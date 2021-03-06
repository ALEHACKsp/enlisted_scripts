local openUrl = require("enlist/openUrl.nut")
local loc = require("dagor.localize").loc

local defStyle = {
  defTextColor = Color(200,200,200)
  ulSpacing = hdpx(15)
  ulGap = hdpx(5)
  ulBullet = {rendObj = ROBJ_DTEXT text=" • "}
  ulNoBullet= { rendObj = ROBJ_DTEXT, text="   " }
  h1Font = Fonts.huge_text
  h2Font = Fonts.big_text
  textFont = Fonts.medium_text
  noteFont = Fonts.small_text
  h1Color = Color(220,220,250)
  h2Color = Color(200,250,200)
  urlColor = Color(170,180,250)
  emphasisColor = Color(245,245,255)
  urlHoverColor = Color(220,220,250)
  noteColor = Color(128,128,128)
  padding = hdpx(5)
}

local noTextFormatFunc = @(object, style=defStyle) object

local function textArea(params, formatTextFunc=noTextFormatFunc, style=defStyle){
  return {
    rendObj = ROBJ_TEXTAREA
    text = params?.v
    behavior = Behaviors.TextArea
    color = style?.defTextColor ?? defStyle.defTextColor
    size = [flex(), SIZE_TO_CONTENT]
  }.__update(params)
}

local function url(data, formatTextFunc=noTextFormatFunc, style=defStyle){
  if (data?.url==null)
    return textArea(data, style)
  local stateFlags = Watched(0)
  return function() {
    local color = stateFlags.value & S_HOVER ? style.urlHoverColor : style.urlColor
    return {
      rendObj = ROBJ_DTEXT
      text = data?.v ?? loc("see more...")
      behavior = Behaviors.Button
      color = color
      watch = stateFlags
      onElemState = @(sf) stateFlags(sf)
      children = {rendObj=ROBJ_FRAME borderWidth = [0,0,hdpx(1),0] color=color, size = flex()}
      onClick = function() {
        openUrl(data.url)
      }
    }.__update(data)
  }
}

local function mkUlElement(bullet){
  return function (elem, formatTextFunc=noTextFormatFunc, style=defStyle) {
    local res = formatTextFunc(elem)
    if (res==null)
      return null
    if (::type(res)!="array")
      res = [res]
    return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [bullet].extend(res)
    }
  }
}
local function mkList(elemFunc){
  return function(obj, formatTextFunc=noTextFormatFunc, style=defStyle) {
    return obj.__merge({
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      children = obj.v.map(@(elem) elemFunc(elem, formatTextFunc, style))
    })
  }
}
local function horizontal(obj, formatTextFunc=noTextFormatFunc, style=defStyle){
  return obj.__merge({
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    children = obj.v.map(@(elem) formatTextFunc(elem))
  })
}

local function vertical(obj, formatTextFunc=noTextFormatFunc, style=defStyle){
  return obj.__merge({
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    children = obj.v.map(@(elem) formatTextFunc(elem))
  })
}

local hangingIndent = calc_comp_size(defStyle.ulNoBullet)[0]

local bullets = mkList(mkUlElement(defStyle.ulBullet))
local indent = mkList(mkUlElement(defStyle.ulNoBullet))
local separatorCmp = {rendObj = ROBJ_FRAME borderWidth = [0,0,hdpx(1), 0] size = [flex(),hdpx(5)], opacity=0.2, margin=[hdpx(5), hdpx(20), hdpx(20), hdpx(5)]}

local function textParsed(params, formatTextFunc=noTextFormatFunc, style=defStyle){
  if (params?.v == "----")
    return separatorCmp
  return textArea(params, formatTextFunc, style)
}

local formatters = {
  defStyle = defStyle//for modification, fixme, make instances
  def=textArea,
  string=@(string, formatTextFunc, style=defStyle) textParsed({v=string}, style),
  textParsed = textParsed,
  textArea = textArea,
  text=textArea,
  hangingText=@(obj, formatTextFunc=noTextFormatFunc, style=defStyle) textArea(obj.__merge({ hangingIndent = hangingIndent }), style)
  h1 = @(text, formatTextFunc=noTextFormatFunc, style=defStyle) textArea(text.__merge({font=style.h1Font, color=style.h1Color, margin = [hdpx(15), 0, hdpx(25), 0]}), style)
  h2 = @(text, formatTextFunc=noTextFormatFunc, style=defStyle) textArea(text.__merge({font=style.h2Font, color=style.h2Color, margin = [hdpx(10), 0, hdpx(15), 0]}), style)
  emphasis = @(text, formatTextFunc=noTextFormatFunc, style=defStyle) textArea(text.__merge({color=style.emphasisColor, margin = [hdpx(5),0]}), style)
  image = @(obj, formatTextFunc=noTextFormatFunc, style=defStyle) {rendObj = ROBJ_IMAGE image=::Picture(obj.v) size = [flex(), hdpx(200)], keepAspect=true padding=style.padding, hplace = ALIGN_CENTER}.__update(obj)
  url = url
  note = @(obj, formatTextFunc=noTextFormatFunc, style=defStyle) textArea(obj.__merge({font=style.noteFont, color=style.noteColor}), style)
  preformat = @(obj, formatTextFunc=noTextFormatFunc, style=defStyle) textArea(obj.__merge({preformatted=FMT_KEEP_SPACES | FMT_NO_WRAP}), style)
  bullets = bullets
  indent = indent
  sep = @(obj, formatTextFunc=noTextFormatFunc, style=defStyle) separatorCmp.__merge(obj)
  horizontal = horizontal
  vertical = vertical
}

return formatters
 