require ecs
require app
require game.es.events
require game.utils.hero

[es (tag=gameClient, no_order, REQUIRE=mortar_marker)]
def mortar_kill_marker_cleanup_es(info: UpdateStageInfoAct; eid: EntityId; marker_dot_endTime: float)
  if info.curTime > marker_dot_endTime
    destroyEntity(eid)

def create_minimap_icon(minimap_icon : string; pos:float3; showTime: float)
  createEntity(minimap_icon) <| $(var init: ComponentsInitializer)
    var tm : float3x4
    identity(tm)
    tm[3] = pos
    set(init, "transform", tm)
    set(init, "marker.endTime", get_sync_time() + showTime)

[es (tag=gameClient)]
def mortar_kill_mark_create_es(evt : EventEntityDied; transform:float3x4)
  if evt.offender == INVALID_ENTITY_ID || evt.offender != get_controlled_hero()
    return
  ecs::find_query() <| $ [es (REQUIRE=mortar)] (gun_dot_owner : ecs::EntityId;
                                                gun_dot_propsId : int;
                                                mortar_dot_killIconShowTime : float;
                                                mortar_dot_killIconName : string)
    if gun_dot_owner == evt.offender && int(evt.deathDesc.gunPropsId) == gun_dot_propsId
      create_minimap_icon(mortar_dot_killIconName, transform[3], mortar_dot_killIconShowTime)
      return true
    return false


[es (tag=gameClient, REQUIRE=msg_sink)]
def mortar_shell_explode_mark_create_es(evt: EventOnShellExploded)
  if evt.owner == INVALID_ENTITY_ID || evt.owner != get_controlled_hero()
    return
  ecs::find_query() <| $ [es (REQUIRE=mortar)] (gun_dot_owner : ecs::EntityId;
                                                gun_dot_propsId : int;
                                                mortar_dot_explodeIconShowTime : float;
                                                mortar_dot_explodeIconName : string)
    if gun_dot_owner == evt.owner && evt.gunPropsId == gun_dot_propsId
      create_minimap_icon(mortar_dot_explodeIconName, evt.explPos, mortar_dot_explodeIconShowTime)
      return true
    return false