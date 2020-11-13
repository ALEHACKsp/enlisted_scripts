require ecs
require app
require math
require game.es.events

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def reset_squad_suicide_rate_on_squad_spawn(evt: Event; squad_dot_ownerPlayer: ecs::EntityId)
  ecs::query(squad_dot_ownerPlayer) <| $[es](var squads_dot_suicideRate: float&;
                                             var squads_dot_respawnPenaltyTime: float&;
                                             var squads_dot_lastRespawnAtTime: float&)
    squads_dot_lastRespawnAtTime = get_sync_time()
    squads_dot_suicideRate = 0.f
    squads_dot_respawnPenaltyTime = 0.f

def is_suicide(playerEid; evt: EventAnyEntityDied)
  return evt.offender == evt.victim || evt.offenderPlayer == playerEid

[es (tag=server, REQUIRE=player)]
def calc_squad_suicide_rate(evt: EventAnyEntityDied;
                            eid: EntityId;
                            var squads_dot_suicideRate: float&;
                            var squads_dot_respawnPenaltyTime: float&;
                            squads_dot_lastRespawnAtTime: float;
                            squads_dot_respawnPenaltyTimeThreshold: float;
                            squads_dot_suicideRateThresholdForPenalty: float;
                            squads_dot_botCount: int)
  var isMySquad = false
  ecs::query(evt.victimSquad) <| $[es](squad_dot_ownerPlayer: ecs::EntityId)
    isMySquad = squad_dot_ownerPlayer == eid
  if !isMySquad
    return

  let squadSize = float(squads_dot_botCount + 1 /* leader */)
  let squadLifeTime = get_sync_time() - squads_dot_lastRespawnAtTime
  if is_suicide(eid, evt)
    squads_dot_suicideRate += 1.f / squadSize
  if squads_dot_suicideRate >= squads_dot_suicideRateThresholdForPenalty
    squads_dot_respawnPenaltyTime = max(squads_dot_respawnPenaltyTimeThreshold - squadLifeTime, 0.f)
