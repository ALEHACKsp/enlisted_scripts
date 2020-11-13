local cursors = require("ui/style/cursors.nut")
local style = require("enlisted/enlist/viewConst.nut")
local { Flat, PrimaryFlat, Purchase, primaryButtonStyle } = require("enlist/components/textButton.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")
local { secondsToTimeSimpleString } = require("utils/time.nut")
local scrollbar = require("daRg/components/scrollbar.nut")
local { sound_play } = require("sound")
local { utf8ToUpper } = require("std/string.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { armiesUnlocks } = require("enlisted/enlist/campaigns/armiesConfig.nut")
local armyPackage = require("enlisted/enlist/soldiers/components/armyPackage.nut")
local mkAward = require("components/mkAward.nut")
local mkArmyProgress = require("components/mkArmyProgress.nut")
local mkSquadProgress = require("components/mkSquadProgress.nut")
local mkAnimatedItemsBlock = require("enlisted/enlist/soldiers/mkAnimatedItemsBlock.nut")
local {
  allItemTemplates, findItemTemplate
} = require("enlisted/enlist/soldiers/model/all_items_templates.nut")
local mkSoldierCard = require("mkDebriefingSoldierCard.nut")
local mkScoresStatistics = require("enlisted/ui/hud/components/mkScoresStatistics.nut")
local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local { playerSelectedArmy } = require("enlisted/enlist/soldiers/model/state.nut")
local { setCurCampaign } = require("enlisted/enlist/meta/curCampaign.nut")
local squadsPresentation = require("enlisted/globals/squadsPresentation.nut")
local { premiumImage } = require("enlisted/enlist/currency/premiumComp.nut")
local {
  mkCurrencyButton, mkLogisticsPromoMsgbox
} = require("enlisted/enlist/shop/currencyComp.nut")
local {
  hasShopOrdersUsed, curArmyCurrency
} = require("enlisted/enlist/shop/armyShopState.nut")
local { round_by_value } = require("std/math.nut")
local { logerr } = require("dagor.debug")


const ANIM_TRIGGER = "new_items_wnd_anim"
const NEW_BLOCK_TRIGGER = "new_debr_block_appear"
const OVERLAY_TRIGGER = "content_anim"
const OVERLAY_TRIGGER_SKIP = "content_anim_skip"
const SKIP_ANIM_POSTFIX = "_skip"
const FILL_BLOCK_DELAY = 0.3
const AWARD_DELAY = 0.2

const MISSION_NAME_TEXT_DELAY = 1.6
const SESSION_TIME_TEXT_DELAY = 1.8
const SESSION_TIME_VALUE_DELAY = 2.0
const HEADER_TEXT_DELAY = 1.0
const HEADER_ICON_DELAY = 1.3

const DELAY = 0.1 //default delayAfter for mkAnim

local BODY_W = sh(125)
local BODY_H = sh(60)
local WINDOW_CONTENT_SIZE = [BODY_W, BODY_H - safeAreaBorders.value[0] - safeAreaBorders.value[2]]

local bigPadding = style.bigPadding
local debriefingWidth = sw(80)
local leftBlockWidth = debriefingWidth * 0.55
local maxAwardsRows = 3
local awardsInRow = (leftBlockWidth / (style.awardIconSize + style.awardIconSpacing)).tointeger()

local hasAnim = true
local skippedAnims = {}
local isWaitAnim = Watched(false)

local windowBlocks = Watched([])
local windowContentQueue = null
local scrollHandler = ::ScrollHandler()
local gainRewardContent = Watched(null)

local soldierStatsCfg = [
  { stat = "time", locId = "debriefing/battleTime", toString = secondsToTimeSimpleString },
  { stat = "spawns", locId = "debriefing/awards/spawns" },
  { stat = "kills", locId = "debriefing/awards/kill" },
  { stat = "tankKills", locId = "debriefing/awards/tankKill" },
  { stat = "planeKills", locId = "debriefing/awards/planeKill" },
  { stat = "assists", locId = "debriefing/awards/assists" },
  { stat = "crewKillAssists", locId = "debriefing/awards/crewKillAssists" },
  { stat = "crewTankKillAssists", locId = "debriefing/awards/crewTankKillAssists" },
  { stat = "crewPlaneKillAssists", locId = "debriefing/awards/crewPlaneKillAssists" },
  { stat = "captures", locId = "debriefing/awards/capture", toString = @(v) round_by_value(v, 0.5) },
  { stat = "score", locId = "debriefing/score" },
  { stat = "classBonus", locId = "debriefing/classBonusExp", toString = @(v) v > 0 ? $"+{100 * v}%" : "0%"},
  { stat = "exp", locId = "debriefing/expAdded" },
].map(@(s) { toString = @(v) v.tostring() }.__update(s))


windowBlocks.subscribe(@(v) ::anim_start(NEW_BLOCK_TRIGGER))
local scrollToBlock = @(key) scrollHandler.scrollToChildren(@(desc) desc?.key == key, 3, false, true)

local mkAppearAnimations = @(delay, onVisibleCb = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true,
    easing = InOutCubic, trigger = $"{ANIM_TRIGGER}{SKIP_ANIM_POSTFIX}" }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4, play = true,
    easing = InOutCubic, delay = delay, trigger = ANIM_TRIGGER, onFinish = onVisibleCb }
  { prop = AnimProp.scale, from = [2,2], to = [1,1], duration = 0.8, play = true,
    easing = InOutCubic, delay = delay, trigger = ANIM_TRIGGER}
  { prop = AnimProp.translate, from = [0, -sh(30)], to = [0,0], duration = 0.8, play = true,
    easing = OutQuart, delay = delay, trigger = ANIM_TRIGGER}
]

