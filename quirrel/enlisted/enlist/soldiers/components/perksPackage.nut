local { sound_play } = require("sound")
local { tooltip } = require("ui/style/cursors.nut")
local tooltipBox = require("ui/style/tooltipBox.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local math = require("std/math.nut")
local {
  smallPadding, bigPadding, defTxtColor, gap, perkIconSize,
  titleTxtColor, perkBgHover, perkBgLighten, perkBgDarken,
  activeBgColor, msgHighlightedTxtColor, perkBigIconSize,
  defBgColor
} = require("enlisted/enlist/viewConst.nut")
local colors = require("ui/style/colors.nut")
local perksStats = require("enlisted/enlist/soldiers/model/perks/perksStats.nut")
local perksList = require("enlisted/enlist/soldiers/model/perks/perksList.nut")
local perksPoints = require("enlisted/enlist/soldiers/model/perks/perksPoints.nut")
local colorize = require("enlist/colorize.nut")

const MIN_ROLL_PERKS = 10
const NEXT_ROLL_PERKS = 5


local mkText = @(txt) {
  rendObj = ROBJ_DTEXT
  font = Fonts.small_text
  text = txt
}

local flexTextArea = @(params) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  font = Fonts.small_text
  color = defTxtColor
  vplace = ALIGN_CENTER
  halign = ALIGN_LEFT
}.__update(params)

local mkSelectedPerkMark = @(isSelected, fontSize = null) !isSelected ? null
  : {
      rendObj = ROBJ_STEXT
      padding = bigPadding
      font = Fonts.fontawesome
      fontSize = fontSize
      text = fa["check"]
    }

local mkPerkAmountText = @(amount) amount <= 1 ? null
  : {
      rendObj = ROBJ_DTEXT
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      text = $"x{amount}"
    }

local perkPointIcon = @(pPointCfg, pPointSize = hdpx(32).tointeger()) {
  rendObj = ROBJ_IMAGE
  image = ::Picture("{0}:{1}:{1}:K".subst(pPointCfg.icon, pPointSize))
  color = pPointCfg.color
}

local perkPointCostText = @(pPointCfg, cost, format = "{cost}", isUnavailable = false) { //warning disable: -forgot-subst
  rendObj = ROBJ_DTEXT
  text = format.subst({cost = cost})
  color = isUnavailable ? colors.HighlightFailure : pPointCfg.color
}

local usedPerkPoints = @(pPointCfg, usedValue, totalValue) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    mkText(usedValue)
    perkPointCostText(pPointCfg, totalValue, "/{cost}")  //warning disable: -forgot-subst
    perkPointIcon(pPointCfg)
  ]
}

local function perkIcon(perk, iconSize) {
  local size = iconSize.tointeger()
  local statClassMask = (perk?.stats ?? {}).keys()
    .reduce(@(res, statId) res | (perksStats.stats?[statId]?.stat_class ?? 0), 0)
  return {
    size = [size, size]
    rendObj = ROBJ_IMAGE
    image = ::Picture("{0}:{1}:{1}:K".subst(
      perksStats.classesConfig?[statClassMask].image ?? perksStats.fallBackImage,
      size))
  }
}

local function mkPerkCostChildren(perk, isUnavailable = false) {
  local res = []
  local perkCost = perk?.cost ?? {}
  foreach (pPointId in perksPoints.pPointsList) {
    local pPointsValue = perkCost?[pPointId] ?? 0
    if (pPointsValue <= 0)
      continue

    local pPointCfg = perksPoints.pPointsBaseParams?[pPointId]
    res.append({
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        perkPointCostText(pPointCfg, pPointsValue, "{cost}", isUnavailable)  //warning disable: -forgot-subst
        perkPointIcon(pPointCfg)
      ]
    })
  }
  return res
}

local function mkPerkCostShort(perk, isUnavailable, statType) {
  local pPointsChildren = mkPerkCostChildren(perk, isUnavailable)
  if (pPointsChildren.len() <= 0)
    return null

  local onhoverTooltip = pPointsChildren
  if (isUnavailable){
    local statName = ::loc($"stat/{statType}_genitive")
    local tooltipText = ::loc("notEnoughPerkPointsHint", {statName})
    onhoverTooltip = flexTextArea({text = tooltipText, size = SIZE_TO_CONTENT})
  }
  return {
    size = [hdpx(50), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    behavior = Behaviors.Button
    onHover = @(on) tooltip.state(!on ? null
      : tooltipBox({
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          valign = ALIGN_CENTER
          children = onhoverTooltip
        }))
    children = pPointsChildren
  }
}

local function mkPerkCostFull(perk, override = {}) {
  local pPointsChildren = mkPerkCostChildren(perk)
  if (pPointsChildren.len() <= 0)
    return null
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gap
    children = [mkText(::loc("perkPointsTakeInfo")).__update({ color = defTxtColor })]
      .extend(pPointsChildren)
  }.__update(override)
}


