local fa = require("daRg/components/fontawesome.map.nut")
local progressBar = require("enlist/components/progressBar.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local { mkSquadIcon } = require("enlisted/enlist/soldiers/components/squadsUiComps.nut")
local { hasPremium } = require("enlisted/enlist/currency/premium.nut")
local textButton = require("enlist/components/textButton.nut")
local premiumWnd = require("enlisted/enlist/currency/premiumWnd.nut")
local squadsPresentation = require("enlisted/globals/squadsPresentation.nut")
local { sendBigQueryUIEvent } = require("enlist/bigQueryEvents.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { withTooltip } = require("ui/style/cursors.nut")
local { mkCurrencyImage, mkCurrencyTooltip } = require("enlisted/enlist/shop/currencyComp.nut")
local { sound_play } = require("sound")

local {
  bigPadding, activeTxtColor, progressBorderColor, progressExpColor,
  progressAddExpColor, defBgColor, activeBgColor
} = require("enlisted/enlist/viewConst.nut")

const trigger = "content_anim"

local PROGRESS_ANIM_DELAY = 2.0
local AWARD_ANIM_DELAY = 0.3

local lvlWidth = sw(20)
local lineHeight = hdpx(30)
local slotHeight = hdpx(70)
local ticketHeight = ::hdpx(40)

local mkLevelTextBlock = @(lvl, lvlAlign, mkText = @(baseText) baseText) {
  size = [lvlWidth, flex()]
  halign = lvlAlign
  hplace = lvlAlign
  children = [
    mkText(txt({
      text = ::loc("levelInfo", { level = lvl })
      color = activeTxtColor
      padding = [0, ::hdpx(10)]
    }))
    {
      rendObj = ROBJ_SOLID
      size = [hdpx(1), flex()]
      color = progressBorderColor
    }
  ]
}

local mkLevelsGrid = @(lvl, armyAddExp) {
  size = [flex(), lineHeight + bigPadding]
  children = [
    mkLevelTextBlock(lvl, ALIGN_LEFT,
      @(baseText) {
        flow = FLOW_HORIZONTAL
        children = [
          baseText
          txt(armyAddExp <= 0 ? ""
            : " ({0}{1}{2})".subst(::loc("debriefing/expAdded"), ::loc("ui/colon"), armyAddExp))
        ]
      })
    mkLevelTextBlock(lvl + 1, ALIGN_RIGHT)
  ]
}

local mkLevelRewardAnim = @(animDelay, onFinish = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay, play = true,
    easing = InOutCubic, trigger }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4, play = true,
    easing = InOutCubic, delay = animDelay, trigger }
  { prop = AnimProp.scale, from = [4,4], to = [1,1], duration = 0.8, play = true,
    easing = InOutCubic, delay = animDelay, trigger }
  { prop = AnimProp.translate, from = [0, sh(30)], to = [0,0], duration = 0.8, play = true,
    easing = OutQuart, delay = animDelay, trigger, onFinish }
]

local rewardStyle = {
  rendObj = ROBJ_BOX
  size = [sh(40), sh(30)]
  flow = FLOW_VERTICAL
  padding = sh(4)
  fillColor = defBgColor
  borderColor = activeBgColor
  transform = {}
  animations = mkLevelRewardAnim(0)
}

local mkSquadReward = @(squadCfg, level) {
  key = "squads"
  children = [
    {
      rendObj = ROBJ_DTEXT
      text = ::loc("levelReward/title", { level = level })
      font = Fonts.medium_text
      color = activeTxtColor
      hplace = ALIGN_CENTER
    }
    {
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        mkSquadIcon(squadCfg?.icon, { size = [slotHeight, slotHeight] })
          .__update({ margin = [0,0,sh(1),0] })
        txt(::loc(squadCfg?.nameLocId ?? ""))
        txt({
          text = ::loc(squadCfg?.titleLocId ?? "")
          color = Color(200, 150, 100)
        })
      ]
    }
  ]
}.__update(rewardStyle)

