local { TEAM_UNASSIGNED } = require("team")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {controlledHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {killLogState} = require("ui/hud/state/eventlog.nut")
local remap_nick = require("globals/remap_nick.nut")
local is_teams_friendly = require("globals/is_teams_friendly.nut")
local awardsLog = require("ui/hud/state/eventlog.nut").awards

local function killEventText(victim, killer) {
  if (victim.isHero) {
    if (killer.vehicle) {
      local killerName = ::ecs.get_comp_val(killer.eid, "item.name", "")
      return ::loc(killerName)
    }
    return (killer.isHero) ? ::loc("log/local_player_suicide") : killer.name
  }

  local victimName = victim.name ?? (
    victim?.inMyTeam
      ? victim.inMySquad ? ::loc("log/squadmate") : ::loc("log/teammate")
      : null
  )

  return (victimName != null)
    ? ::loc("log/eliminated", {user = victimName})
    : victim.inMyTeam
      ? ::loc("log/eliminated_teammate")
      : ::loc("log/eliminated_enemy")
}


local function onReportKill(evt, eid, comp) {
  local data = evt.data
  local victim = data.victim
  local killer = data.killer

  local heroEid     = controlledHeroEid.value
  local myTeam      = localPlayerTeam.value
  local mySquad     = ::ecs.get_comp_val(heroEid, "squad_member.squad")

  local victimPlayer = victim.squad==mySquad ? INVALID_ENTITY_ID : victim.player_eid
  local victimInMyTeam = is_teams_friendly(myTeam, victim.team)
  victim = victim.__merge({
    inMyTeam = victimInMyTeam
    inMySquad = victim.squad==mySquad
    isHero = victim.eid==heroEid
    player_eid = victimPlayer
    isDowned = false // TODO: pass it in msg itself
    isAlive = false
    name = victim?.vehicle ? ::loc($"{victim?.name}_shop") : remap_nick(victim?.name)
  })
  killer = killer.__merge({
    inMyTeam = is_teams_friendly(myTeam, killer.team ?? TEAM_UNASSIGNED)
    inMySquad = killer.squad==mySquad
    isHero = killer.eid==heroEid
    name = remap_nick(killer?.name)
  })
  local event = data.__merge({
    event = "kill"
    text = null
    myTeamScores = !victimInMyTeam
    victim = victim
    killer = killer
    ttl = [victim.eid, killer.eid].indexof(heroEid)!=null ? 8 : 5
  })
  killLogState.pushEvent(event)


  if (killer.eid == heroEid || victim.eid == heroEid) {
    //local snd = (victim.eid == heroEid) ? "" : event.victim.inMyTeam ? "ui/kill_assist" : "ui/enemy_killed"
    local award = {awardData = {text = killEventText(victim, killer), type="kill"}}
    awardsLog.pushEvent(award)
  }
}

::ecs.register_es("ui_kill_report_es", {
    [::ecs.sqEvents.EventKillReport] = onReportKill
  },
  {comps_rq=["msg_sink"]}
)
 