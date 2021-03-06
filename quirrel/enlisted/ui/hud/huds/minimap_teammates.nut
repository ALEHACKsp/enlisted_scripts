local {ceil} = require("math")
local {TEAM0_COLOR_FG} = require("ui/hud/style.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {controlledHeroEid, watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {teammatesAvatars} = require("ui/hud/state/human_teammates.nut")

local unitArrowSz = [sh(0.7), sh(1.4)]

local unit_arrow = ::Picture("!ui/skin#unit_arrow.svg:{0}:{1}:K".subst(
    ceil(unitArrowSz[0]*1.3).tointeger(), ceil(unitArrowSz[1]*1.3).tointeger()))

local mkIcon = ::memoize(@(fillColor){
    rendObj = ROBJ_IMAGE
    color = fillColor
    image = unit_arrow
    pos = [0, -unitArrowSz[1] * 0.25]
    size = unitArrowSz
  }
)

local function map_unit_ctor(eid, marker, options={}) {
  if (!marker.isAlive || (!options?.showHero && watchedHeroEid.value==eid))
    return @(){watch = watchedHeroEid}

  local squadEid = ::ecs.get_comp_val(eid, "squad_member.squad") ?? INVALID_ENTITY_ID

  local vehicle = marker["human_anim.vehicleSelected"]
  if (vehicle != INVALID_ENTITY_ID)
    return @(){watch = [watchedHeroEid]}

  return function(){
    local heroEid = watchedHeroEid.value
    local isSquadmate = (squadEid!=INVALID_ENTITY_ID && squadEid >= 0 && squadEid == ::ecs.get_comp_val(heroEid, "squad_member.squad"))
    local fillColor = Color(200, 0, 0)
    local isTeammate = marker?.team == localPlayerTeam.value
    if (eid == controlledHeroEid.value) {
      fillColor = Color(200, 200, 0)
    } else if (isSquadmate) {
      fillColor = Color(0, 200, 0)
    } else if (isTeammate) {
      fillColor = TEAM0_COLOR_FG
    }

    return {
      key = eid
      data = {
        eid = eid
  //      hideOutside = true
        dirRotate = true
      }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}
      watch = [watchedHeroEid, controlledHeroEid, localPlayerTeam]
      children = mkIcon(fillColor)
    }
  }
}
return{
  map_unit_ctor = map_unit_ctor
  teammatesMarkers = Computed(@() { ctor = @(p) teammatesAvatars.value.reduce(@(res, info, eid) res.append(map_unit_ctor(eid, info, p)), [])})
} 