local function mkSquadUnlock(gainLevel, squadCfg, armyId, animDelay, onFinish, gainRewardContent) {
  squadCfg = squadCfg.__merge(squadsPresentation?[armyId]?[squadCfg?.squadId] ?? {})
  return withTooltip({
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    valign = ALIGN_CENTER
    children = [
      mkSquadIcon(squadCfg?.icon, { size = [slotHeight, slotHeight] })
      {
        flow = FLOW_VERTICAL
        children = [
          txt(::loc(squadCfg?.nameLocId ?? ""))
          txt(::loc(squadCfg?.titleLocId ?? ""))
            .__update({ color = Color(200, 150, 100) })
        ]
      }
    ]
    transform = {}
    animations = gainLevel != null
      ? [
          {
            prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay, play = true,
            trigger, onFinish = function() {
              gainRewardContent(mkSquadReward(squadCfg, gainLevel))
              sound_play("ui/debriefing/squad_progression_appear")
            }
          }
        ].extend(mkLevelRewardAnim(animDelay + 2, function() {
          onFinish?()
          sound_play("ui/debriefing/battle_result")
        }))
      : [
          {
            prop = AnimProp.opacity, from = 1, to = 1, duration = animDelay, play = true,
            trigger, onFinish
          }
        ]
  }, ::loc("squads/squadUnlocked"))
}

local mkAwardGauge = @(maxValue, unlockRewards) {
  size = flex()
  children = unlockRewards.map(@(u) {
    size = [0, lineHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    pos = [pw(maxValue > 0 ? ::min(100.00 * (u.exp.tofloat() / maxValue.tofloat()), 100) : 0), 0]
    children = u?.isNext == true
      ? {
        rendObj = ROBJ_SOLID
        size = [::hdpx(1), flex()]
        color = progressBorderColor
      }
      : {
        rendObj = ROBJ_STEXT
        font = Fonts.fontawesome
        fontSize = ::hdpx(10)
        text = fa["caret-up"]
        validateStaticText = false
        pos = [0, ::hdpx(3)]
      }
  })
}

local mkProgress = ::kwarg(
  @(expToNextLevel, armyWasExp, armyAddExp, gainLevel, unlockRewards, hasNewLevel, onFinish) {
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      progressBar({
        maxValue = expToNextLevel
        curValue = armyWasExp
        addValue = armyAddExp
        needText = true
        completeText = gainLevel != null
          ? ::loc("newLevelReached", { lvl = gainLevel }) : null
        hasBlink = gainLevel != null
        height = lineHeight
        addValueAnimations = [
          { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 1.0, play = true, trigger }
          { prop = AnimProp.scale, from = [0, 1], to = [1, 1], duration = 0.8,
            play = true, easing = OutCubic, delay = 1.0, trigger, onFinish = function() {
              if (hasNewLevel)
                sound_play("ui/reward_receive")
              onFinish?()
            }}
        ]
        progressColor = progressExpColor
        addColor = progressAddExpColor
        addGauge = mkAwardGauge(expToNextLevel, unlockRewards)
      })
      {
        rendObj = ROBJ_BOX
        size = flex()
        borderColor = progressBorderColor
      }
    ]
  })

local mkBaseAwardAnim = @(animDelay, onFinish) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay, play = true,
    easing = InOutCubic, trigger }
  { prop = AnimProp.opacity, from = 0, to = 0.5, duration = 0.3, play = true,
    easing = InOutCubic, trigger, delay = animDelay, onFinish}
]

local mkGainAwardAnim = @(animDelay) [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true,
    easing = InOutCubic, delay = animDelay, trigger}
  { prop = AnimProp.scale, from = [4,4], to = [1,1], duration = 0.5, play = true,
    easing = InOutCubic, delay = animDelay, trigger }
  { prop = AnimProp.translate, from = [0, sh(30)], to = [0,0], duration = 0.5, play = true,
    easing = OutQuart, delay = animDelay, trigger }
  { prop = AnimProp.scale, from = [1,1], to = [1.4,1.4], duration = 0.3, play = true,
    easing = InOutCubic, delay = animDelay + 0.5, trigger }
  { prop = AnimProp.scale, from = [1.4,1.4], to = [1,1], duration = 0.3, play = true,
    easing = InOutCubic, delay = animDelay + 0.8, trigger }
]

