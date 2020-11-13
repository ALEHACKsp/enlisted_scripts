require enlisted.game.es.enlisted_events
require game.utils.team
require game.utils.hero
require player
require ecs

[es (tag=gameClient, track=human_weap_dot_currentGunEid, REQUIRE=(hero, human_weap_dot_currentGunEid))]
def hero_weapon_changed_recreate_icons_es(evt: Event; eid : ecs::EntityId)
  sendEvent(eid, [[EventRecreateBuildIcons]])

[es (tag=gameClient, track=minimap_dot_visibleForAll, on_event=(EventEntityCreated, EventComponentsAppear, EventEntityDestroyed), REQUIRE=minimap_dot_visibleForAll)]
def visible_for_all_building_changed_es(evt: Event)
  let hero = get_controlled_hero()
  sendEvent(hero, [[EventRecreateBuildIcons]])

[es (tag=gameClient, on_event=(EventEntityCreated, EventComponentsAppear))]
def building_create_by_hero_update_icons_es(evt: Event; buildByPlayer: ecs::EntityId)
  let engineer = get_Eid(buildByPlayer, "possessed") ?? INVALID_ENTITY_ID
  let hero = get_controlled_hero()
  if engineer != hero
    return
  sendEvent(hero, [[EventRecreateBuildIcons]])

[es (on_event=(EventEntityDestroyed, EventEntityDied), tag=gameClient, REQUIRE=buildByPlayer)]
def building_destroyed_icons_es(evt: Event; eid: EntityId)
  let buildingEid = eid
  ecs::query() <| $[es(REQUIRE=building_user_point)](eid : ecs::EntityId; target: EntityId)
    if target == buildingEid
      destroyEntity(eid)

[es (tag=gameClient)]
def building_icons_creator_es(evt: EventRecreateBuildIcons; human_weap_dot_currentGunEid: ecs::EntityId)
  ecs::query() <| $[es(REQUIRE=building_user_point)](eid : ecs::EntityId)
    destroyEntity(eid)
  let localPlayerEid = get_local_player_eid()
  ecs::query() <| $ [es] (eid: EntityId&;
                          transform: float3x4;
                          buildByPlayer: ecs::EntityId;
                          team: int = -1;
                          minimap_dot_visibleForAll: bool = false;
                          minimap_dot_visibleRadius: float = -1.0)
    if minimap_dot_visibleForAll
      let localPlayerTeam = get_int(localPlayerEid, "team") ?? TEAM_UNASSIGNED
      if !is_teams_friendly(team, localPlayerTeam)
        return
    else
      if buildByPlayer != localPlayerEid || !has(human_weap_dot_currentGunEid, "previewEid")
        return
    createEntitySync("user_building_point") <| $ (var init:ComponentsInitializer)
      set(init, "transform", transform)
      set(init, "target", eid)
      set(init, "hud_marker.visible_distance", minimap_dot_visibleRadius)