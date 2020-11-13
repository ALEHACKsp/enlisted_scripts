local { squadsCfgById } = require("enlisted/enlist/soldiers/model/config/squadsConfig.nut")
local {bigPadding, unitSize, slotBaseSize} = require("enlisted/enlist/viewConst.nut")
local ui = require("daRg/components/std.nut")
local dtxt = require("daRg/components/text.nut").dtext
local itemComp = require("enlisted/enlist/soldiers/components/itemComp.nut")
local mkSoldierCard = require("enlisted/enlist/soldiers/mkSoldierCard.nut")
local { calc_golden_ratio_columns } = require("std/math.nut")

local itemSizeShort = [3.4 * unitSize, 1.8 * unitSize]
local itemSizeLong = [6.0 * unitSize, 1.8 * unitSize]
local itemSizeByTypeMap = {
  soldier = slotBaseSize
  sideweapon = itemSizeShort
  grenade = itemSizeShort
  scope = itemSizeShort
  knife = itemSizeShort
  reapair_kit = itemSizeShort
  medkits = itemSizeShort
  melee = itemSizeShort
  itemparts = itemSizeShort
}

local animDelay = 0
local trigger = ""
local getItemSize = @(itemType) itemSizeByTypeMap?[itemType] ?? itemSizeLong
local minColumns = 2

local TITLE_DELAY = 0.5
local ITEM_DELAY = 0.3
local ADD_OBJ_DELAY = 0.5
local SKIP_ANIM_POSTFIX = "_skip"


local dropTitle = @(titleText) {
  size = SIZE_TO_CONTENT
  margin = [bigPadding, 0]
  transform = {}
  animations = [
    { prop = AnimProp.opacity,   from = 0, to = 1, duration = 0.8, play = true, easing = InOutCubic}
    { prop = AnimProp.scale,     from = [1.5, 2], to = [1, 1], duration = 0.3, play = true, easing = InOutCubic}
    { prop = AnimProp.translate, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.3, play = true, easing = OutQuart}
    { prop = AnimProp.opacity, from = 1, to = 0 duration = 0.1, playFadeOut = true, easing = InOutCubic}
  ]
  children = dtxt(titleText, {
    size = SIZE_TO_CONTENT
    font = Fonts.big_text
  })
}

local function blockTitle(blockId, params) {
  animDelay += TITLE_DELAY

  return {
    transform = {}
    animations = params.hasAnim ? [
      { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay,
        play = true, easing = InOutCubic, trigger = trigger + SKIP_ANIM_POSTFIX }
      { prop = AnimProp.opacity,   delay = animDelay, from = 0, to = 1, duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.scale,     delay = animDelay, from = [1.5, 2], to = [1, 1], duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.translate, delay = animDelay, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.8,
        play = true, easing = OutQuart, trigger = trigger }
      { prop = AnimProp.opacity, from = 1, to = 0 duration = 0.1, playFadeOut = true, easing = InOutCubic}
    ] : []
    children = dtxt(::loc($"received/{blockId}"), {
      size = SIZE_TO_CONTENT
      hplace = ALIGN_LEFT
      font = Fonts.medium_text
      color = ui.gray
    })
  }
}

local mkItemByTypeMap = {
  soldier = function(p){
    local group = ::ElemGroup()
    local soldierInfo = p.item
    local stateFlags = ::Watched(0)
    return @() {
      watch = stateFlags
      group = group
      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags(sf)
      onClick = p.onClickCb

      children = mkSoldierCard({
        soldierInfo = soldierInfo
        squadInfo = squadsCfgById.value?[soldierInfo?.armyId ?? ""][soldierInfo?.squadId ?? ""]
        size = p.itemSize
        group = group
        sf = stateFlags.value
        isDisarmed = p?.isDisarmed
      })
    }
  }
}

