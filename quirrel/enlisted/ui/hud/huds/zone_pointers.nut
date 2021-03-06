local { isEqual } = require("std/underscore.nut")
local { capZones } = require("enlisted/ui/hud/state/capZones.nut")
local style = require("ui/hud/style.nut")
local {safeAreaHorPadding, safeAreaVerPadding} = require("globals/safeArea.nut")


local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")

local { capzoneCtor } = require("enlisted/ui/hud/components/capzone.nut")
local capzoneSettings = {canHighlight=false}

local visibleZoneEids = ::Watched({})
local visibleZoneEidsRecalc = keepref(::Computed(@()
  capZones.value.filter(@(z) z.active && z?.heroInsideEid != watchedHeroEid.value)
    .map(@(_) true)))
visibleZoneEidsRecalc.subscribe(function(v) {
  if (!isEqual(v, visibleZoneEids.value))
    visibleZoneEids(v)
})

local function distanceText(eid) {
  return {
    rendObj = ROBJ_DTEXT
    color = style.DEFAULT_TEXT_COLOR
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = [0, sh(3.5)]
    size = [sh(5), fontH(100)]

    behavior = Behaviors.DistToEntity
    targetEid = eid
    minDistance = 3.0
  }
}

local pointerColor = Color(200,200,200)
local iconSz =[hdpx(32), hdpx(24)]

local defIcon = {
  rendObj = ROBJ_IMAGE
  size = iconSz
  image = Picture(":".concat("!ui/skin#waypoint.svg", iconSz[0].tointeger(), iconSz[1].tointeger()))
}

local mkZonePointer = @(zoneWatch, settings) function() {
  local res = { watch = zoneWatch }
  local zone = zoneWatch.value
  if (zone == null)
    return res

  local heroTeam = settings.heroTeam
  local isDefendZone = (zone.only_team_cap >= 0 && zone.only_team_cap != heroTeam)
  local showCapturing = zone.isCapturing
    && (zone.only_team_cap == heroTeam || (zone.curTeamCapturingZone != heroTeam && zone.only_team_cap!=heroTeam))
  local zoneIcon = (!isDefendZone && (zone?.title ?? "") == "" && (zone?.icon ?? "") == "")
    ? defIcon.__merge({ key = zone.eid })
    : null

  return res.__update({
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [0,0]

    key = showCapturing ? $"i{zone.eid}" : zone.eid
    data = {
      zoneEid = zone.eid
    }
    transform = {}
    children = {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      data = {
        eid = zone.eid
        priorityOffset = 10000
      }
      size = [sh(4.8), sh(4.8 + 2.0)]
      pos = [0, -sh(1)]
      behavior = [Behaviors.DistToPriority, Behaviors.OverlayTransparency]
      children = [
        {
          size = [sh(4.8), sh(4.8)]
          halign = ALIGN_CENTER
          transform = {}

          children = {
            rendObj = ROBJ_IMAGE
            image = Picture("!ui/skin#target_pointer")
            size = [sh(4), sh(4.8)]
            pos = [sh(0.05), -sh(0.34)]
            color = pointerColor
            key = (showCapturing && isDefendZone) ? zone.eid : $"s{zone.eid}"
            animations = (showCapturing && isDefendZone) ? [
                { prop=AnimProp.color, from=pointerColor, to=style.TEAM1_COLOR_FG, duration=0.6, play=true, loop=true, easing=CosineFull}
              ] :
              []
          }
        }
        capzoneCtor(zone, settings)
        zoneIcon
        distanceText(zone.eid)
      ]
    }

    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InOutCubic}
    ]
  })
}

local function zonePointers() {
  local settings = capzoneSettings.__merge({
    heroTeam = localPlayerTeam.value ?? -1
    watchedHeroEidV = watchedHeroEid.value
  })
  local children = visibleZoneEids.value.keys()
    .map(@(eid) mkZonePointer(::Computed(@() capZones.value?[eid]), settings))

  return {
    watch = [visibleZoneEids, localPlayerTeam, watchedHeroEid, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.value*2 - sh(6), sh(100) - safeAreaVerPadding.value*2-sh(8)]
    behavior = Behaviors.ZonePointers
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }
}

return zonePointers
 