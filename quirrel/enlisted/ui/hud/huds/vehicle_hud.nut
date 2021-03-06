local {gear, neutralGear, rpm, cruiseControl, speed, isAutomaticTransmission, inTank} = require("ui/hud/state/vehicle_state.nut")

local mkText = @(txt) {
  text = txt
  padding = [0,hdpx(2),0,hdpx(2)]
  minHeight = sh(2)
  valign = ALIGN_BOTTOM
}

local mkSText = @(txt) mkText(txt).__update({
  rendObj = ROBJ_STEXT
  minWidth = sh(4)
})

local mkDText = @(txt) mkText(txt).__update({rendObj=ROBJ_DTEXT})

local mkRow = @(children) {
  children = children
  flow = FLOW_HORIZONTAL
}

const CRUISE_CONTROL_MAX = 3

local mkGear = @(g, neutral) g < neutral ? $"R{neutral-g}" : g == neutral ? "N" : $"{g-neutral}"
local mkCruiseControl = @(cc) cc < 0 ? "R" : cc >= CRUISE_CONTROL_MAX ? "MAX" : $"{cc}"

return @() {
  size = flex()
  flow = FLOW_VERTICAL
  watch = [gear, rpm, cruiseControl, speed, isAutomaticTransmission, inTank]
  children = !inTank.value ? null : [
    mkRow([mkSText("GEAR"), mkDText(mkGear(gear.value, neutralGear.value))])
    mkRow([mkSText("RPM"),  mkDText($"{rpm.value}")])
    mkRow([mkSText("SPD"),  mkDText($"{speed.value} km/h")])
    !isAutomaticTransmission.value ? null : mkRow([mkSText("CC"), mkDText(mkCruiseControl(cruiseControl.value))])
  ]
} 