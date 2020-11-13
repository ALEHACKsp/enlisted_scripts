require ecs
require math
require DagorMath
require Dacoll
require game.es.events
require game.utils.team
require DagorSystem


def calc_artillery_source_pos(owner : EntityId)
  var count = 0.0
  var pos = float3()
  ecs::query(owner) <| $[es] (team: int)
    let ownerTeam = team
    ecs::query() <| $[es (REQUIRE=respbase)](active: bool; team: int; transform: float3x4)
      if !active || (team != ownerTeam && team != TEAM_UNASSIGNED)
        return
      count += 1.0
      pos += transform[3]

  if count == 0.0
    logerr("no respawn base for calc_artillery_source_pos")
    pos =  float3(0.0, 0.0, 0.0)
    count = 1.0

  pos *= rcp(count)
  return pos + float3(0.0, 70.0, 0.0)


def calc_artillery_target_pos(eid : EntityId; var result: float3): bool
  let aimTm = deref(get_TMatrix(eid, "human.aimTm"))

  var len = 200.0
  var norm : float3
  if traceray_normalized(aimTm[3], aimTm[0], len, norm)
    result = aimTm[3] + aimTm[0] * len
    return true

  return false


def artillery_start(tpl_name : string; offender, owner_player : EntityId; source_pos, target_pos : float3)
  createEntity(tpl_name) <| $(var init: ComponentsInitializer)
    set(init, "artillery.offender", offender)
    set(init, "artillery.callerEid", owner_player)
    set(init, "artillery.sourcePos", source_pos)
    set(init, "artillery.targetPos", target_pos)


[es (tag=server)]
def artillery_strike_start_es(evt: CmdStartArtilleryStrike; eid: EntityId; artilleryTemplate : string)
  var targetPos : float3
  if calc_artillery_target_pos(evt.owner, targetPos)
    artillery_start(artilleryTemplate, evt.owner, eid, calc_artillery_source_pos(evt.owner), targetPos)
  else
    logerr("can't calc artillery source pos for team {get_int(evt.owner, "team") ?? TEAM_UNASSIGNED}")


[es (tag=server)]
def artillery_strike_start_at_pos_es(evt: CmdStartArtilleryStrikeAtPos; eid: EntityId; artilleryTemplate : string)
  artillery_start(artilleryTemplate, evt.owner, eid, calc_artillery_source_pos(evt.owner), evt.pos)