local function getStatDescList(perk) {
  local res = []
  local stats = perk?.stats ?? {}
  foreach (statId, statValue in stats) {
    local value = statValue * (perksStats.stats?[statId]?.base_power ?? 0.0)
    local statValueText = math.round_by_value(value, 0.1)
      + (perksStats.stats?[statId]?.power_type ?? "")
    res.append(::loc($"stat/{statId}/desc", {
      value = colorize(colors.MsgMarkedText, statValueText)
    }))
  }
  return res
}

local perkUi = ::kwarg(
  function(perkId, amount = 1, isSelected = false, customStyle = {}) {
    local perk = perksList?[perkId]
    local statDescList = getStatDescList(perk)
    local iconSize = customStyle?.perkIconSize ?? perkIconSize
    local isUnavailable = customStyle?.isUnavailable ?? false
    local textParams = { font = customStyle?.font ?? Fonts.small_text, halign = customStyle?.halign ?? ALIGN_LEFT }
    local statType = isUnavailable ? perk?.cost.keys()[0] : ""

    return {
      key = perk
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      padding = smallPadding
      animations = perk ? null : [
        { prop = AnimProp.opacity, from = 0.6, to = 1, duration = 1, play = true, loop = true, easing = Blink}
      ]

      children = [
        {
          size = [iconSize, iconSize]
          children = [
            perkIcon(perk, iconSize)
            mkPerkAmountText(amount)
          ]
        }
        perk
          ? flexTextArea(textParams
              .__merge({ text = ", ".join(statDescList), color = defTxtColor }))
          : flexTextArea(textParams
              .__merge({ text = ::loc("choose_new_perk"), color = titleTxtColor }))
        mkPerkCostShort(perk, isUnavailable, statType)
        mkSelectedPerkMark(isSelected)
      ]
    }.__update(customStyle)
})

local function slotBg(slotNumber, cb = null, params = {})  {
  local stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    rendObj = ROBJ_BOX
    size = [flex(), SIZE_TO_CONTENT]
    behavior = cb ? Behaviors.Button : null
    onClick = cb
    onElemState = @(sf) stateFlags(sf)
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
    }
    fillColor = stateFlags.value & S_HOVER ? perkBgHover
      : (slotNumber % 2) ? perkBgLighten
      : perkBgDarken
    borderColor = activeBgColor
    borderWidth = [0, 0, stateFlags.value & S_HOVER ? 1 : 0, 0]
  }.__update(params)
}

local slot = ::kwarg(
  @(perkData, slotNumber = 0, cb = null, customStyle = {})
    slotBg(slotNumber, cb,
      perkUi({
        perkId = perkData.perkId
        amount = perkData?.amount ?? 1
        isSelected = perkData?.isSelected ?? false
        customStyle = {
          opacity = (perkData?.isAvailable ?? true) ? 1.0 : 0.5
          isUnavailable = !(perkData?.isAvailable ?? true)
        }.__update(customStyle)
      })))

local function bigSlot(perkId) {
  local perk = perksList?[perkId]
  local statDescList = getStatDescList(perk)
  return {
    size = perkBigIconSize
    padding = bigPadding
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          perkIcon(perk, hdpx(140))
          flexTextArea({ text = "\n".join(statDescList),
            color = defTxtColor,
            font = Fonts.medium_text,
            halign = ALIGN_CENTER
          })
        ]
      }
      mkPerkCostFull(perk, { vplace = ALIGN_BOTTOM, hplace = ALIGN_RIGHT })
    ]
  }
}