local blockAnimations = mkAppearAnimations(0).append(
  { prop = AnimProp.translate, from = [0, sh(30)], to = [0,0], duration = 0.3, easing = OutQuart,
    trigger = NEW_BLOCK_TRIGGER })

local mkAnim = @(children, onVisibleCb = null, animDelay = DELAY) {
  size = SIZE_TO_CONTENT
  transform = {}
  animations = mkAppearAnimations(animDelay, onVisibleCb)
  children = children
}

local grayText = @(override) {
  rendObj = ROBJ_DTEXT
  color = Color(184, 182, 181)
  font = Fonts.medium_text
}.__merge(override)

local headerMarginTop = hdpx(30)

local function overGainRewardBlock() {
  local res = { watch = gainRewardContent }
  local content = gainRewardContent.value
  if (content == null)
    return res
  return res.__update({
    size = flex()
    children = {
      key = $"{content.key}_nest"
      rendObj = ROBJ_SOLID
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      color = style.debriefingDarkColor
      behavior = Behaviors.Button
      children = content
      opacity = 0
      transform = {}
      animations = [
        { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.2, play = true,
          trigger = OVERLAY_TRIGGER }
        { prop = AnimProp.opacity, from = 1, to = 1, duration = 1.6, play = true, delay = 0.2,
          trigger = OVERLAY_TRIGGER }
        { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, play = true, delay = 1.8,
          trigger = OVERLAY_TRIGGER_SKIP, onFinish = @() gainRewardContent(null) }
      ]
    }
  })
}

local missionTitle = @(debriefing) debriefing?.missionName == null ? null : mkAnim({
  rendObj = ROBJ_DTEXT
  text = debriefing.missionName
  font = Fonts.huge_text
  fontFxColor = Color(0, 0, 0, 180)
  fontFxFactor = min(64, hdpx(64))
  fontFx = FFT_GLOW
}, null, MISSION_NAME_TEXT_DELAY)

local sessionTimeCounter = @(debriefing) {
  margin = [headerMarginTop, 0, 0, 0]
  flow = FLOW_VERTICAL
  hplace = ALIGN_LEFT
  halign = ALIGN_LEFT
  children = [
    missionTitle(debriefing)
    mkAnim(grayText({
      text = utf8ToUpper(::loc("debriefing/session_time"))
    }), null, SESSION_TIME_TEXT_DELAY)
    mkAnim(grayText({
      font = Fonts.big_text
      text = secondsToTimeSimpleString((debriefing?.result.time ?? 0).tointeger())
    }), null, SESSION_TIME_VALUE_DELAY)
  ]
}

local bonusText = @(val) "+{0}%".subst((100 * val).tointeger())
local colon = ::loc("ui/colon")

