local mkPieMenuDarg = require("daRg/components/mkPieMenu.nut")
local cursors = require("ui/style/cursors.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local dainput = require("dainput2")
local JB = require("ui/control/gui_buttons.nut")
local {mkHintRow, mkHotkey} = require("ui/components/uiHotkeysHint.nut")
local style = require("ui/hud/style.nut")

local cfgMax = {
  itemsOffset = 1
  gamepadHotkeys = ["J:LB", "J:D.Up", "J:RB", "J:D.Right", "J:Y", "J:D.Down", "J:X", "J:D.Left"]
}
local cfgByAmount = {
  [1] = ["J:D.Up"],
  [2] = ["J:D.Up", "J:D.Down"],
  [3] = ["J:D.Up", "J:D.Right", "J:D.Left"],
  [4] = ["J:D.Up", "J:D.Right", "J:D.Down", "J:D.Left"],
  [5] = ["J:D.Up", "J:D.Right", "J:D.Down", "J:X", "J:D.Left"],
  [6] = {
    itemsOffset = 1
    gamepadHotkeys = ["J:D.Left", "J:D.Up", "J:D.Right", "J:Y", "J:D.Down", "J:X"]
  },
  [7] = {
    itemsOffset = 1
    gamepadHotkeys = ["J:LB", "J:D.Up", "J:RB", "J:D.Right", "J:D.Down", "J:X", "J:D.Left"]
  },
}.map(@(v) ::type(v) != "array" ? v : { gamepadHotkeys = v })

local function locAction(action){
  return ::loc($"controls/{action}", action)
}
local activateHotkey = "^{0}".subst(JB.A)
local closeHotkey = "^Esc | {0}".subst(JB.B)

local isCurrent = @(sf, curIdx, idx) (sf & S_HOVER) || curIdx == idx

local white = Color(255,255,255)
local dark = Color(200,200,200)
local disabledColor = Color(60,60,60)
local curTextColor = Color(250,250,200,200)
local defTextColor = Color(150,150,150,50)
local disabledTextColor = Color(50, 50, 50, 50)

local function mkDefTxtCtor(text, available) {
  if (!(text instanceof ::Watched))
    text = ::Watched(text)
  return @(curIdx, idx)
    ::watchElemState(@(sf) {
      watch = [available, text]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = text.value
      color = !available.value ? disabledTextColor
        : isCurrent(sf, curIdx.value, idx) ? curTextColor
        : defTextColor
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      maxWidth = ::hdpx(140)
      valign = ALIGN_CENTER
    })
}

local function mkmkDefCtor(elemSize) {
  return function (curImage, fallbackImage=null, available = Watched(true)){
    if (curImage==null)
      return null
    local fallbackPicture = fallbackImage!=null ? ::Picture(fallbackImage) : null
    local function ctor(curIdx, idx){
      return ::watchElemState(function(sf) {
        local isWatched = curImage instanceof ::Watched
        local curVal = isWatched ? (curImage.value ?? "") : curImage
        return {
          image = ( curVal == "" ) ? fallbackPicture : ::Picture(curVal)
          fallbackImage = fallbackPicture
          watch = [available, isWatched ? curImage : null]
          rendObj = ROBJ_IMAGE
          color = !available.value ? disabledColor
            : (curIdx.value==idx || (sf & S_HOVER)) ? white : dark

          size = elemSize
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
        }
      })
    }
    return ctor
  }
}


local function mkBlurBack(radius){
  local size = [2*radius*1.02,2*radius*1.02]
  return{
    size = size
    rendObj = ROBJ_MASK
    image = ::Picture("ui/uiskin/white_circle.png?Ac")
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = { rendObj=ROBJ_WORLD_BLUR_PANEL size=size color = Color(190,190,190,190) }
  }
}

local mkSelectedActionHint = @(curIdx, available, actions, radius) function() {
  local res = { watch = curIdx }
  local action = actions?[curIdx.value]
  if (action == null)
    return res
  local text = available ? action?.text : action?.disabledtext
  if (!(text instanceof ::Watched))
    text = ::Watched(text)
  return res.__update({
    size = SIZE_TO_CONTENT
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = ::hdpx(10)
    children = [
      available && (curIdx.value !=null) ? mkHintRow(activateHotkey) : null
      @() {
        watch = text
        size = SIZE_TO_CONTENT
        halign = ALIGN_CENTER
        maxWidth = 0.7 * radius
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = available ? curTextColor : disabledTextColor
        text = text.value
      }
    ]
  })
}
local closeHint = {
  flow = FLOW_HORIZONTAL
  gap = ::hdpx(10)
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    mkHintRow(closeHotkey)
    {
      rendObj = ROBJ_DTEXT
      opacity = 0.5
      text = ::loc("pieMenu/close")
    }
  ]
}

