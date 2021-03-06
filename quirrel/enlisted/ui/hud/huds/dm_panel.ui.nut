local {isVisible} = require("enlisted/ui/hud/state/dm_panel.nut")

return @() {
  watch = [isVisible]
  size = !isVisible.value ? null : [hdpx(220), hdpx(220)]
  children = !isVisible.value ? null : {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = Color(0,0,0,80)
    size = flex()
    children = {
      size = flex()
      behavior = Behaviors.DMPanel
    }
  }
} 