local colors = require("ui/style/colors.nut")
local modalWindows = require("daRg/components/modalWindows.nut")
local { actionInProgress } = require("globals/uistate.nut")
local spinner = require("enlist/components/spinner.nut")()

const WND_UID = "actionInProgress"

local close = @() modalWindows.remove(WND_UID)

local function open() {
  modalWindows.add({
    key = WND_UID
    zOrder = Layers.Blocker
//    rendObj = ROBJ_WORLD_BLUR_PANEL
//    fillColor = colors.ModalBgTint
    rendObj = ROBJ_SOLID
    color = colors.MenuBgOverlay
    onClick = @() null
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      {
        size = [sw(50), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        font = Fonts.medium_text
        halign = ALIGN_CENTER
        text = ::loc("xbox/waitingMessage")
      }
      spinner
    ]
  })
}

if (actionInProgress.value)
  open()

actionInProgress.subscribe(@(d) d ? open() : close())
 