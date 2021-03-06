local {defTxtColor, noteTxtColor, bigPadding, textBgBlurColor, smallPadding,
  hoverBgColor, defBgColor, hoverTxtColor, activeTxtColor} = require("enlisted/enlist/viewConst.nut")

local txt = @(text) {
  rendObj = ROBJ_DTEXT
  color = defTxtColor
}.__update(typeof text != "table" ? { text = text } : text)

local note = @(text) {
  rendObj = ROBJ_DTEXT
  color = noteTxtColor
  font = Fonts.tiny_text
}.__update(typeof text != "table" ? { text = text } : text)

local noteTextArea = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = noteTxtColor
  font=Fonts.tiny_text
}.__update(typeof text != "table" ? { text = text } : text)

local function bigTextWithNote(noteText, mainText) {
  local mainTextParams = (typeof mainText == "table") ? mainText : { text = mainText }
  return {
    flow = FLOW_HORIZONTAL
    children = [
      note(noteText)
      {
        rendObj = ROBJ_DTEXT
        font = Fonts.big_text
        color = defTxtColor
        margin = [0, bigPadding]
      }.__update(mainTextParams)
    ]
  }
}

local sceneHeaderText = @(text) {
  rendObj = ROBJ_DTEXT
  font = Fonts.big_text
  text = text
  color = defTxtColor
}

local sceneHeader = @(text) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = textBgBlurColor
  padding = [0, smallPadding]
  children = sceneHeaderText(text)
}

local function btn(params){
  local sFlags = params?.stateFlags ?? Watched(0)
  local group = params?.group ?? ::ElemGroup()
  local text = params?.text
  local fillColorCtr = params?.fillColorCtr ?? @(flags) (flags & S_HOVER) ? hoverBgColor : defBgColor
  local colorCtr = params?.colorCtr ?? @(flags) (flags & S_HOVER) ? hoverTxtColor : defTxtColor
  return @() {
    watch = [sFlags]
    onElemState = @(sf) sFlags.update(sf)
    group = group
    rendObj = ROBJ_BOX
    size = SIZE_TO_CONTENT
    padding = hdpx(2)
    children = {
      color = colorCtr(sFlags.value)
      rendObj = ROBJ_DTEXT text=text
    }
    fillColor = fillColorCtr(sFlags.value)
    borderWidth = 0
    behavior = [Behaviors.Button]
    halign = ALIGN_CENTER
  }.__update(params)
}


local function mCtor(ctor, selCtor, watch, checkSelected=@(opt, idx, watch) watch.value==idx, onSelect=null, clickHandler = null, dblClickHandler = null){
  return function (opt, idx) {
    local group = ::ElemGroup()
    local stateFlags = ::Watched(0)
    onSelect = onSelect ?? @(opt, idx) watch(idx)
    clickHandler = clickHandler ?? @(opt, idx) null
    dblClickHandler = dblClickHandler ?? @(opt, idx) null
    return @(){
      children = checkSelected(opt,idx,watch) ? selCtor(opt, idx, group, stateFlags) : ctor(opt, idx, group, stateFlags)
      size = SIZE_TO_CONTENT
      behavior = Behaviors.Button
      onElemState=@(sf) stateFlags(sf)
      watch = stateFlags
      onClick = @() onSelect(opt, idx) || clickHandler(opt, idx)
      onDoubleClick = @() dblClickHandler(opt,idx)
    }
  }
}

local function genericSelList(params = {}){
  //ctors for selected and regular elems
  //watch is int (index in options), list is list of anything
  local watch = params.watch
  local options = params.options
  local ctor = params.ctor
  local selCtor = params?.selCtor ?? ctor
  local checkSelected = params?.checkSelected ?? @(opt, idx, obs) obs.value==idx
  local onSelect = params?.onSelect
  return function(){
    local ct = mCtor(ctor, selCtor, watch, checkSelected, onSelect, params?.clickHandler, params?.dblClickHandler)
    return {
      flow = FLOW_HORIZONTAL
      children = options.map(ct)
      gap = hdpx(1)
      size = SIZE_TO_CONTENT
      watch = watch
    }.__update(params?.style ?? {})
  }
}

local function select(watch, options, objStyle = {flow=FLOW_HORIZONTAL, gap=hdpx(5) rendObj=ROBJ_SOLID color=Color(0,0,0,50)}){
  return genericSelList({
    watch=watch, options=options, style = objStyle
    checkSelected = @(opt, idx, watch) watch.value==opt
    ctor = @(opt, idx, group, stateFlags) txt({text=opt, key=idx})
    selCtor = @(opt, idx, group, stateFlags) txt({text=opt color = Color(255,255,255), key=idx})
    onSelect = @(opt, idx) watch(opt)
  })
}

local autoscrollText = ::kwarg(function(text, size = null, group = null, color = null, vplace = null, textParams = {}, params = {}){
  return {
    clipChildren = true
    children = {
      children = txt({ text = text, color = color }.__update(textParams))
      size = size ?? [flex(), SIZE_TO_CONTENT]
      behavior = group ? Behaviors.Marquee : [Behaviors.Marquee, Behaviors.Button]
      skipDirPadNav = group == null
      group = group
      scrollOnHover = true
    }.__merge(params)
    size = size ?? [flex(), SIZE_TO_CONTENT]
    group = group
    vplace = vplace
  }
})

local progressBar = ::kwarg(function(value, height = ::hdpx(7), width = flex(),
  color = activeTxtColor, bgColor = defBgColor, addValue = 0,
  addValueColor = activeTxtColor, addValueAnimations = null
) {
  local valueProgress = ::clamp(100.0 * value, 0, 100)
  return {
    rendObj = ROBJ_BOX
    size = [width, height]
    flow = FLOW_HORIZONTAL
    margin = [smallPadding, 0]
    fillColor = bgColor
    borderColor = color
    children = [
      {
        rendObj = ROBJ_SOLID
        size = [pw(valueProgress), flex()]
        color = color
      }
      addValue > 0
      ? {
          rendObj = ROBJ_SOLID
          size = [pw(::clamp(100.0 * addValue, 0, 100 - valueProgress)), flex()]
          color = addValueColor
          transform = { pivot = [0, 0] }
          animations = addValueAnimations
        }
      : null
    ]
  }
})

return {
  txt = txt
  note = note
  noteTextArea = noteTextArea
  autoscrollText = autoscrollText
  bigTextWithNote = bigTextWithNote
  sceneHeader = sceneHeader
  sceneHeaderText = sceneHeaderText
  btn = btn
  horSelect = @(watch, options, style={gap=hdpx(5) rendObj=ROBJ_SOLID color=Color(0,0,0,50)}) select(watch, options, style.__merge({flow=FLOW_HORIZONTAL}))
  verSelect = @(watch, options, style={gap=hdpx(5) rendObj=ROBJ_SOLID color=Color(0,0,0,50)}) select(watch, options, style.__merge({flow=FLOW_VERTICAL}))
  select = genericSelList
  progressBar = progressBar
} 