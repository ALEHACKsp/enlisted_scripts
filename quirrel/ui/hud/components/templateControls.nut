local {isGamepad} = require("ui/control/active_controls.nut")
local {textListFromAction, buildElems, makeSvgImgFromText} = require("ui/control/formatInputBinding.nut")
local { HUD_TIPS_HOTKEY_FG } = require("ui/hud/style.nut")
local style = {
  textColor = Color(180,180,180,180)
  hotkeyColor = HUD_TIPS_HOTKEY_FG
}
local controlOpenTag=@"{controls{"
local closeTag = @"}}"

local token = @(tokenType, value) { type = tokenType, value = value }

local function tokenizeRow(text) {
  local res = []
  local start = 0
  local end = 0
  do {
    start = text.indexof(controlOpenTag, end)
    if (start == null)
      break
    local close = text.indexof(closeTag, start + controlOpenTag.len())
    if (close == null)
      break
    if (start > end)
      res.append(token("text", text.slice(end, start)))
    res.append(token("control", text.slice(start + controlOpenTag.len(), close)))
    end = close + closeTag.len()
  } while(start != null)

  if (end < text.len() - 1)
    res.append(token("text", text.slice(end)))

  return res
}

local function tokenizeTextWithShortcuts(text){
  local rows = text.split("\n")
  return rows.map(tokenizeRow)
}


local function textFunc(text){
  return {
    text = text font=Fonts.small_text
    color = style.hotkeyColor, rendObj = ROBJ_DTEXT
    padding = [0, hdpx(4)]
    vplace = ALIGN_CENTER
  }
}
local function makeControlText(text){
  return (text==null || text=="") ? null
  : {
    rendObj = isGamepad.value ? null : ROBJ_FRAME
    color = style.hotkeyColor
    vplace = ALIGN_CENTER
    children = textFunc(text)
  }
}

local imgHeight = ::calc_comp_size({font=Fonts.small_text text="A" rendObj=ROBJ_DTEXT})[1]

local function mkControlImg(text){
  return (text!=null && text!="") ? makeSvgImgFromText(text, imgHeight) : null
}

local function controlView(textList){
  local controlElems = buildElems(textList, {textFunc = makeControlText, eventTextFunc = textFunc,imgFunc=mkControlImg, compact = false, eventTypesAsTxt = true})
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(2)
    children = controlElems
  }
}

local function controlHint(control){
  local column = isGamepad.value ? 1 : 0
  local textList = textListFromAction(control, column)
  if (textList.filter(@(v) v!="").len() == 0)
    return null
  return controlView(textList)
}

local dtext = @(text){
  font = Fonts.small_text, color = style.textColor
  rendObj = ROBJ_DTEXT
  text = text
}

local EmptyControl = {}
local tokensView = {
  control = function(v) {
    local controlComp = controlHint(v)
    if (controlComp==null)
      return EmptyControl
    local name = ::loc("controls/{0}".subst(v))
    return {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      children = [
        controlComp
        dtext(" - {0}".subst(name))
      ]
    }
  }

  text = @(v) dtext(::loc(v))
}

local function viewControlToken(token_to_process) {
  local ctor = tokensView[token_to_process.type]
  return ctor ? ctor(token_to_process.value) : null
}

local function makeHintsRows(hintsTokens) {
  return hintsTokens.map(function(textRow) {
    local children = textRow.map(viewControlToken)
    if (children.indexof(EmptyControl)!=null)
      return null
    return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = textRow.map(viewControlToken)
    }
  })
}


return {
  tokenizeTextWithShortcuts = tokenizeTextWithShortcuts
  makeHintsRows = makeHintsRows
  controlView = controlView
  style = style
} 