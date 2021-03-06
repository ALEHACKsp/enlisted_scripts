local {weaponsList} = require("ui/hud/state/hero_state.nut")
local { mkCountdownTimerPerSec } = require("ui/helpers/timers.nut")

local artilleryIsAvailable = ::Watched(false)
local artilleryAvailableAtTime = ::Watched(-1.0)
local wasArtilleryAvailableForSquad = ::Watched(false)

local function track(evt, eid, comp) {
  if (!comp.is_local)
    return
  artilleryIsAvailable(comp["artillery.available"])
  artilleryAvailableAtTime(comp["artillery.availableAtTime"])
  wasArtilleryAvailableForSquad(comp["artillery.wasAvailableForSquad"] != INVALID_ENTITY_ID)
}

::ecs.register_es("artillery_ui", {
  onInit = track,
  onChange = track,
  onDestroy = function(evt, eid, comp) {
    if (!comp.is_local)
      return
    artilleryIsAvailable(false)
    artilleryAvailableAtTime(-1.0)
    wasArtilleryAvailableForSquad(false)
  }
},
{
  comps_track=[
    ["artillery.available", ::ecs.TYPE_BOOL],
    ["artillery.availableAtTime", ::ecs.TYPE_FLOAT],
    ["artillery.wasAvailableForSquad", ::ecs.TYPE_EID],
    ["is_local", ::ecs.TYPE_BOOL]
  ],
  comps_rq=["player"]
})

local artilleryAvailableTimeLeft = mkCountdownTimerPerSec(artilleryAvailableAtTime)
local artilleryIsReady = ::Computed(@() artilleryIsAvailable.value && artilleryAvailableTimeLeft.value <= 0)

local isHeroRadioman = ::Computed(@()
  weaponsList.value.filter(@(weapon) weapon?.weapType == "radio")?[0] != null)

return {
  artilleryAvailableTimeLeft = artilleryAvailableTimeLeft
  artilleryIsReady = artilleryIsReady
  artilleryIsAvailable = artilleryIsAvailable
  wasArtilleryAvailableForSquad = wasArtilleryAvailableForSquad
  isHeroRadioman = isHeroRadioman
} 