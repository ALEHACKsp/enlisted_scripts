local { resupplyZones, heroActiveResupplyZonesEids } = require("enlisted/ui/hud/state/resupplyZones.nut")
local style = require("ui/hud/style.nut")
local {safeAreaVerPadding, safeAreaHorPadding} = require("globals/safeArea.nut")


local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")

local { resupplyZoneCtor } = require("enlisted/ui/hud/components/resupplyZone.nut")

local function distanceText(eid, radius) {
  return {
    rendObj = ROBJ_DTEXT
    color = style.DEFAULT_TEXT_COLOR
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = [0, sh(3.5)]
    size = [sh(5), fontH(100)]

    behavior = Behaviors.DistToSphere
    targetEid = eid
    radius = radius
    minDistance = 0
  }
}

local pointerColor = Color(200,200,200)

local mkZonePointer = @(zoneWatch) function() {
  local res = { watch = zoneWatch }
  local zone = zoneWatch.value
  if (zone == null)
    return res

  return res.__update({
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [0,0]

    key = zone.eid
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
      size = flex()
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
            pos = [sh(0.0), -sh(0.35)]
            color = pointerColor
            key = zone.eid
            animations = []
          }
        }
        resupplyZoneCtor(zone)
        distanceText(zone.eid, zone.radius)
      ]
    }

    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InOutCubic}
    ]
  })
}

local function resupplyPointers() {
  local children = heroActiveResupplyZonesEids.value
    .map(@(eid) mkZonePointer(::Computed(@() resupplyZones.value?[eid])))

  return {
    watch = [heroActiveResupplyZonesEids, localPlayerTeam, watchedHeroEid, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.value*2 - sh(6), sh(100) - safeAreaVerPadding.value*2-sh(8)]
    behavior = Behaviors.ZonePointers
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }
}

return resupplyPointers
 