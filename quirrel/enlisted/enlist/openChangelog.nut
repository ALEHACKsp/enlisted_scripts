local navState = require("enlist/navState.nut")
local JB = require("ui/control/gui_buttons.nut")
local { currentPatchnote, patchoteSelector } = require("changelog.ui.nut")

local fontIconButton = require("enlist/components/fontIconButton.nut")
local fa = require("daRg/components/fontawesome.map.nut")

local textButton = require("enlist/components/textButton.nut")
local {isGamepad} = require("ui/control/active_controls.nut")

local isOpened = persist("isOpened", @() Watched(false))
local {chosePatchnote, curPatchnoteIdx, nextPatchNote, prevPatchNote, updateVersion} = require("changeLogState.nut")

local close = @() isOpened(false)
local open = @() isOpened(true)

local gap = ::hdpx(10)
local btnNext  = textButton(::loc("shop/nextItem"), nextPatchNote, {hotkeys=[["^{0}".subst(JB.B)]], margin=0})
local btnClose = textButton(::loc("mainmenu/btnClose"), close, {hotkeys=[["^{0}".subst(JB.B)]], margin=0})
local closeBtn = fontIconButton(fa["close"], {
  skipDirPadNav = true
  onClick = close
  hplace = ALIGN_RIGHT
  hotkeys=[["^Esc | {0}".subst(JB.B), {description=::loc("Close")}]]
})

local function nextButton(){
  return {
    size = SIZE_TO_CONTENT
    children = curPatchnoteIdx.value != 0 ? btnNext : btnClose
    watch = [curPatchnoteIdx]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    behavior = Behaviors.RecalcHandler
    function onRecalcLayout(initial, elem) {
      if (initial && isGamepad.value) {
        ::move_mouse_cursor(elem, false)
      }
    }
  }
}

local attractorForCursorDirPad = {
  behavior = Behaviors.Button
  size = [hdpx(50), ph(66)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  eventPassThrough = true
}

local clicksHandler = {
  size = flex(), eventPassThrough = true,
  behavior = Behaviors.Button
  hotkeys = [
    ["^J:LB | Left", nextPatchNote, ::loc("shop/nextItem")],
    ["^J:RB | Right", prevPatchNote, ::loc("shop/previousItem")]
  ]
  onClick = nextPatchNote
}

local changelogRoot = {
  size = flex()
  children = [
    clicksHandler
    {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = Color(0,0,0,90)
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      padding = gap
      gap = gap
      children = [
        closeBtn
        currentPatchnote
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = gap
          valign = ALIGN_CENTER
          children = [
            patchoteSelector
            nextButton
          ]
        }
      ]
    }
    attractorForCursorDirPad
  ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hotkeys = [
    ["^J:Y | J:Start | Esc | Space", {action=close, description = ::loc("mainmenu/btnClose")}]
  ]
}

local addLogScene = @() navState.addScene(changelogRoot)
if (isOpened.value)
  addLogScene()
isOpened.subscribe(function(opened) {
  if (opened) {
    addLogScene()
    return
  }
  updateVersion()
  chosePatchnote(null)
  navState.removeScene(changelogRoot)
})

return {
  openChangelog = open
  isOpened = isOpened
}
 