local function mkPieMenuRoot(actions, curIdx, radius, showPieMenu, close = null) {
  close = close ?? @() showPieMenu(false)

  local descr = function(){
    local available = actions?[curIdx.value]?.available

    return {
      watch = available
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      gap = ::hdpx(40)
      flow = FLOW_VERTICAL
      children = [
        mkSelectedActionHint(curIdx, available?.value ?? true, actions, radius)
        closeHint
      ]
    }
  }
  local desc = {
    key = {}
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }
    hooks = HOOK_ATTACH
    actionSet = "PieMenu"
    hotkeys = [
      [activateHotkey, {description = { skip = true }, action = @() actions?[curIdx.value]?.onClick?()}],
      [closeHotkey, {description = {skip = true}, action = close}],
    ]

    children = [
      mkBlurBack(radius)
      mkPieMenuDarg({
        stickNo = 0
        devId = isGamepad.value ? DEVID_JOYSTICK : DEVID_MOUSE
        onClick = @(idx) actions?[idx]?.onClick?()
        radius = radius
        curIdx = curIdx
        children = [descr]
        objs = actions
      })
    ]
  }

  if (!isGamepad.value)
    desc.cursor <- cursors.normal

  return desc
}

local mkOnSelect = @(action, disabledAction, available)
  @() available?.value ?? true ? action() : disabledAction?()

local mkOnClick = @(a, onSelect, showPieMenu) function() {
  onSelect()
  if (a?.closeOnClick ?? false)
    showPieMenu(false)
}

local function textFunc(text) {
  return {
    fillColor = style.HUD_TIPS_HOTKEY_FG
    borderWidth = 0
    borderRadius = ::hdpx(2)
    size = SIZE_TO_CONTENT
    padding = [0, ::hdpx(3)]
    rendObj = ROBJ_BOX
//    color = Color(180,180,180,200)
    children = [
      {rendObj = ROBJ_DTEXT text = text color=Color(0,0,0)}
    ]
  }
}

local function mkCtor(ctor, mkDefCtor, image, fallbackImage, available, text, hotkey, action){
  available = available ?? ::Watched(true)
  local main = ctor ?? mkDefCtor(image, fallbackImage, available) ?? mkDefTxtCtor(text ?? "", available)
  return function (curIdx, idx){
    local hotkeyComp = hotkey == null ? null
      : @() {
          watch = [isGamepad, available]
          hplace = isGamepad.value ? ALIGN_RIGHT : ALIGN_LEFT
          vplace = isGamepad.value ? ALIGN_TOP : ALIGN_CENTER
          pos = isGamepad.value ? [::hdpx(10), -::hdpx(10)] : [-::hdpx(18), ::hdpx(3)]
          children = available.value ? mkHotkey(hotkey, action, {textFunc = textFunc}) : null
          size = SIZE_TO_CONTENT
        }
    return {
      children = [main(curIdx, idx), hotkeyComp]
      size = SIZE_TO_CONTENT
    }
  }
}

