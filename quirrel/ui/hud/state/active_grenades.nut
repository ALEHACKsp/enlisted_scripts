local { TEAM_UNASSIGNED } = require("team")
local { watchedHeroEid } = require("ui/hud/state/hero_state_es.nut")
local is_teams_friendly = require("globals/is_teams_friendly.nut")

local active_grenades = Watched({})
local function deleteGrenade(eid){
  if (eid in active_grenades.value)
    delete active_grenades.value[eid]
}

local getGrenadeOwnerTeamQuery = ::ecs.SqQuery("getGrenadeOwnerTeamQuery", {comps_ro = [["team", ::ecs.TYPE_INT]]})
local getHeroTeam = @(heroEid) getGrenadeOwnerTeamQuery.perform(heroEid, @(eid, comp) comp["team"]) ?? TEAM_UNASSIGNED
::ecs.register_es(
  "active_grenades_hud_es",
  {
    [["onInit", "onChange"]] = function(evt, eid, comp){
      if (!(comp.active || comp["shell.explTime"] == 0.0))
        deleteGrenade(eid)
      else{
        active_grenades(function(v) {
          local grenadeOwner = comp["shell.owner"]
          local heroEid = watchedHeroEid.value ?? INVALID_ENTITY_ID
          local willDamageHero = (grenadeOwner == heroEid && heroEid != INVALID_ENTITY_ID && grenadeOwner != INVALID_ENTITY_ID)
            ? true
            : !(is_teams_friendly(getHeroTeam(heroEid), getHeroTeam(grenadeOwner)))
          v[eid] <- {
            willDamageHero = willDamageHero
            maxDistance = comp["hud_marker.max_distance"]
          }
        })
      }
    }
    function onDestroy(evt, eid, comp){
      deleteGrenade(eid)
    }
  },
  {
    comps_ro = [
      ["shell.explTime", ::ecs.TYPE_FLOAT, 0.0],
      ["shell.owner", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["hud_marker.max_distance", ::ecs.TYPE_FLOAT, 10.0]
    ]
    comps_track = [["active", ::ecs.TYPE_BOOL]]
    comps_rq = ["hud_grenade_marker"]
  }
)

return {
  active_grenades = active_grenades
} 