local function mkSquadsBonusTooltipText(premiumExpMul) {
  local premiumText = "".concat(::loc("premium/title"), colon, "+", premiumExpMul*100, "%")
  return "\n\n".join([premiumText], true)
}

local function battleExpBonus(debriefing) {
  local totalBonus = debriefing?.premiumExpMul ?? null
  if (totalBonus == null)
    return null

  return {
    margin = [headerMarginTop, 0, 0, 0]
    flow = FLOW_VERTICAL
    hplace = ALIGN_RIGHT
    halign = ALIGN_RIGHT

    behavior = Behaviors.Button
    onHover = @(on) cursors.tooltip.state(
      on ? mkSquadsBonusTooltipText(totalBonus - 1) : null)
    children = [
      mkAnim(grayText({ text = utf8ToUpper(::loc("battle_exp_bonus")) }))
      mkAnim(
        {
          flow = FLOW_HORIZONTAL
          children = [
            grayText({ font = Fonts.big_text, text = bonusText(totalBonus - 1) })
            premiumImage(hdpx(35))
          ]
        }
      )
    ]
  }
}

local blockHeader = @(locId) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_SOLID
  color = Color(0, 0, 0, 60)
  halign = ALIGN_CENTER
  padding = hdpx(5)
  children = grayText({ font = Fonts.small_text, text = utf8ToUpper(::loc(locId)) })
}

local continueAnim = @(debriefing) function() {
  local blockIdx = -1
  local block = null
  foreach(idx, ctor in windowContentQueue) {
    block = ctor(debriefing)
    if (block != null) {
      blockIdx = idx
      break
    }
  }

  if (blockIdx < 0) {
    isWaitAnim(false)
    return
  }

  windowContentQueue = windowContentQueue.slice(blockIdx + 1)
  windowBlocks(@(v) v.append(block))
}

local function skipAnim(debriefing) {
  ::anim_skip("".concat(ANIM_TRIGGER, SKIP_ANIM_POSTFIX))
  ::anim_skip(ANIM_TRIGGER)
  ::anim_skip(OVERLAY_TRIGGER)
  ::anim_skip_delay(OVERLAY_TRIGGER_SKIP)
  skippedAnims = skippedAnims.map(@(v) true)

  local prevContent = gainRewardContent.value
  if (prevContent != null)
    gui_scene.setTimeout(0.5, function() { //only to handle bugs when reward window not delete after skip
      if (prevContent != gainRewardContent.value)
        return
      gainRewardContent(null)
      logerr($"Debriefing reward window not removed after skip: key = {prevContent?.key}")
      log("Not removed content: ", prevContent)
    })

  continueAnim(debriefing)()
}

local blockIdx = 0
local function blockCtr(locId, blockContent, debriefing, override = null) {
  if (!blockContent)
    return null

  local key = $"debr_block_{blockIdx++}"
  return {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_SOLID
    color = locId ? Color(32, 32, 32, 200) : Color(0, 0, 0, 0)
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      locId ? blockHeader(locId) : null
      {
        padding = locId ? [hdpx(10), 0, hdpx(10), 0] : 0
        children = blockContent
      }
    ]

    key = key
    function onAttach() {
      scrollToBlock(key)
    }

    transform = {}
    animations = blockAnimations
  }.__update(override ?? {})
}

local function hasNewArmyLevel(debriefing) {
  local levelGrid = debriefing?.armyProgress.expToArmyLevel
  if (levelGrid == null)
    return false

  local armyWasLevel = debriefing.armyWasLevel
  local expToNextLevel = levelGrid?[armyWasLevel] ?? levelGrid.top()
  return debriefing.armyWasExp + debriefing.armyExp >= expToNextLevel
}

