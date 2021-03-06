local navState = require("navState.nut")
local {room, roomIsLobby, leaveRoom} = require("state/roomState.nut")

local textButton = require("components/textButton.nut")
local progressText = require("components/progressText.nut")

const TIME_TO_ALLOW_CANCEL = 7.0

local isNeedMsg = ::Computed(@()    room.value != null
                                && !roomIsLobby.value
                                && !(room.value?.gameStarted ?? false))
keepref(isNeedMsg)

local canCancelMsg = ::Watched(false)
isNeedMsg.subscribe(@(v) canCancelMsg(false))
local allowCancel = @() canCancelMsg(true)

isNeedMsg.subscribe(@(need) need ? ::gui_scene.setTimeout(TIME_TO_ALLOW_CANCEL, allowCancel)
  : ::gui_scene.clearTimer(allowCancel))

local cancelGameLaunchBtn = textButton(::loc("mainmenu/btnCancel"),
  @() leaveRoom(function(...){}),
  {
    halign = ALIGN_CENTER
    textParams = { font = Fonts.big_text, fontSize = hdpx(20) }
    style = { BgNormal = Color(250,130,0,250)}
  }
)

local function gameLaunchingMsg() {
  local cancelGameLaunch = canCancelMsg.value ? cancelGameLaunchBtn : null
  return {
    watch = canCancelMsg
    size = [pw(100), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    hplace = ALIGN_LEFT
    vplace = ALIGN_TOP
    pos = [0,sh(70)]
    valign = ALIGN_TOP
    halign = ALIGN_CENTER
    gap = hdpx(50)
    children = [
      progressText(::loc("gameIsFound"))
      cancelGameLaunch
    ]
  }
}

local open = @() navState.addScene(gameLaunchingMsg)
if (isNeedMsg.value)
  open()

isNeedMsg.subscribe(@(need) need ? open()
  : navState.removeScene(gameLaunchingMsg))
 