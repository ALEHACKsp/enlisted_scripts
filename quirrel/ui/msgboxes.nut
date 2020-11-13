local msgbox = require("ui/components/msgbox.nut")

::gui_scene.setShutdownHandler(function sceneShutdownHandler() {
  msgbox.widgets.update([])
})

local msgboxes = @() {
  size = flex()
  children = msgbox.widgets.value
  watch = msgbox.widgets
}


return {msgboxes} 