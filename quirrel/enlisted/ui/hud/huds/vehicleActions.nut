local { canChangeCockpitView } = require("enlisted/ui/hud/state/cockpit.nut")
local vehicleSeats = require("ui/hud/state/vehicle_seats.nut")
local { controlledHeroEid, watchedHeroEid } = require("ui/hud/state/hero_state_es.nut")
local { DEFAULT_TEXT_COLOR } = require("ui/hud/style.nut")
local { tipCmp, mkInputHintBlock, defTipAnimations } = require("ui/hud/huds/tips/tipComponent.nut")

local allowHints = ::Computed(@() controlledHeroEid.value == watchedHeroEid.value
  && controlledHeroEid.value != INVALID_ENTITY_ID)

local canHatch = ::Computed(function() {
  if (!allowHints.value)
    return false
  local ownerEid = controlledHeroEid.value
  local seat = vehicleSeats.value.data.findvalue(@(s) s?.owner.eid == ownerEid)
  return (seat?.seat.hatchNodes.len() ?? 0) > 0
})

local function getOutOfTheTankHatch() {
  local res = { watch = canHatch }
  if (!canHatch.value)
    return res
  return res.__update({
    children = tipCmp({
      text = ::loc("watchFromTheTankHatch")
      inputId = "Human.ToggleHatch"
      textColor = DEFAULT_TEXT_COLOR
    })
  })
}

local nextViewTip = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  transform = { pivot = [0.5,0.5] }
  animations = defTipAnimations

  children = [
    mkInputHintBlock("Vehicle.PrevCockpitView")
    tipCmp({
      inputId = "Vehicle.NextCockpitView"
      text = ::loc("lookTheOtherWay")
      textColor = DEFAULT_TEXT_COLOR
      animations = []
    })
  ]
}

local function nextView() {
  local res = { watch = [canChangeCockpitView, allowHints] }
  if (!canChangeCockpitView.value || !allowHints.value)
    return res
  return res.__update({ children = nextViewTip })
}

return [
  getOutOfTheTankHatch
  nextView
] 