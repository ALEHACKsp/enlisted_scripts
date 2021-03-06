local JB = require("ui/control/gui_buttons.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local fontIconButton = require("fontIconButton.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local buttonParams = {
  onClick = @() null
  hotkeys=[[$"^Esc | {JB.B}", {description=::loc("Close")}]]
  skipDirPadNav = true
}

return @(override) {
  size = [hdpx(21), hdpx(21)]
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = @(){
    watch = isGamepad
    children = !isGamepad.value
      ? fontIconButton(fa["close"], buttonParams.__merge(override))
      : {behavior = Behaviors.Button}.__merge(buttonParams, override)
  }
} 