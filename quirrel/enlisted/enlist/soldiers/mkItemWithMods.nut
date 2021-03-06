local { insideBorderColor, defInsideBgColor, smallPadding, unitSize, bigPadding, soldierWndWidth, activeBgColor, hoverBgColor } = require("enlisted/enlist/viewConst.nut")
local { getModSlots, objInfoByGuid } = require("model/state.nut")
local { mkItem } = require("components/itemComp.nut")
local { iconByItem } = require("itemsInfo.nut")

local defItemSize = [soldierWndWidth - 2 * bigPadding, 2 * unitSize] //!!TODO: move it to style
local MAKE_PARAMS = { //+all params of itemComp
  item = null
  itemSize = defItemSize
  soldierGuid=null
  isInteractive = true
  isDisabled = false
  onClickCb = @(params) null
  onDoubleClickCb = null
  onHoverCb = null
  selectedKey = Watched(null)
  isXmb = false
  hasUnseenSign = Watched(false)
  hasModsUnseenSign = Watched(false)
}

local function modItemCtor(item, slotType, itemSize, selected, flags, group){
  return iconByItem(item, {
    width = itemSize[0] - 2 * smallPadding, height = itemSize[1] - 2 * smallPadding
  })
}

local modBgStyle = @(sf, isSelected) {
  rendObj = ROBJ_BOX
  fillColor = isSelected ? activeBgColor
    : sf & S_HOVER ? hoverBgColor
    : defInsideBgColor
  borderColor = insideBorderColor
  borderWidth = hdpx(1)
}

local function mkItemMods(p) {
  local slots = getModSlots(p.item)
  if (!slots.len())
    return null

  local modHeight = 0.5 * p.itemSize[1]
  local modSize = [2 * modHeight, modHeight]
  return {
    size = SIZE_TO_CONTENT
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    margin = smallPadding
    flow = FLOW_HORIZONTAL
    stopHover = true
    children = slots.map(@(slot) mkItem({
      isXmb = p.isXmb
      item = objInfoByGuid.value?[slot.equipped]
      itemSize = modSize
      scheme = slot.scheme
      soldierGuid = p.item.guid
      slotType = slot.slotType
      bgStyle = modBgStyle
      isInteractive = p.isInteractive
      hasUnseenSign = p.hasUnseenSign
      isDisabled = p.isDisabled
      onClickCb = p.onClickCb
      onDoubleClickCb = p.onDoubleClickCb
      onHoverCb = p.onHoverCb
      selectedKey = p.selectedKey

      itemCtor = modItemCtor
      emptySlotChildren = @(...) null
    }))
  }
}

local function mkItemWithMods(p = MAKE_PARAMS) {
  p = MAKE_PARAMS.__merge(p)
  local mods = mkItemMods(p.__merge({ hasUnseenSign = p.hasModsUnseenSign }))
  if (mods)
    p.__update({ mods = mods })
  return {
    size = SIZE_TO_CONTENT
    children = mkItem(p)
  }
}

return mkItemWithMods 