local function calcUnlockRewards(armyId, armyLevel, armyWasExp, armyExpNew) {
  local levelUnlocks = armiesUnlocks.value
    .filter(@(u) u?.armyId == armyId
      && u?.level == armyLevel
      && u?.unlockType == "item"
      && (u?.isMultiple ? u.multipleUnlock.expEnd : u.exp) > armyWasExp)

  local unlockRewards = []
  foreach (unlock in levelUnlocks) {
    if (unlock?.isMultiple) {
      // periods is not correct naming, should be count (may be need to FIX it)
      local periods = unlock.multipleUnlock.periods
      local expBegin = unlock.multipleUnlock.expBegin
      local expEnd = unlock.multipleUnlock.expEnd
      local expStep = (expEnd - expBegin).tofloat() / (periods - 1)
      local gained = armyWasExp >= expBegin
        ? ((armyWasExp - expBegin) / expStep).tointeger() + 1 : 0

      local experiences = []
      for (local i = gained; i < periods; i++) {
        local curExp = expBegin + (expEnd - expBegin) * i / (periods - 1)
        experiences.append(curExp)
        if (curExp > armyExpNew)
          break
      }

      unlockRewards.extend(experiences
        .map(@(exp) {
          isNext = exp > armyExpNew
          exp = exp
          unlockId = unlock.unlockId
          unlockCount = 1
        }))
    }
    else
      unlockRewards.append({
        isNext = unlock.exp > armyExpNew
        exp = unlock.exp
        unlockId = unlock.unlockId
        unlockCount = unlock.unlockCount
      })
  }

  unlockRewards.sort(@(a, b) a.exp <=> b.exp)
  local nextRewardIdx = unlockRewards.findindex(@(v) v.isNext)
  return nextRewardIdx != null
    ? unlockRewards.slice(0, nextRewardIdx + 1)
    : unlockRewards
}

local function armyProgressBlock(debriefing) {
  local armyAddExp = debriefing?.armyExp ?? 0
  if (armyAddExp <= 0)
    return continueAnim(debriefing)()

  local armyId = debriefing.armyId
  local armyLevel = debriefing?.armyWasLevel ?? 1
  local armyExp = debriefing?.armyWasExp ?? 0
  local armyExpNew = armyExp + armyAddExp

  skippedAnims.army <- false
  return {
    size = [WINDOW_CONTENT_SIZE[0] * 0.8, SIZE_TO_CONTENT]
    padding = bigPadding
    children = mkArmyProgress({
      armyId
      armyWasLevel = armyLevel
      armyWasExp = armyExp
      armyAddExp = armyAddExp
      progressCfg = debriefing?.armyProgress
      unlockRewards = calcUnlockRewards(armyId, armyLevel, armyExp, armyExpNew)
      hasNewLevel = hasNewArmyLevel(debriefing)
      onFinish = function() {
        if (!skippedAnims.army)
          continueAnim(debriefing)()
      }
      gainRewardContent
    })
    transform = {}
    animations = mkAppearAnimations(FILL_BLOCK_DELAY)
  }
}

local function debriefingHeader(debriefing) {
  local result = debriefing?.result
  local armyIcon = armyPackage.mkIcon(debriefing.armyId, ::hdpx(44))
  local armyProgress = armyProgressBlock(debriefing)
  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    margin = [headerMarginTop, 0, 0, 0]
    flow = FLOW_VERTICAL
    children = [
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(30)
        children = [
          mkAnim(armyIcon, null, HEADER_ICON_DELAY)
          mkAnim({
              size = SIZE_TO_CONTENT
              rendObj = ROBJ_DTEXT
              font = Fonts.giant_numbers
              text = utf8ToUpper(result?.title ?? "")
            },
            @() sound_play("ui/debriefing/{0}".subst(result?.success ? "text_victory" : "text_defeat")),
            HEADER_TEXT_DELAY)
          mkAnim(armyIcon, null, HEADER_ICON_DELAY)
        ]
      }
      blockCtr("debriefing/squad_unlocking", armyProgress, debriefing, {
        size = [WINDOW_CONTENT_SIZE[0], SIZE_TO_CONTENT]
        margin = [bigPadding]
        onAttach = @() null
        animations = []
      })
    ]
  }
}

local function switchContext(debriefing) {
  local campaign = gameProfile.value?.campaignByArmyId[debriefing.armyId]
  if (campaign == null)
    return
  setCurCampaign(campaign)
  playerSelectedArmy(debriefing.armyId)
}

local function skipAnimOrClose(doClose, debriefing) {
  if (isWaitAnim.value) {
    skipAnim(debriefing)
    return
  }
  doClose()
  switchContext(debriefing)
  if (hasNewArmyLevel(debriefing))
    setCurSection("SQUADS")
}

