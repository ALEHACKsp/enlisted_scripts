options remove_unused_symbols = false
module battle_area_common
require ecs
require ecs.common
require DagorMath
require zones
require game.utils.team

let
  identityBox = BBox3(float3(-0.5,-0.5,-0.5), float3(0.5,0.5,0.5))

[private, generic, unused_argument(trigger_tag, eid)]
def check_active_poly_battle_area(pos2 : float2; team : int; trigger_tag : auto(TT); eid : EntityId;
                                  battleAreaPoints : Point2List; battle_area_dot_team : int; active : bool)
  if active && (battle_area_dot_team == TEAM_UNASSIGNED || battle_area_dot_team == team)
    static_if typeinfo(is_string type<TT>)
      if !has(eid, trigger_tag)
        return false
    if is_point_in_poly(pos2, battleAreaPoints)
      return true
  return false

[private, generic, unused_argument(trigger_tag, eid)]
def check_active_box_battle_area(pos : float3; team : int; trigger_tag : auto(TT); eid : EntityId; transform : float3x4;
                                 battle_area_dot_team : int; active : bool)
  if active && (battle_area_dot_team == TEAM_UNASSIGNED || battle_area_dot_team == team)
    static_if typeinfo(is_string type<TT>)
      if !has(eid, trigger_tag)
        return false
    let zonePos = inverse(transform) * pos
    if identityBox & zonePos
      return true
  return false

def query_active_battle_areas(pos : float3; team : int; trigger_tag : string; cb : block<(eid:EntityId):void>)
  let pos2 = pos.xz
  if trigger_tag == "humanTriggerable" // fast path (without trigger_tag checks)
    ecs::query() <| $ [es (REQUIRE=battle_area, REQUIRE=humanTriggerable)] (eid : EntityId; battleAreaPoints : Point2List;
                                                                            battle_area_dot_team : int; active : bool)
      if check_active_poly_battle_area(pos2, team, true, eid, battleAreaPoints, battle_area_dot_team, active)
        invoke(cb, eid)
    ecs::query() <| $ [es (REQUIRE=battle_area, REQUIRE=box_zone, REQUIRE=humanTriggerable)] (eid : EntityId; transform : float3x4;
                                                                                              battle_area_dot_team : int; active : bool)
      if check_active_box_battle_area(pos, team, true, eid, transform, battle_area_dot_team, active)
        invoke(cb, eid)
  else // generic triggerable tag path
    ecs::query() <| $ [es (REQUIRE=battle_area)] (eid : EntityId; battleAreaPoints : Point2List;
                                                 battle_area_dot_team : int; active : bool)
      if check_active_poly_battle_area(pos2, team, trigger_tag, eid, battleAreaPoints, battle_area_dot_team, active)
        invoke(cb, eid)
    ecs::query() <| $ [es (REQUIRE=battle_area, REQUIRE=box_zone)] (eid : EntityId; transform : float3x4;
                                                                    battle_area_dot_team : int; active : bool)
      if check_active_box_battle_area(pos, team, trigger_tag, eid, transform, battle_area_dot_team, active)
        invoke(cb, eid)

enum FindActiveBattleAreasRes
  not_found
  found
  no_any

def find_active_battle_areas(pos : float3; team : int; trigger_tag : string; cb : block<(eid:EntityId):bool>)
  let pos2 = pos.xz
  var hasAnyBattleAreas = false
  let polyRes = ecs::find_query() <| $ [es (REQUIRE=battle_area)] (eid : EntityId; battleAreaPoints : Point2List;
                                                                   battle_area_dot_team : int; active : bool)
    hasAnyBattleAreas = true
    if check_active_poly_battle_area(pos2, team, trigger_tag, eid, battleAreaPoints, battle_area_dot_team, active)
      if invoke(cb, eid)
        return true
    return false
  if polyRes
    return FindActiveBattleAreasRes found
  let boxRes = ecs::find_query() <| $ [es (REQUIRE=battle_area, REQUIRE=box_zone)] (eid : EntityId; transform : float3x4;
                                                                                    battle_area_dot_team : int; active : bool)
    hasAnyBattleAreas = true
    if check_active_box_battle_area(pos, team, trigger_tag, eid, transform, battle_area_dot_team, active)
      if invoke(cb, eid)
        return true
    return false
  if boxRes
    return FindActiveBattleAreasRes found
  return hasAnyBattleAreas ? FindActiveBattleAreasRes not_found : FindActiveBattleAreasRes no_any

def has_active_human_battle_area_at(pos : float3; team : int = int(TEAM_UNASSIGNED))
  let result = find_active_battle_areas(pos, team, "humanTriggerable") <| $[unused_argument(area_eid)](area_eid) => true
  return result != FindActiveBattleAreasRes not_found

def has_active_human_battle_area_at(pos : float3; team : int; exlude_eid : ecs::EntityId)
  let result = find_active_battle_areas(pos, team, "humanTriggerable") <| $(area_eid)
    return area_eid != exlude_eid
  return result != FindActiveBattleAreasRes not_found
