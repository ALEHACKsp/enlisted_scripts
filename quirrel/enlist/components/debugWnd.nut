local colors = require("ui/style/colors.nut")
local { tostring_r, utf8ToLower } = require("std/string.nut")
local { makeVertScroll } = require("ui/components/scrollbar.nut")
local textButton = require("enlist/components/textButton.nut")
local textInput = require("ui/components/textInput.nut")

local modalWindows = require("daRg/components/modalWindows.nut")


local gap = ::hdpx(5)
local defFilterText = persist("filterText", @() ::Watched(""))
local wndWidth = sh(120)
local editboxWidth = hdpx(250)

local listButtonStyle = @(isSelected) isSelected
  ? {
      fillColor = Color(150,150,150)
      textParams = {color=Color(0,0,0,255)}
      margin = 0
    }
  : { margin = 0 }

local mkTabs = @(tabs, curTab) @() {
  watch = curTab
  children = wrap(tabs.map(@(t) textButton(t.id, @() curTab(t), listButtonStyle(t == curTab.value))),
    {
      width = wndWidth - editboxWidth - gap,
      hGap = gap, vGap = gap
    })
}


local textArea = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  font = Fonts.small_text
  color = colors.TextDefault
  rendObj=ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  preformatted = FMT_AS_IS //FMT_KEEP_SPACES
  text = text
}

local dataToText = @(data) tostring_r(data, { maxdeeplevel = 10, compact = false })

local function defaultRowFilter(rowData, rowKey, txt) {
  if (utf8ToLower(rowKey.tostring()).indexof(txt) != null)
    return true
  if (rowData == null)
    return false
  local dataType = ::type(rowData)
  if (dataType == "array" || dataType == "table") {
    foreach(key, value in rowData)
      if (defaultRowFilter(value, key, txt))
        return true
    return false
  }
  return utf8ToLower(rowData.tostring()).indexof(txt) != null
}

local function filterData(data, curLevel, filterLevel, rowFilter, countLeft) {
  local isArray = ::type(data) == "array"
  if (!isArray && ::type(data) != "table")
    return rowFilter(data, "") ? data : null

  local res = isArray ? [] : {}
  foreach(key, rowData in data) {
    local curData = rowData
    if (filterLevel <= curLevel) {
      local isVisible = countLeft.value >= 0 && rowFilter(rowData, key)
      if (!isVisible)
        continue
      countLeft(countLeft.value - 1)
      if (countLeft.value < 0)
        break
    }
    else {
      curData = filterData(rowData, curLevel + 1, filterLevel, rowFilter, countLeft)
      if (curData == null)
        continue
    }

    if (isArray)
      res.append(curData)
    else
      res[key] <- curData
    if (countLeft.value < 0)
      break
    continue
  }
  return (curLevel == 0 || res.len() > 0) ? res : null
}

local mkFilter = @(rowFilterBase, filterArr) filterArr.len() == 0 ? @(rowData, key) true
  : function(rowData, key) {
      foreach(anyList in filterArr) {
        local res = true
        foreach(andText in anyList)
          if (!rowFilterBase(rowData, key, andText)) {
            res = false
            break
          }
        if (res)
          return true
      }
      return false
    }

local mkInfoBlockKey = 0
local function mkInfoBlock(curTabV, filterText) {
  local dataWatch = curTabV.data
  local textWatch = ::Watched("")
  local recalcText = function() {
    local filterArr = utf8ToLower(filterText.value).split("||").map(@(v) v.split("&&"))
    local rowFilterBase = curTabV?.rowFilter ?? defaultRowFilter
    local rowFilter = mkFilter(rowFilterBase, filterArr)
    local countLeft = ::Watched(curTabV?.maxItems ?? 100)
    local resData = filterData(dataWatch.value, 0, curTabV?.recursionLevel ?? 0, rowFilter, countLeft)
    local resText = dataToText(resData)
    if (countLeft.value < 0)
      resText = $"{resText}\n...... has more items ......"
    textWatch(resText)
  }
  recalcText()

  local function timerRestart(_) {
    ::gui_scene.clearTimer(recalcText)
    ::gui_scene.setTimeout(0.8, recalcText)
  }
  filterText.subscribe(timerRestart)

  mkInfoBlockKey++
  return @() textArea(textWatch.value).__update({
    key = mkInfoBlockKey,
    watch = textWatch,
    function onDetach() {
      ::gui_scene.clearTimer(recalcText)
      filterText.unsubscribe(timerRestart)
    }
  })
}

local mkCurInfo = @(curTab, filterText) @() {
  watch = curTab
  size = [flex(), SIZE_TO_CONTENT]
  children = mkInfoBlock(curTab.value, filterText)
}

local debugShopWnd = @(tabs, curTab, filterText) {
  size = [wndWidth + 2 * gap, sh(90)]
  stopMouse = true
  padding = gap
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = colors.BtnBgNormal
  flow = FLOW_VERTICAL
  gap = gap

  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      children = [
        mkTabs(tabs, curTab)
        textInput(filterText, {
          font = Fonts.small_text
          placeholder = "search..."
          textmargin = hdpx(5)
          margin = 0
        }, {
          onChange = @(value) filterText(value)
          onEscape = @() filterText("")
        })
      ]
    }
    makeVertScroll(mkCurInfo(curTab, filterText))
  ]
}

local function openDebugWnd(tabs, wndUid = "debugWnd", curTab = null, filterText = defFilterText) {
  curTab = curTab ?? ::Watched(tabs[0])
  local close = @() modalWindows.remove(wndUid)

  modalWindows.add({
    key = wndUid
    size = [sw(100), sh(100)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = colors.ModalBgTint
    onClick = close
    children = debugShopWnd(tabs, curTab, filterText)
    hotkeys = [["^J:B | Esc", { action = close, description = ::loc("Cancel") }]]
  })
}

return {
  openDebugWnd = ::kwarg(openDebugWnd)
  defaultRowFilter = defaultRowFilter
} 