local function mkItem(item, params) {
  animDelay += ITEM_DELAY
  return {
    transform = {}
    key = item?.guid ?? item
    animations = params.hasAnim ? [
      { prop = AnimProp.opacity,                      from = 0, to = 0, duration = animDelay,
        play = true, easing = InOutCubic, trigger = trigger + SKIP_ANIM_POSTFIX }
      { prop = AnimProp.opacity,   delay = animDelay, from = 0, to = 1, duration = 0.4,
        play = true, easing = InOutCubic, trigger = trigger, onFinish = params.onVisibleCb}
      { prop = AnimProp.scale,     delay = animDelay, from = [1.5, 2], to = [1, 1], duration = 0.5,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.translate, delay = animDelay, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.5,
        play = true, easing = OutCubic, trigger = trigger }
    ] : []

    children = (mkItemByTypeMap?[item?.itemtype] ?? itemComp.mkItem)({
      item = item
      onClickCb = params?.onItemClick ? @(...) params.onItemClick(item) : null
      itemSize = getItemSize(item?.itemtype)
      canDrag = false
      isInteractive = params?.onItemClick ? true : false
      pauseTooltip = params?.pauseTooltip ?? Watched(false)
      isDisarmed = params?.isDisarmed
    })
  }
}

local function blockContent(items, columnsAmount, params) {
  local itemSize = getItemSize(items?[0].itemtype)
  local containerWidth = columnsAmount * itemSize[0] + (columnsAmount - 1) * bigPadding
  return {
    flow = FLOW_HORIZONTAL
    children = wrap (items.map(@(item) mkItem(item, params)), {
      width = containerWidth
      hGap = bigPadding
      vGap = bigPadding
      hplace = ALIGN_CENTER
      halign = ALIGN_CENTER
    })
  }
}

local function itemsBlock(items, blockId, params) {
  if (!items.len())
    return null

  local itemSize = getItemSize(items?[0].itemtype)
  local columnsAmount = params.width != null
    ? ((params.width - (params.width / itemSize[0] - 1).tointeger() * bigPadding) / itemSize[0]).tointeger()
    : ::max(minColumns, calc_golden_ratio_columns(items.len(), itemSize[0] / itemSize[1]))

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = bigPadding

    children = (blockId ? [blockTitle(blockId, params)] : [])
      .append(blockContent(items, columnsAmount, params))
  }
}

local function appearAnim(comp, hasAnim) {
  animDelay += ADD_OBJ_DELAY
  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = comp

    animations = hasAnim ? [
      { prop = AnimProp.opacity,                    from = 0, to = 0, duration = animDelay,
        play = true, trigger = trigger + SKIP_ANIM_POSTFIX }
      { prop = AnimProp.opacity, delay = animDelay, from = 0, to = 1, duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
    ] : []
  }
}

local ITEMS_REWARDS_PARAMS = {
  hasAnim = true
  titleText = ""
  addChildren = []
  baseAnimDelay = 0.0
  hasItemTypeTitle = true
  animTrigger = "mkAnimatedItems"
  onVisibleCb = null
  width = null
  onItemClick = null
}

local function mkAnimatedItemsBlock(itemBlocks, params = ITEMS_REWARDS_PARAMS) {
  params = ITEMS_REWARDS_PARAMS.__merge(params)
  animDelay = params.baseAnimDelay
  trigger = params.animTrigger
  local underline = {
    rendObj = ROBJ_FRAME
    size = [pw(80), 1]
    margin = bigPadding
    borderWidth = [0, 0, 1, 0]
    color = Color(100, 100, 100, 50)
    transform = {}
    animations = params.hasAnim ? [
      { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 0.2,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.scale, delay = 0.2 from = [0, 1], to = [1, 1], duration = 1,
        play = true, easing = InOutCubic, trigger = trigger }
    ] : []
  }

  local blocks = itemBlocks.keys()

  local children = []
  if (params.titleText.len())
    children.append(
      dropTitle(params.titleText)
      underline
    )
  else
    animDelay -= TITLE_DELAY

  children.append({
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = blocks.map(@(blockId) itemsBlock(itemBlocks[blockId], params.hasItemTypeTitle ? blockId : null, params))
  })

  children.extend(params.addChildren.map(@(comp) appearAnim(comp, params.hasAnim)))

  return {
    totalTime = params.hasAnim ? animDelay : 0
    component = {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = children
    }
  }
}

return mkAnimatedItemsBlock
 