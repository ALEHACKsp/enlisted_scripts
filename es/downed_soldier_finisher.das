require ecs
require game.es.events
require game.utils.team
require DagorRandom
require game.es.vehicle.vehicle_events

def have_active_teammates(owner_eid : EntityId; our_team : int)
  return ecs::find_query() <| $[es(REQUIRE=human)](eid : EntityId; team : int; isAlive, isDowned : bool; beh_tree_dot_enabled = false)
    return eid != owner_eid && isAlive && !isDowned && is_teams_friendly(team, our_team) && !beh_tree_dot_enabled

[es (REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def downed_soldier_finisher_es(evt:Event;
                               eid : EntityId;
                               var hitpoints_dot_hp: float&;
                               hitpoints_dot_deathHpThreshold: float;
                               team, total_kits_dot_selfRevive : int;
                               human_anim_dot_vehicleSelected : EntityId;
                               hitpoints_dot_canBeDownedInVehicle : bool = false;
                               hitpoints_dot_canSelfReviveByHealing : bool = false;
                               hitpoints_dot_canBeRevivedByTeammates : bool = false;
                               hitpoints_dot_alwaysAllowRevive : bool = false)
  if human_anim_dot_vehicleSelected != INVALID_ENTITY_ID
    if hitpoints_dot_canBeDownedInVehicle
      sendEvent(human_anim_dot_vehicleSelected, [[CmdKickFromVehicle eid=eid]])
    else
      hitpoints_dot_hp = hitpoints_dot_deathHpThreshold
  if hitpoints_dot_alwaysAllowRevive || (hitpoints_dot_canSelfReviveByHealing && total_kits_dot_selfRevive > 0) || (hitpoints_dot_canBeRevivedByTeammates && have_active_teammates(eid, team))
    return
  hitpoints_dot_hp = hitpoints_dot_deathHpThreshold

[es (REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def downed_chance_soldier_finisher_es(evt:Event;
                                      var hitpoints_dot_hp: float&;
                                      hitpoints_dot_deathHpThreshold: float;
                                      hitpoints_dot_downedKillChanceMult: float;
                                      hitpoints_dot_downedKillChanceBase: float)
  let hpProportion = hitpoints_dot_hp / hitpoints_dot_deathHpThreshold
  let dice = gfrnd()
  let chance = hitpoints_dot_downedKillChanceBase + hpProportion * hitpoints_dot_downedKillChanceMult
  if dice < chance
    hitpoints_dot_hp = hitpoints_dot_deathHpThreshold


def lose_team_finisher(eid, victim : EntityId; team : int;
                       isAlive, isDowned : bool;
                       hitpoints_dot_canBeRevivedByTeammates : bool;
                   var hitpoints_dot_hp : float&;
                       hitpoints_dot_canSelfReviveByHealing : bool = false;
                       total_kits_dot_selfRevive : int = 0;
                       hitpoints_dot_deathHpThreshold : float = 0.0)
  if eid == victim || victim == INVALID_ENTITY_ID || (hitpoints_dot_canSelfReviveByHealing && total_kits_dot_selfRevive > 0)
    return
  if isAlive && isDowned && is_teams_friendly(get_int(victim, "team") ?? TEAM_UNASSIGNED, team) && hitpoints_dot_canBeRevivedByTeammates
    if !have_active_teammates(eid, team)
      hitpoints_dot_hp = hitpoints_dot_deathHpThreshold


[es (REQUIRE=human, tag=server)]
def lose_team_finisher_downed_es(evt : EventAnyEntityDowned;
                                eid : EntityId; team : int;
                                isAlive, isDowned : bool;
                                hitpoints_dot_canBeRevivedByTeammates : bool;
                            var hitpoints_dot_hp : float&;
                                hitpoints_dot_canSelfReviveByHealing : bool = false;
                                total_kits_dot_selfRevive : int = 0;
                                hitpoints_dot_deathHpThreshold : float = 0.0)
  lose_team_finisher(eid, evt.victim, team, isAlive, isDowned, hitpoints_dot_canBeRevivedByTeammates, hitpoints_dot_hp,
                     hitpoints_dot_canSelfReviveByHealing, total_kits_dot_selfRevive, hitpoints_dot_deathHpThreshold)


[es (REQUIRE=human, tag=server)]
def lose_team_finisher_died_es(evt : EventAnyEntityDied;
                               eid : EntityId; team : int;
                               isAlive, isDowned : bool;
                               hitpoints_dot_canBeRevivedByTeammates : bool;
                           var hitpoints_dot_hp : float&;
                               hitpoints_dot_canSelfReviveByHealing : bool = false;
                               total_kits_dot_selfRevive : int = 0;
                               hitpoints_dot_deathHpThreshold : float = 0.0)
  lose_team_finisher(eid, evt.victim, team, isAlive, isDowned, hitpoints_dot_canBeRevivedByTeammates, hitpoints_dot_hp,
                     hitpoints_dot_canSelfReviveByHealing, total_kits_dot_selfRevive, hitpoints_dot_deathHpThreshold)


[es (REQUIRE=human, tag=server, track=burning_dot_isBurning)]
def burning_finisher_es(evt: Event;
                        isAlive, isDowned, burning_dot_isBurning : bool;
                        var hitpoints_dot_hp : float&;
                        hitpoints_dot_deathHpThreshold : float = 0.0;
                        hitpoints_dot_downedKillWhenBurning = false)
  if isAlive && isDowned && burning_dot_isBurning && hitpoints_dot_downedKillWhenBurning
    hitpoints_dot_hp = hitpoints_dot_deathHpThreshold

[es (REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def burning_finisher_before_downed(evt: Event;
                                   isAlive, burning_dot_isBurning : bool;
                                   var hitpoints_dot_hp : float&;
                                   hitpoints_dot_deathHpThreshold : float = 0.0;
                                   hitpoints_dot_downedKillWhenBurning = false)
  if isAlive && burning_dot_isBurning && hitpoints_dot_downedKillWhenBurning
    hitpoints_dot_hp = hitpoints_dot_deathHpThreshold


[es (REQUIRE=human, tag=server, on_event=EventEntityDowned)]
def set_downed_minDmgSpd_es(evt:Event; var human_coll_damage_dot_minDmgSpd: float&;
                                       var human_coll_damage_dot_lastMinDmgSpd : float&;
                                           human_coll_damage_dot_downedMinDmgSpd: float)
  human_coll_damage_dot_lastMinDmgSpd = human_coll_damage_dot_minDmgSpd
  human_coll_damage_dot_minDmgSpd = human_coll_damage_dot_downedMinDmgSpd

[es (REQUIRE=human, tag=server, on_event=EventEntityRevived)]
def unset_downed_minDmgSpd_es(evt:Event; var human_coll_damage_dot_minDmgSpd: float&;
                                             human_coll_damage_dot_lastMinDmgSpd : float;
                                             human_coll_damage_dot_downedMinDmgSpd: float)
  if human_coll_damage_dot_minDmgSpd == human_coll_damage_dot_downedMinDmgSpd
    human_coll_damage_dot_minDmgSpd = human_coll_damage_dot_lastMinDmgSpd

[es (REQUIRE=human, tag=server, track=isOutsideBattleArea)]
def outside_battle_area_finisher_es(evt: Event;
                                    isAlive, isDowned, isOutsideBattleArea : bool;
                                    var hitpoints_dot_hp : float&;
                                    hitpoints_dot_deathHpThreshold : float = 0.0)
  if isAlive && isDowned && isOutsideBattleArea
    hitpoints_dot_hp = hitpoints_dot_deathHpThreshold

[es (REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def outside_battle_area_finisher_before_downed(evt: Event;
                                               isAlive, isOutsideBattleArea : bool;
                                               var hitpoints_dot_hp : float&;
                                               hitpoints_dot_deathHpThreshold : float = 0.0)
  if isAlive && isOutsideBattleArea
    hitpoints_dot_hp = hitpoints_dot_deathHpThreshold