local baseCombo = require("daRg/components/combobox.nut")

local colors = require("ui/style/colors.nut")
local {buttonSound} = require("ui/style/sounds.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local gamepadImgByKey = require("gamepadImgByKey.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local JB = require("ui/control/gui_buttons.nut")

local font = Fonts.medium_text
local borderColor = colors.comboboxBorderColor

local listItemSound = {
  click  = "ui/button_click_inactive"
  hover = "ui/menu_highlight_settings"
  active = "ui/button_action"
}

local function fillColor(sf) {
  if (sf & S_ACTIVE)
    return colors.BtnBgActive
  if (sf & S_HOVER)
    return colors.BtnBgHover
  return colors.ControlBgOpaque
}

local hotkeyLoc = ::loc("controls/check/toggleOrEnable/prefix", "Toggle")

local function comboStyle(style_params) {
  local function label(params) {
    local sf = params?.sf ?? 0
    local color = colors.Active
    local disabled = params?.disabled ?? false
    if (disabled)
      color = colors.Inactive
    else if (sf & S_HOVER)
      color = colors.BtnTextHover

    local labelText = {
      group = params?.group
      rendObj = ROBJ_DTEXT
      //behavior = Behaviors.Marquee
      margin = [sh(0.5),sh(1.0),sh(0.5),sh(1.0)]
      text = params?.text
      color
      font
      size = [flex(), SIZE_TO_CONTENT]
    }

    local function popupArrow() {
      return !disabled ? {
        size = [ph(100), ph(100)]
        margin = hdpx(3)
        children = {
          rendObj = ROBJ_DTEXT
          padding = [hdpx(1), 0, 0, hdpx(2)]
          font = Fonts.fontawesome
          text = isGamepad.value ? fa["caret-right"] : fa["caret-down"]
          color
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
        }
      } : null
    }

    return {
      size = flex()
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        labelText
        popupArrow
      ]
    }
  }


  local function boxCtor(params) {
    local {comboOpen, disabled, text, stateFlags, group} = params
    local toggle = @() comboOpen(!comboOpen.value)
    local hotkeysElem = style_params?.useHotkeys ? {
      key = "hotkeys"
      hotkeys = [
        ["Left | J:D.Left", hotkeyLoc, toggle],
        ["Right | J:D.Right", hotkeyLoc, toggle],
      ]
    } : null

    return function() {
      local sf = stateFlags.value
      return{
        rendObj = ROBJ_BOX
        fillColor = fillColor(sf)
        size = flex()
        borderColor = borderColor
        children = [
          label({text=text, sf=sf, group=group, disabled=disabled}),
          sf & S_HOVER ? hotkeysElem : null
        ]
        borderWidth = hdpx(1)
        borderRadius = hdpx(3)
        watch = stateFlags
        margin = 0
      }
    }
  }

  local function listItem(text, action, is_current, params = null) {
    local group = ::ElemGroup()
    local stateFlags = ::Watched(0)

    return function() {
      local sf = stateFlags.value
      local textColor
      if (is_current)
        textColor = (sf & S_HOVER) ? colors.BtnTextHover : colors.TextHighlight
      else
        textColor = (sf & S_HOVER) ? colors.BtnTextHover : colors.TextDefault

      local bgColor = (sf & S_HOVER) ? colors.BtnBgHover : colors.ControlBgOpaque
      local hotkey_hint = (sf & S_HOVER) && isGamepad.value
        ? gamepadImgByKey.mkImageCompByDargKey(JB.A, {hplace = ALIGN_RIGHT vplace = ALIGN_CENTER}) : null

      return {
        behavior = [Behaviors.Button, Behaviors.Marquee]
        xmbNode = params?.xmbNode
        scrollOnHover=true
        speed =[hdpx(100),hdpx(1000)]
        delay =0.5
        size = [flex(), SIZE_TO_CONTENT]
        group = group
        watch = [stateFlags, isGamepad]

        rendObj = ROBJ_BOX
        fillColor = bgColor
        padding = [0,hdpx(8),0,hdpx(8)]
        borderWidth = 0
        flow = FLOW_HORIZONTAL
        onClick = action
        onElemState = @(nsf) stateFlags.update(nsf)
        sound = listItemSound

        children = [
          {
            rendObj = ROBJ_DTEXT
            margin = sh(0.5)
            group
            font
            text
            color = textColor
          }
          {size = [flex(),0]}
          hotkey_hint
        ]
      }
    }
  }


  local function closeButton(onClick) {
    return {
      size = flex()
      behavior = Behaviors.Button
      onClick
      hotkeys = [["^Esc | {0}".subst(JB.B)]]
      //rendObj = ROBJ_FRAME
      //borderWidth = 1
      //color = colors.Active
    }
  }

  local function onOpenDropDown(itemXmbNode) {
    ::gui_scene.setXmbFocus(isGamepad.value ? itemXmbNode : null)
  }

  local function onCloseDropDown(boxXmbNode) {
    if (isGamepad.value)
      ::gui_scene.setXmbFocus(boxXmbNode)
  }

  local rootBaseStyle = {
    sound = buttonSound
  }

  return {
    popupBgColor = colors.ControlBgOpaque
    popupBdColor = borderColor
    popupBorderWidth = hdpx(1)
    dropDir = style_params?.dropDir
    boxCtor
    rootBaseStyle
    listItem
    itemGap = {rendObj=ROBJ_FRAME size=[flex(),hdpx(1)] color=borderColor}
    closeButton
    onOpenDropDown
    onCloseDropDown
  }
}


local function combo(wdata, options, style_params) {
  return baseCombo(wdata, options, comboStyle(style_params))
}

local export = class{
  //Big = combo(wdata, options)
  _call = @(self, wdata, options, style_params={}) combo(wdata, options, style_params)
}()

return export
 