local function mkAppearAnimation(idx, total, onFinishCb) {
  local animDelay = idx * 0.4
  local xOffset = total.tofloat() / 2 - 0.5 - idx
  local angle = -80 + idx * 20
  return [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay + 0.05,
      play = true, easing = InOutCubic, trigger = "perks_roll_anim" }
    { prop = AnimProp.scale, from = [1.6,1.6], to = [1.6,1.6], duration = animDelay,
      play = true, easing = InOutCubic, trigger = "perks_roll_anim" }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.6, delay = animDelay,
      play = true, easing = InOutCubic, trigger = "perks_roll_anim",
      onFinish = @() sound_play("ui/debriefing/new_equip") }
    { prop = AnimProp.scale, from = [1.6,1.6], to = [1,1], duration = 0.8, delay = animDelay,
      play = true, easing = InOutCubic, trigger = "perks_roll_anim" }
    { prop = AnimProp.rotate, from = angle, to = 0, duration = 0.8,
      delay = animDelay, play = true, easing = InOutCubic, trigger = "perks_roll_anim" }
    { prop = AnimProp.translate, from = [-(xOffset * sh(20)), -sh(20)], to = [0,0], duration = 0.8,
      delay = animDelay, play = true, easing = InOutCubic, trigger = "perks_roll_anim",
      onFinish = idx == total - 1 ? onFinishCb : null }
  ]
}

local function mkRollBigSlot(perkId, idx, total, selectedPerk, hasRoll, isRollAnimation, onClick, onDoubleClick) {
  if (hasRoll)
    sound_play("ui/debriefing/squad_progression_appear")

  return ::watchElemState(@(sf) {
    padding = ::hdpx(1)
    behavior = Behaviors.Button
    onClick = onClick
    onDoubleClick = onDoubleClick
    children = [
      {
        key = $"{perkId}"
        rendObj = ROBJ_BOX
        size = perkBigIconSize
        flow = FLOW_VERTICAL
        borderColor = sf & S_HOVER ? activeBgColor : Color(70, 70, 70)
        fillColor = defBgColor
        children = bigSlot(perkId)
        transform = { pivot = [0.5, 0.5] }
        animations = hasRoll
          ? mkAppearAnimation(idx, total, idx == total - 1 ? @() isRollAnimation(false) : null)
          : null
      }
      @() {
        watch = [isRollAnimation, selectedPerk]
        size = flex()
        children = isRollAnimation.value ? null
          : mkSelectedPerkMark(selectedPerk.value == perkId, hdpx(30))
      }
    ]
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
    }
  })
}

local function uniteEqualPerks(perks) {
  local perksTable = {}
  foreach (perk in perks)
    perksTable[perk] <- (perksTable?[perk] ?? 0) + 1
  local unitedPerks = []
  foreach (perkId, amount in perksTable)
    unitedPerks.append({
      perkId = perkId
      amount = amount
    })

  return unitedPerks
}

local mkPerksList = @(perks) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = perks.map(@(perkData, idx) slot({
    perkData = perkData
    slotNumber = idx
  }))
}

local tierTitle = @(tier) tier?.locId
  ? {
      rendObj = ROBJ_TEXTAREA
      margin = smallPadding
      behavior = Behaviors.TextArea
      font = Fonts.small_text
      color = titleTxtColor
      text = ::loc(tier.locId)
    }
  : null

local perkPointsInfoTooltip = {
  size = [hdpx(400), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    mkText(::loc("perkPointsTitle")).__update({ color = msgHighlightedTxtColor })
    flexTextArea({ text = ::loc("perkPointsDesc") })
  ]
}

local mkPerksPointsBlock = @(perkPointsInfoWatch) function() {
  local res = { watch = perkPointsInfoWatch }
  local perkPointsInfo = perkPointsInfoWatch.value
  if (perkPointsInfo == null)
    return res

  local children = []
  foreach (pPointId in perksPoints.pPointsList) {
    local pointsAmount = perkPointsInfo.total?[pPointId] ?? 0
    if (pointsAmount <= 0)
      continue
    local pPointCfg = perksPoints.pPointsBaseParams?[pPointId]
    if (pPointCfg == null)
      continue

    local usedValue = perkPointsInfo.used?[pPointId] ?? 0
    children.append(usedPerkPoints(pPointCfg, usedValue, pointsAmount))
  }

  return res.__update({
    behavior = Behaviors.Button
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    onHover = @(on) tooltip.state(on ? tooltipBox(perkPointsInfoTooltip) : null)
    skipDirPadNav = true
    children = children
  })
}

return {
  mkRollBigSlot = ::kwarg(mkRollBigSlot)
  slot // TODO rename methods to more specific
  slotBg
  mkPerksList
  tierTitle
  uniteEqualPerks
  perkPointIcon
  perkPointCostText
  usedPerkPoints
  perkUi
  mkPerksPointsBlock
}
 