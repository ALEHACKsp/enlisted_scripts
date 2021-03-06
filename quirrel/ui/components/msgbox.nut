local msgbox = require("daRg/components/msgbox.nut")

local JB = require("ui/control/gui_buttons.nut")
local cursors = require("ui/style/cursors.nut")
local colors = require("ui/style/colors.nut")
local {isGamepad} = require("ui/control/active_controls.nut")

local textButton = require("enlist/components/textButton.nut")
local fontIconButton = require("enlist/components/fontIconButton.nut")


local eventHandlersStopper = {
  ["HUD.ChatInput"] = @(event) EVENT_BREAK
}

local styling = {
  cursor = cursors.normal

  Root = {
    hooks = HOOK_ATTACH
    actionSet = "StopInput"
    rendObj = ROBJ_WORLD_BLUR_PANEL
    stopMouse = true
    stopHotkeys = true
    fillColor = Color(0,0,0,120)
    borderColor = colors.WindowBd
    borderWidth = [hdpx(1),0,hdpx(1),0]
    padding = hdpx(10)
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [sw(100), SIZE_TO_CONTENT]
    minHeight = sh(40)
    transform ={pivot =[0.5,0.5]}
    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.25, play=true, easing=OutCubic }
      { prop=AnimProp.scale,  from=[1, 0], to=[1,1], duration=0.2, play=true, easing=OutQuintic }
    ]
  }
  moveMouseCursor = isGamepad
  closeKeys = "Esc | {0}".subst(JB.B)
  leftKeys = "L.Shift Tab | R.Shift Tab"
  rightKeys = "Tab"
  activateKeys = "Space | Enter"
//  maskKeys = "J:D.Up | J:D.Down"
  closeTxt = ::loc("Close")
  BgOverlay = {
    size = [sw(100), sh(100)]
    color = Color(0,0,0,220)
    rendObj = ROBJ_SOLID
    stopMouse = true
    zOrder = Layers.MsgBox
    sound = {
      hover  = "ui/menu_highlight"
      click  = "ui/button_click_inactive"
    }
    eventHandlers = eventHandlersStopper
    animations = [
      { prop=AnimProp.opacity, from=1, to=0, duration=0.15, playFadeout=true, easing=OutCubic }
      { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
    ]
  }

  button = function(desc, on_click) {
    local addKey = {key = desc?.key ?? desc}
    return textButton(desc?.text ?? "???", on_click, (desc?.customStyle!=null) ? desc.customStyle.__merge(addKey) : addKey)
  }

  messageText = function(params) {
    local text = params?.text
    if (text instanceof Watched)
      text = text.value

    return {
      size = [flex(), SIZE_TO_CONTENT]
      minHeight = sh(50)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      padding = [sh(2), 0]
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          text = text
          font = Fonts.big_text
        }
        params?.children
      ]
    }
  }
}

local function showMessageWithStyle(p, msgStyle) {
  msgStyle.messageText = function(p) {
    return {
      halign = ALIGN_CENTER
      padding = [sh(2), 0]
      children = p.content
    }
  }
  msgbox.show(p, msgStyle)
}

local function showContentOnPictureBg (p) {
  local msgStyle = clone styling
  msgStyle.Root = styling.Root.__merge({ rendObj = null })
  msgStyle.BgOverlay = styling.BgOverlay.__merge({
    size = [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = {
      size = [SIZE_TO_CONTENT, sh(100)]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      color = null
      keepAspect = true
      image = p?.bgImage
    }
  })
  showMessageWithStyle(p, msgStyle)
}

local function showMessageWithContent (p, customStyle = {}) {
  local msgStyle = styling.__merge(customStyle)
  msgStyle.Root = clone msgStyle.Root
  msgStyle.Root.size = [ sw(100), SIZE_TO_CONTENT ]

  showMessageWithStyle(p, msgStyle)
}


local function showWithCloseButton(params) {
  local originalMessageText = styling.messageText
  local style = styling.__merge({
    messageText = @(textParams) {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        {
          flow = FLOW_HORIZONTAL
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          children = [
            params?.topPanel
            fontIconButton("close", {
              onClick = @() textParams?.handleButton(params?.onButtonCloseCb)
              size = [sh(5),sh(5)]
              hotkeys = [[JB.B, { description = { skip = true } }]]
            })
          ]
        }
        originalMessageText(textParams)
      ]
    }
  })
  msgbox.show(params, style)
}

return msgbox.__merge({
  show = @(params, style=styling) msgbox.show(params, style)
  showMessageWithContent = showMessageWithContent
  showContentOnPictureBg = showContentOnPictureBg
  showWithCloseButton = showWithCloseButton
  styling = styling
})
 