local mkCloseBtn = @(doClose, debriefing) closeBtnBase({
  onClick = @() skipAnimOrClose(doClose, debriefing)
  hotkeys = null
}).__update({ margin = bigPadding })

local btnCloseStyle = { margin = 0, size = [hdpx(450), hdpx(60)] }
local mkSkipOrCloseBtn = @(doClose, debriefing) function() {
  local doStopAndClose = @() skipAnimOrClose(doClose, debriefing)
  local doCloseAndShopping = function() {
    if (isWaitAnim.value)
      skipAnim(debriefing)
    doClose()
    switchContext(debriefing)
    setCurSection("SHOP")
  }
  local { armyId, armyWasLevel = 1, armyWasExp = 0, armyExp = 0 } = debriefing
  armyExp += armyWasExp

  local hasNewLevel = hasNewArmyLevel(debriefing)
  local hasOrdersUsed = hasShopOrdersUsed.value
  local armyExpNew = armyWasExp + armyExp
  local unlockRewards = calcUnlockRewards(armyId, armyWasLevel, armyWasExp, armyExpNew)
  local firstReward = unlockRewards?[0]
  local firstSupply = (firstReward?.isNext ?? false) ? null
    : firstReward?.unlockId

  local btnClose
  if (isWaitAnim.value)
    btnClose = Flat(::loc("Skip"), doStopAndClose, btnCloseStyle.__merge({
      size = [SIZE_TO_CONTENT, ::hdpx(60)]
      hotkeys = [["^J:B | Esc", {description = ::loc("Skip")}]]
    }))
  else if (hasNewLevel)
    btnClose = Purchase(::loc("newArmyLevel"), doStopAndClose, btnCloseStyle.__merge({
      hotkeys = [["^J:Y | Space | Enter", {description = ::loc("newArmyLevel")}]]
    }))
  else if (firstSupply == null || hasOrdersUsed)
    btnClose = PrimaryFlat(::loc("Ok"), doStopAndClose, btnCloseStyle.__merge({
      hotkeys = [["^J:Y | Space | Enter", {description = ::loc("Ok")}]]
    }))

  local btnShopping = firstSupply == null || isWaitAnim.value || hasNewLevel
    ? null
    : mkCurrencyButton({
        text = ::loc("GoToShop")
        currency = firstSupply
        cb = function() {
          doCloseAndShopping()
          if (!hasOrdersUsed)
            mkLogisticsPromoMsgbox(curArmyCurrency.value)
        }
        style = primaryButtonStyle.__merge(btnCloseStyle.__merge({
          hotkeys = [["^J:X", {description = ::loc("GoToShop")}]]
        }))
      })

  return {
    watch = isWaitAnim
    size = [WINDOW_CONTENT_SIZE[0], SIZE_TO_CONTENT]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign = isWaitAnim.value ? ALIGN_RIGHT : ALIGN_CENTER
    gap = ::hdpx(20)
    flow = FLOW_HORIZONTAL
    margin = [0, 0, hdpx(20), 0]
    children = [
      btnClose
      btnShopping
    ]
    animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 2.0, play = true, easing = InOutCubic }]
  }
}


local mkAwardsContent = @(awards, nextAnimCb)
  wrap(awards.map(@(award, idx) {
    children = mkAward.make({
      size = [style.awardIconSize, style.awardIconSize]
      award = award
      hasAnim = hasAnim
      pauseTooltip = isWaitAnim
      countDelay = idx * AWARD_DELAY
    })
    transform = {}
    animations = mkAppearAnimations(idx * AWARD_DELAY, function() {
      sound_play("ui/debriefing/battle_result")
      if (idx == awards.len() - 1)
        ::gui_scene.setTimeout(0.4, nextAnimCb)
    })
  }),
  { width = WINDOW_CONTENT_SIZE[0] * 0.75
    hGap = bigPadding * 2
    vGap = bigPadding * 2
    halign = ALIGN_CENTER
  })