local function mkAward(award, idx, maxValue, timeForRewards, onFinish) {
  local hasGained = !(award?.isNext ?? false)
  local xPos = maxValue > 0
    ? pw(::min(100.00 * award.exp.tofloat() / maxValue.tofloat(), 100)) : 0

  local animDelay = AWARD_ANIM_DELAY * idx + PROGRESS_ANIM_DELAY + timeForRewards
  return {
    size = [0, SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    pos = [xPos, 0]
    opacity = hasGained ? 1.0 : 0.5
    children = withTooltip(mkCurrencyImage(award.unlockId, ticketHeight),
      mkCurrencyTooltip(award.unlockId))
    transform = {}
    animations = mkBaseAwardAnim(animDelay, onFinish)
      .extend(hasGained ? mkGainAwardAnim(animDelay) : [])
  }
}

local mkAwards = @(unlockRewards, maxValue, timeForRewards, onFinish) {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [bigPadding, 0, 0, 0]
  children = unlockRewards.map(@(award, idx)
    mkAward(award, idx, maxValue, timeForRewards, idx == unlockRewards.len() - 1
      ? onFinish
      : null))
}

local mkGainAwards = @(unlockedRewards) {
  key = "awards"
  children = [
    {
      rendObj = ROBJ_DTEXT
      text = ::loc("receivedAwards")
      font = Fonts.medium_text
      color = activeTxtColor
      hplace = ALIGN_CENTER
    }
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = bigPadding
      valign = ALIGN_CENTER
      children = unlockedRewards.map(@(count, tpl) {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_CENTER
        children = [
          txt({
            text = ::loc("common/amountShort", { count = count })
            font = Fonts.medium_text
          })
          mkCurrencyImage(tpl, ticketHeight * 1.5)
          txt(::loc($"items/{tpl}"))
        ]
      }).values()
    }
  ]
}.__update(rewardStyle)

local function mkArmyProgress(
  armyId, armyWasLevel, armyWasExp, armyAddExp, progressCfg, unlockRewards,
  hasNewLevel, onFinish, gainRewardContent
) {
  local levelGrid = progressCfg?.expToArmyLevel
  if (levelGrid == null)
    return null

  local expToNextLevel = levelGrid?[armyWasLevel] ?? levelGrid.top()
  local gainLevel = armyWasExp + armyAddExp >= expToNextLevel ? armyWasLevel + 1 : null
  local squadIndexToUnlock = (progressCfg?.lockedSquads ?? {}).findindex(@(s) s?.level == armyWasLevel + 1)
  local squadToUnlock = squadIndexToUnlock != null
    ? { squadId = squadIndexToUnlock }.__update(progressCfg?.lockedSquads[squadIndexToUnlock])
    : null

  local unlockedRewards = unlockRewards
    .filter(@(u) !(u?.isNext ?? false))
    .reduce(@(res, val)
      res.__update({[val.unlockId] = (res?[val.unlockId] ?? 0) + val.unlockCount}), {})

  local timeForRewards = unlockedRewards.len() > 0 ? 2 : 0
  local squadAnimDelay = AWARD_ANIM_DELAY * unlockRewards.len() + PROGRESS_ANIM_DELAY + timeForRewards
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = 3 * bigPadding
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = [
          mkLevelsGrid(armyWasLevel, armyAddExp)
          mkProgress({
            expToNextLevel
            armyWasExp
            armyAddExp
            gainLevel
            unlockRewards
            hasNewLevel
            onFinish = function() {
              if (unlockedRewards.len() > 0) {
                gainRewardContent(mkGainAwards(unlockedRewards))
                sound_play("ui/debriefing/squad_progression_appear")
              }
              if (unlockRewards.len() == 0 && squadToUnlock == null)
                onFinish?()
            }
          })
          mkAwards(unlockRewards, expToNextLevel, timeForRewards, squadToUnlock == null
            ? onFinish
            : null)
        ]
      }
      @() {
        watch = [hasPremium, monetization]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          squadToUnlock != null
            ? mkSquadUnlock(gainLevel, squadToUnlock, armyId, squadAnimDelay, onFinish, gainRewardContent)
            : null
          gainLevel == null && !hasPremium.value && monetization.value
            ? textButton.PrimaryFlat(::loc("premium/getTwiceMuch"), function() {
              premiumWnd()
              sendBigQueryUIEvent("open_premium_window", "battle_debriefing", "army_progress")
            }, { margin = 0 })
            : null
        ]
      }
    ]
  }
}

return ::kwarg(mkArmyProgress)
 