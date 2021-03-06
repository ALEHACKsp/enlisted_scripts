local { capZones, activeCapZonesEids } = require("enlisted/ui/hud/state/capZones.nut")
local { localPlayerTeam } = require("ui/hud/state/local_player.nut")
local { watchedHeroEid } = require("ui/hud/state/hero_state_es.nut")
local { capzoneCtor } = require("enlisted/ui/hud/components/capzone.nut")

local iconSz= [hdpx(18).tointeger(), hdpx(16).tointeger()]

local defIcon = {rendObj = ROBJ_IMAGE image=Picture("!ui/skin#waypoint.svg:{0}:{1}:K".subst(iconSz[0],iconSz[1])) size = iconSz transform={}}
local capzoneSettings = {canHighlight=false, size=[sh(2),sh(2)], useBlurBack=false}


local minimapCapZone = @(zoneWatch, settings, transform) function() {
  local res = { watch = zoneWatch }
  local zone = zoneWatch.value
  if (zone == null)
    return res

  local heroTeam = settings.heroTeam
  local isDefendZone = (zone.only_team_cap >= 0 && zone.only_team_cap != heroTeam)
  local zoneIcon = (!isDefendZone && (zone?.title ?? "") == "" && (zone?.icon ?? "") == "")
    ? defIcon.__merge({key=zone.eid}) : null

  return res.__update({
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    key = zone.eid
    data = {
      zoneEid = zone.eid
      clampToBorder = true
    }
    transform = transform

    children = [
      capzoneCtor(zone, settings)
      zoneIcon
    ]
  })
}

local function minimapCaptureZones(eids, heroTeam, watchedHeroEidV, transform = {}) {
  local settings = capzoneSettings.__merge({ watchedHeroEidV = watchedHeroEidV, heroTeam = heroTeam })
  return eids.map(@(_, eid) minimapCapZone(::Computed(@() capZones.value?[eid]), settings, transform))
    .values()
}


return ::Computed(function() {
  local heroTeam = localPlayerTeam.value ?? -1
  local watchedHeroEidV = watchedHeroEid.value
  local eids = activeCapZonesEids.value
  return { ctor = @(o) minimapCaptureZones(eids, heroTeam, watchedHeroEidV, o?.transform ?? {}) }
}) 