local function getSupplyAnimBlock(debriefing, condition = @(val) true) {
  local rewardItems = debriefing?.rewardItems ?? {}
  local itemsToShow = []

  foreach (itemInfo in rewardItems) {
    local itemBase = itemInfo?.basetpl
    local army = debriefing.armyId
    local item = findItemTemplate(allItemTemplates, army, itemBase).__merge(itemInfo)

    if (item == null) {
      log("Item", itemBase, "is not in templates of army", army, "!")
      continue
    }

    if (!condition(item?.itemtype))
      continue

    itemsToShow.append(item)
  }

  if (!itemsToShow.len())
    return null

  local ret = mkAnimatedItemsBlock({ weapons = itemsToShow }, {
    width = WINDOW_CONTENT_SIZE[0] * 0.9
    hasAnim = hasAnim
    pauseTooltip = isWaitAnim
    baseAnimDelay = FILL_BLOCK_DELAY
    animTrigger = ANIM_TRIGGER
    hasItemTypeTitle = false
    onVisibleCb = function() {
      sound_play("ui/debriefing/new_equip")
    }
  })

  return ret
}

local function awardsBlock(debriefing) {
  local rewards = debriefing?.awards ?? []
  if (rewards.len() == 0)
    return null

  skippedAnims.awards <- false
  local content = mkAwardsContent(rewards
      .filter(@(val) mkAward.awardsCfg?[val.id])
      .slice(0, maxAwardsRows * awardsInRow),
    function() {
      if (!skippedAnims.awards)
        continueAnim(debriefing)()
    })

  return blockCtr("debriefing/personal_results", content, debriefing)
}

local function weaponSupplyBlock(debriefing) {
  local block = getSupplyAnimBlock(debriefing, @(val) val != "vehicle" && val != "soldier")
  if (block == null)
    return null

  return blockCtr("debriefing/weaponSupply", block.component, debriefing)
}

local function soldiersSupplyBlock(debriefing) {
  local block = getSupplyAnimBlock(debriefing, @(val) val == "soldier" || val == "vehicle")
  if (block == null)
    return null

  return blockCtr("debriefing/replenishment", block.component, debriefing)
}

local function squadsExpBlock(debriefing) {
  local squads = debriefing?.squads ?? {}
  if (squads.len() == 0)
    return null

  skippedAnims.squads <- false
  local animDelay = 0
  local idx = 0
  local children = []
  foreach (squad in squads) {
    local squadCard = mkSquadProgress({
      squad = squad
      animDelay = animDelay
      mkAppearAnimations = mkAppearAnimations
      onFinishCb = idx == squads.len() - 1
        ? function() {
            if (!skippedAnims.squads)
              continueAnim(debriefing)()
          }
        : null
    })
    children.append(squadCard.content)
    animDelay += squadCard.duration
    idx++
  }

  local content = {
    size  = [WINDOW_CONTENT_SIZE[0], SIZE_TO_CONTENT]
    children = wrap(children,
      { width = WINDOW_CONTENT_SIZE[0]
        hGap = bigPadding * 2
        vGap = bigPadding * 2
        halign = ALIGN_CENTER
      })
  }

  return blockCtr("debriefing/squads_progression", content, debriefing)
}

local function mkSoldierTooltipText(stats) {
  local textList = soldierStatsCfg.map(@(s)
    "".concat(::loc(s.locId), colon, s.toString(stats?[s.stat] ?? 0)))
  return "\n".join(textList)
}

local function soldiersBlock(debriefing) {
  local soldierStatSorted = (debriefing?.soldiers.stats ?? {})
    .map(@(s, id) s.__merge({ soldierId = id }))
    .values()
    .sort(@(a, b) (b?.exp ?? 0) <=> (a?.exp ?? 0) || (b?.kills ?? 0) <=> (a?.kills ?? 0))

  skippedAnims.soldiers <- false
  local animDelay = 0
  local children = []
  foreach (idx, soldierStat in soldierStatSorted) {
    local soldierData = debriefing?.soldiers?.items[soldierStat.soldierId]
    if (!soldierData)
      continue

    local soldierCard = mkSoldierCard({
      stat = soldierStat
      info = soldierData
      animDelay = animDelay
      mkAppearAnimations = mkAppearAnimations
      nextAnimCb = idx == soldierStatSorted.len() - 1
        ? function() {
            if (!skippedAnims.soldiers)
              continueAnim(debriefing)()
          }
        : null
    })
    if (!soldierCard)
      continue

    local stats = soldierStat
    children.append(soldierCard.content
      .__update({
        behavior = Behaviors.Button
        onHover = @(on) cursors.tooltip.state(on ? mkSoldierTooltipText(stats) : null)
      }))
    animDelay += soldierCard.delay
  }

  if (children.len() == 0)
    return null

  local ret = {
    onAttach = @() ::gui_scene.setTimeout(0.1, function() {
      sound_play("ui/debriefing/squad_progression_appear")
    })
    children = wrap(children,
    { width = WINDOW_CONTENT_SIZE[0] * 0.95
      hGap = bigPadding * 2
      vGap = bigPadding * 2
      halign = ALIGN_CENTER
    })
  }

  return blockCtr("debriefing/soldiers_progression", ret, debriefing)
}

