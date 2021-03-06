local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local style = require("ui/hud/style.nut")
local {vehicleEngineBroken, vehicleTransmissionBroken, vehicleTracksBroken, vehicleWheelsBroken,
  vehicleTurretHorDriveBroken, vehicleTurretVerDriveBroken, inVehicle} = require("ui/hud/state/vehicle_state.nut")
local string = require("std/string.nut")

local vehicleCantMoveWarnings = [
  {state = vehicleEngineBroken, text = @() ::loc("hud/engine_broken", "engine broken")}
  {state = vehicleTransmissionBroken, text = @() ::loc("hud/transmission_broken", "transmission broken")}
  {state = vehicleTracksBroken, text = @() ::loc("hud/tracks_broken", "tracks broken")}
  {state = vehicleWheelsBroken, text = @() ::loc("hud/wheels_broken", "wheels broken")}
]

local vehicleTurretDriveWarnings = [
  {state = vehicleTurretHorDriveBroken, text = @() ::loc("hud/turret_hor_drive_broken", "horizontal drive broken")}
  {state = vehicleTurretVerDriveBroken, text = @() ::loc("hud/turret_ver_drive_broken", "vertical drive broken")}
]

local watch = [ inVehicle ]
watch.extend(vehicleCantMoveWarnings.map(@(w) w.state))
watch.extend(vehicleTurretDriveWarnings.map(@(w) w.state))

local function addTip(tips, warnings, msgKey, msgDefVal) {
  local reasons = warnings.filter(@(w) w.state.value).map(@(w) w.text())
  local text = reasons.len() > 0 ? ::loc(msgKey, msgDefVal, {reason = string.implode(reasons, ", ")}) : null
  local tip = tipCmp({
    text = text
    textColor =  style.DEFAULT_TEXT_COLOR
  })
  if (tip != null)
    tips.append(tip)
}

return function () {
  local tips = []

  if (inVehicle.value) {
    addTip(tips, vehicleCantMoveWarnings, "hud/vehicle_cant_move", "Vehicle can't move: {reason}") //warning disable: -forgot-subst
    addTip(tips, vehicleTurretDriveWarnings, "hud/vehicle_turret_cant_move", "Vehicle turret can't move: {reason}") //warning disable: -forgot-subst
  }

  return {
    watch = watch
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(5)

    children = tips
  }
}
 