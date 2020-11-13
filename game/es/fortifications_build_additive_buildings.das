require DagorSystem
require game.utils.team
require ecs.common
require ecs

[private]
def align_tm_by_up_vector(var tm; up)
  if up == null
    return tm
  tm[0] =  normalize(cross(*up, tm[2]))
  tm[1] = -normalize(cross(tm[0], tm[2]))
  tm[2] =  normalize(cross(tm[0], tm[1]))
  return tm

[es ( tag=gameClient, after=build_ability_update_transform_es)]
def building_additive_preview_depends_es(info: UpdateStageInfoAct;
                                         dependsOnPreviewEid : EntityId;
                                         additiveTm: float3x4&;
                                         additiveUp: float3?;
                                         var transform: float3x4&;
                                         var semi_transparent_dot_placingColor: float3&;
                                         var semi_transparent_dot_visible: bool&)
  var tm & = transform
  var color & = semi_transparent_dot_placingColor
  var isVisivle & = semi_transparent_dot_visible
  ecs::query(dependsOnPreviewEid) <| $ [es]  (transform: float3x4; semi_transparent_dot_placingColor: float3; semi_transparent_dot_visible: bool)
    tm = align_tm_by_up_vector(transform * additiveTm, additiveUp)
    color = semi_transparent_dot_placingColor
    isVisivle = semi_transparent_dot_visible

def create_additive_buildings(eid, transform, additiveBuildings, team)
  for i in iter_range(additiveBuildings)
    let obj = get_ecs_object(additiveBuildings[i])
    if obj == null
      continue
    let buildingTemplate = get_string(obj, "template", "")
    let targetTM = get_TMatrix(obj, "tm")
    if buildingTemplate == "" || targetTM == null
      logerr("can't create all additive buildings for {eid} и {getEntityTemplateName(eid)}, some of them hasn't template or tm")
      continue
    let additiveUp = get_Point3(obj, "additiveUp")
    let additiveBuildingTm = align_tm_by_up_vector(transform * (*targetTM), additiveUp)
    createEntity(buildingTemplate) <| $ (var init: ComponentsInitializer)
      set(init, "transform", additiveBuildingTm)
      set(init, "dependsOnPreviewEid", eid)
      set(init, "additiveTm", (*targetTM))
      set(init, "team", team)
      if additiveUp != null
        set(init, "additiveUp", *additiveUp)

[es (tag=server, on_event=EventEntityCreated, REQUIRE_NOT=builder_preview)]
def init_additive_buildings_es(evt : Event;
                               eid: EntityId;
                               transform: float3x4;
                               additiveBuildings: Array;
                               team = TEAM_UNASSIGNED)
  create_additive_buildings(eid, transform, additiveBuildings, team)

[es (tag=gameClient, on_event=EventEntityCreated, REQUIRE=builder_preview)]
def init_additive_local_previews_es(evt : Event;
                                    eid: EntityId;
                                    transform: float3x4;
                                    additiveBuildings: Array;
                                    team = TEAM_UNASSIGNED)
  create_additive_buildings(eid, transform, additiveBuildings, team)

def destroy_additive_buildings(base_eid)
  ecs::query() <| $ [es]  (eid: EntityId; dependsOnPreviewEid: EntityId)
    if base_eid == dependsOnPreviewEid
      destroyEntity(eid)

[es (tag=server, on_event=(EventEntityDestroyed, EventEntityDied), REQUIRE=additiveBuildings, REQUIRE_NOT=builder_preview)]
def destroy_additive_buildings_es(evt : Event;
                                  eid: EntityId)
  destroy_additive_buildings(eid)

[es (tag=gameClient, on_event=EventEntityDestroyed, REQUIRE=(additiveBuildings, builder_preview))]
def destroy_additive_previews_es(evt : Event;
                                 eid: EntityId)
  destroy_additive_buildings(eid)