local function statisticBlock(debriefing) {
  if (debriefing.players.len() == 0)
    return null

  skippedAnims.statistic <- false
  ::gui_scene.setTimeout(0.5, function() {
    if (!skippedAnims.statistic)
      continueAnim(debriefing)()
  })
  return blockCtr(null, mkScoresStatistics(debriefing.players, {
    localPlayerEid = debriefing.localPlayerEid
    myTeam = debriefing.myTeam
    teams = debriefing.teams
    width = WINDOW_CONTENT_SIZE[0]
  }), debriefing)
}

local windowContent = @(debriefing) mkAnim({
  pos = [0, hdpx(100)]
  size = WINDOW_CONTENT_SIZE
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER

  children = scrollbar.makeVertScroll(@() {
    watch = windowBlocks
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = ph(100)
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = hdpx(18)
    children = windowBlocks.value
  },
  {
    scrollHandler = scrollHandler
    size = flex()
    needReservePlace = false
  })
}).__merge({ size = flex() })

local mkSessionIdText = @(debriefing) (debriefing?.sessionId ?? "0") == "0" ? null : {
  text = debriefing.sessionId
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_LEFT
  rendObj = ROBJ_DTEXT
  color = Color(120,120,120, 50)
  font = Fonts.tiny_text
}

local function debriefingRoot(debriefing, doClose) {
  local armyId = debriefing?.armyId
  local squads = debriefing?.squads ?? []
  foreach (squadId, squad in squads)
    squad.__update(squadsPresentation?[armyId][squadId] ?? {})

  gainRewardContent(null)
  skippedAnims = {}
  hasAnim = true
  WINDOW_CONTENT_SIZE = [BODY_W, BODY_H - safeAreaBorders.value[0] - safeAreaBorders.value[2]]

  windowBlocks.value.clear()
  windowContentQueue = [
    awardsBlock
    weaponSupplyBlock
    soldiersSupplyBlock
    squadsExpBlock
    soldiersBlock
    statisticBlock
  ]
  return @() {
    key = debriefing
    size = [sw(100), sh(100)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    cursor = cursors.normal
    stopMouse = true
    hooks = HOOK_ATTACH
    actionSet = "StopInput"
    watch = safeAreaBorders
    stopHotkeys = true
    children = [
      {
        size = flex()
        padding = safeAreaBorders.value
        children = [
          debriefingHeader(debriefing)
          sessionTimeCounter(debriefing)
          battleExpBonus(debriefing)
          mkCloseBtn(doClose, debriefing)
          windowContent(debriefing)
          mkSkipOrCloseBtn(doClose, debriefing)
          mkSessionIdText(debriefing)
        ]
      }
      overGainRewardBlock
    ]

    onAttach = function() {
      isWaitAnim(true)
    }

    transform = {pivot = [0.5, 0.25]}
    animations = [
      { prop=AnimProp.opacity, from=0, to=1 duration=0.8, play=true, easing=InOutCubic}
      { prop=AnimProp.scale, from=[2,2], to=[1,1], duration=0.5, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0 duration=0.8, playFadeOut=true, easing=InOutCubic}
      { prop=AnimProp.scale, from=[1,1], to=[2,2], duration=0.5, playFadeOut=true, easing=InOutCubic}
    ]

    sound = {
      attach = "ui/menu_highlight"
      detach = "ui/menu_highlight"
    }
  }
}

return debriefingRoot
 