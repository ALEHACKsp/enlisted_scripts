local {exit_game} = require("app")
local textarea = require("daRg/components/textArea.nut")
local JB = require("ui/control/gui_buttons.nut")

local winColor = Color(255,200,50,200)
local loseColor = Color(200,40,20,200)
local neutralColor = Color(150,180,250,150)
local textFx = {font=Fonts.huge_text fontFxColor = Color(0, 0, 0, 60)  fontFxFactor = 48 fontFx = FFT_GLOW halign=ALIGN_CENTER}


const shortDebriefingTime = 5

local animations = [
  { prop=AnimProp.opacity, from=0, to=1 duration=0.5, play=true, easing=InOutCubic}
  { prop=AnimProp.scale, from=[2,2], to=[1,1], duration=0.3, play=true, easing=InOutCubic}
  { prop=AnimProp.opacity, from=1, to=0 duration=0.5, playFadeOut=true, easing=InOutCubic}
  { prop=AnimProp.scale, from=[1,1], to=[2,2], duration=0.3, playFadeOut=true, easing=InOutCubic}
]

local requestExitToLobby = ::Watched(false).subscribe(@(v) v ? exit_game() : null)

local function closeAction() {
  requestExitToLobby(true)
}

local function mkShortDebriefing(debriefing){
  local result = debriefing?.result
  local isVictory = result?.success
  local function info(){
    local title = textarea( " ".concat((result?.title ?? ""), result.who),
      textFx.__merge({
        size = [sh(100), SIZE_TO_CONTENT]
        color = isVictory ? winColor
          : result?.fail ? loseColor
          : neutralColor
      }))
    return {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      gap = sh(1)
      pos = [0, -sh(20)]
      size = SIZE_TO_CONTENT
      children = [ title ]
    }
  }
  return {
    key = "debriefingRootShort"
    size = [sw(100),sh(100)]
    function onDetach(){
      ::gui_scene.clearTimer(closeAction)
    }
    function onAttach() {
      ::gui_scene.setTimeout(shortDebriefingTime, closeAction)
    }
    children = [
     {
        valign = ALIGN_CENTER
        size = flex()
        children = info
      }
    ]

    hotkeys = [["^{0} | @HUD.GameMenu | Esc".subst(JB.B), {action = closeAction, description={skip=true}}]]

    transform = {pivot = [0.5, 0.25]}
    animations = animations
    sound = {
      attach = isVictory ? "ui/victory" : "ui/fail"
      detach = "ui/menu_highlight"
    }
  }
}

local function mkDebriefing(debriefingData) {
  local function debriefing() {
    local debriefingV = debriefingData.value
    local children = mkShortDebriefing(debriefingV)

    return {
      children = children
      watch = [debriefingData]
    }
  }
  return debriefing
}

return mkDebriefing
 