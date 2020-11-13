local {isVisible, totalMembersBeforeShot, deadMembers} = require("enlisted/ui/hud/state/hitcamera.nut")

return @() {
  watch = [isVisible]
  size = !isVisible.value ? null : [hdpx(240), hdpx(110)]
  children = !isVisible.value ? null : {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = Color(0,0,0,80)
    size = flex()
    flow = FLOW_VERTICAL
    children = [
      {
        rendObj=ROBJ_DTEXT
        color = Color(190,190,190,180)
        text = (totalMembersBeforeShot.value == 0)
                ? ::loc("hitcameraKillledMembers/empty")
                : (deadMembers.value != 0)
                ? ::loc("hitcameraKillledMembers/killed", {deadMembers=deadMembers.value})
                : ::loc("hitcameraKillledMembers/notKilled")
      }
      {
        size = flex()
        behavior = Behaviors.HitCamera
      }
    ]
  }
} 