local idxToKbHotkey = @(idx) ((idx + 1) % 10).tostring()
local function combineHotkeys(list) {
  local all = list.filter(@(h) h != null)
  if (all.len() == 0)
    return null
  return "^{0}".subst(" | ".join(all))
}

local function shiftArray(arr, offset) {
  local total = arr.len()
  if (total < 2 || offset == 0)
    return arr
  local idx = (::clamp(offset, 1 - total, total - 1) + total) % total
  return arr.slice(idx, total).extend(arr.slice(0, idx))
}

local function filterAndUpdateActions(actions, showPieMenu, mkDefCtor){
  local { itemsOffset = 0, gamepadHotkeys } = cfgByAmount?[actions.len()] ?? cfgMax
  actions = actions.map(function(a, idx) {
    if (a == null || (::type(a?.action)=="string" && dainput.get_action_handle(a?.action, 0xFFFF) == dainput.BAD_ACTION_HANDLE)) //action invaild if there is no such action in actions config)
      return null
    local text = a?.text ?? ((::type(a.action)=="string") ? locAction(a.action) : null)
    local action = ::type(a.action) == "function" ? a.action : @() dainput.send_action_event(dainput.get_action_handle(a.action, 0xFFFF))
    local onSelect = mkOnSelect(action, a?.disabledAction, a?.available)
    local onClick = mkOnClick(a, onSelect, showPieMenu)
    local gpHotkey = gamepadHotkeys?[idx]
    local hotkeys = combineHotkeys([idxToKbHotkey(idx), gpHotkey])
    local ctor = mkCtor(a?.ctor, mkDefCtor, a?.image, a?.fallbackImage, a?.available, text, hotkeys, onClick)
    return a.__merge({
      text = text
      action = action
      ctor = ctor
      disabledtext = a?.disabledtext ?? ::loc("pieMenu/actionUnavailable", "{action} ({unavailable})", {action=text unavailable=::loc("unavailable")})
      onSelect = onSelect
      onClick = onClick

      //need to filter used shortcuts
      idx = idx
      gpHotkey = gpHotkey
    })
  })
  if (actions.len() == 1) //fill only half of pie menu when single action
    actions.append(null)
  actions = shiftArray(actions, itemsOffset)
  return actions
}

local function removeValue(list, value) {
  local idx = list.indexof(value)
  if (idx != null)
    list.remove(idx)
}

local function collectUnusedHotkeys(actions) {
  local gpUnused = clone cfgMax.gamepadHotkeys
  local idxUnused = cfgMax.gamepadHotkeys.map(@(_, idx) idx)
  foreach(action in actions) {
    removeValue(gpUnused, action?.gpHotkey)
    removeValue(idxUnused, action?.idx)
  }
  local allUnused = idxUnused.map(idxToKbHotkey)
    .extend(gpUnused)
  return combineHotkeys(allUnused)
}

local function mkPieMenu(actions, curIdx = ::Watched(null), showPieMenu = ::Watched(false),
  radius = ::Watched(::hdpx(350)), elemSize = null, close = null
){
  elemSize = elemSize ?? ::Computed(@() array(2, (0.4 * radius.value).tointeger()))

  return function(){
    local mkDefCtor = mkmkDefCtor(elemSize.value)
    local actionsV = filterAndUpdateActions(actions.value, showPieMenu, mkDefCtor)
    local hotkeysStubs = collectUnusedHotkeys(actionsV)
    return{
      key = "pieMenuListener"
      watch = [showPieMenu, isGamepad, actions, elemSize, radius]
      size = flex()
      children = !showPieMenu.value ? null
        : [
            mkPieMenuRoot(actionsV, curIdx, radius.value, showPieMenu, close)
            hotkeysStubs == null ? null
              : { key = hotkeysStubs, hotkeys = [[hotkeysStubs, @() null]] }
          ]
      behavior = Behaviors.RecalcHandler
      function onRecalcLayout(initial, elem) {
        if (initial)
          ::move_mouse_cursor(elem)
      }
    }
  }
}

return ::kwarg(mkPieMenu)
 