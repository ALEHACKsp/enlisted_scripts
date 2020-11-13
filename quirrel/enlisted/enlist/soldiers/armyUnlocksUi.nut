local fontIconButton = require("enlist/components/fontIconButton.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local campaignTitle = require("enlisted/enlist/campaigns/campaign_title_small.ui.nut")
local unlockSquadScene = require("unlockSquadScene.nut")
local cratesPresentation = require("enlisted/globals/cratesPresentation.nut")
local itemRewardPromo = require("components/itemRewardPromo.nut")
local { safeAreaSize } = require("enlist/options/safeAreaState.nut")
local { primaryButtonStyle } = require("enlist/components/textButton.nut")
local { currencyBtn } = require("enlisted/enlist/currency/currenciesComp.nut")
local { enlistedGold } = require("enlisted/enlist/currency/currenciesList.nut")
local { get_army_level_reward } = require("enlisted/enlist/meta/clientApi.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { debounce } = require("utils/timers.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local { makeHorizScroll } = require("daRg/components/scrollbar.nut")
local armySelect = require("army_select.ui.nut")
local { armyLevelsData } = require("enlisted/enlist/campaigns/armiesConfig.nut")
local { mkSquadSmallCard } = require("mkSquadPromo.nut")
local { ModalBgTint } = require("ui/style/colors.nut")
local { promoLarge } = require("enlisted/enlist/currency/pkgPremiumWidgets.nut")
local { squadsCfgById } = require("enlisted/enlist/soldiers/model/config/squadsConfig.nut")
local { purchaseMsgBox } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local {
  bigGap, bigPadding, activeTxtColor, defBgColor, progressBorderColor,
  progressExpColor, fadedTxtColor
} = require("enlisted/enlist/viewConst.nut")
local { curArmyData, armySquadsById } = require("model/state.nut")
local {
  curArmyLevels, curArmyLevelsSize, getPositionByExp, curArmyExp, hasArmyUnlocks,
  curArmySquadsUnlocks, curArmyRewardsUnlocks, unlockSquad, curArmyLevel,
  curBuyLevelData, buyArmyLevel, curArmyLevelRewardsUnlocks, receivedUnlocks,
  curArmyNextUnlockLevel, forceScrollToLevel
} = require("model/armyUnlocksState.nut")

local progressLineHeight = ::hdpx(35)
local levelWidth = sw(40) + bigPadding
local tblScrollHandler = ::ScrollHandler()

local showSubLevels = ::Watched(false)

local function getLevelStartExp(lvl) {
  local levels = curArmyLevels.value.len()
  return lvl < 0 || levels <= 0 ? 0
    : lvl < levels ? curArmyLevels.value[lvl]?.expFrom ?? 0
    : curArmyLevels.value.top()?.expTo ?? 0
}

local function mkProgressText(lvl, exp, curLvl, curExp) {
  if (exp <= 0)
    return null

  local interval = curArmyLevels.value?[lvl]
  if (!interval)
    return null

  local levelPos = getPositionByExp((interval.expFrom + interval.expTo) / 2)
  local pos = (levelPos * levelWidth).tointeger()
  local expText = lvl == curLvl ? curExp
    : lvl < curLvl ? exp
    : 0
  return {
    size = [0, SIZE_TO_CONTENT]
    pos = [pos, 0]
    halign = ALIGN_CENTER
    children = txt({
      text = $"{expText}/{exp}"
      font = Fonts.medium_text
      color = activeTxtColor
    })
  }
}

local experienceIntervals = @() {
  watch = [armyLevelsData, curArmyLevel, curArmyExp]
  children = armyLevelsData.value
    .map(@(levelData, idx) mkProgressText(idx, levelData.exp, curArmyLevel.value, curArmyExp.value))
}

local experienceBar = function() {
  local fullSize = (curArmyLevelsSize.value * levelWidth).tointeger() - bigPadding
  local pos = getPositionByExp(getLevelStartExp(curArmyLevel.value) + curArmyExp.value)
  local expSize = min((pos * levelWidth).tointeger(), fullSize)
  local children = [{
    rendObj = ROBJ_SOLID
    size = [expSize, progressLineHeight]
    color = progressExpColor
  }]
  children.extend(curArmyLevels.value
    .filter(@(lvl) lvl.expFrom > 0)
    .map(@(lvl) {
      rendObj = ROBJ_SOLID
      size = [::hdpx(2), flex()]
      pos = [(getPositionByExp(lvl.expFrom) * levelWidth - 1).tointeger(), 0]
      color = progressBorderColor
    }))
  children.append({
    rendObj = ROBJ_BOX
    size = [fullSize, progressLineHeight]
    borderWidth = ::hdpx(2)
    borderColor = progressBorderColor
  })
  return {
    watch = [curArmyExp, curArmyLevels, curArmyLevelsSize]
    children = children
  }
}

local mkLevelLabel = @(lvl, hasBlink) {
  pos = [(getPositionByExp(lvl.expFrom) * levelWidth).tointeger(), 0]
  size = [0, SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  children = txt({
    key = $"lvl_txt_{lvl}_{hasBlink}"
    text = ::loc("levelInfo", { level = lvl.level })
    font = Fonts.medium_text
    color = activeTxtColor
    transform = { pivot = [0.5, 1] }
    animations = hasBlink
      ? [{ prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1,
           play = true, loop = true, easing = Blink }]
      : null
  })
}

local levelsLabels = function() {
  local nextUnlock = curArmyNextUnlockLevel.value
  local armyData = curArmyData.value
  return {
    watch = [curArmyLevels, curArmyNextUnlockLevel, curArmyData]
    vplace = ALIGN_TOP
    children = curArmyLevels.value
      .filter(@(lvl) lvl.expFrom > 0)
      .map(@(lvl) mkLevelLabel(lvl,
        (lvl.level == nextUnlock && armyData.level >= nextUnlock)))
  }
}

local mkSquadReward = @(squad) {
  pos = [(getPositionByExp(getLevelStartExp(squad.level) + squad.exp) * levelWidth).tointeger(), 0]
  size = [0, SIZE_TO_CONTENT]
  padding = [0, 0, ::hdpx(5), 0]
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_STEXT
    font = Fonts.fontawesome
    fontSize = ::hdpx(15)
    color = fadedTxtColor
    text = fa["chevron-down"]
    validateStaticText = false
  }
}

local squadsRewards = @() {
  watch = [curArmySquadsUnlocks, curArmyLevels]
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  children = curArmySquadsUnlocks.value
    .map(@(squad) mkSquadReward(squad))
}

local mkOtherReward = @(unlockLevel, unlockExp) {
  rendObj = ROBJ_SOLID
  pos = [(getPositionByExp(getLevelStartExp(unlockLevel) + unlockExp) * levelWidth).tointeger(), 0]
  size = [::hdpx(1), flex()]
  padding = [::hdpx(10), 0, 0, 0]
  color = 0x66666666
}

local function mkOtherMultipleReward(unlock) {
  local periods = unlock.multipleUnlock.periods
  local expBegin = unlock.multipleUnlock.expBegin
  local distance = unlock.multipleUnlock.expEnd - expBegin
  local experiences = [expBegin]
  for (local i = 1; i < periods; i++)
    experiences.append(expBegin + distance * i / (periods - 1))

  return {
    size = [SIZE_TO_CONTENT, flex()]
    children = experiences.map(@(e)
      mkOtherReward(unlock.level, e).__update({color = 0x99996666}))
  }
}

local otherRewards = @() {
  watch = [curArmyRewardsUnlocks, curArmyLevels, showSubLevels]
  size = flex()
  vplace = ALIGN_TOP
  children = showSubLevels.value
    ? curArmyRewardsUnlocks.value.map(@(unlock) unlock.isMultiple
        ? mkOtherMultipleReward(unlock)
        : mkOtherReward(unlock.level, unlock.exp)
      )
    : null
}

local progressBlock = {
  children = [
    {
      valign = ALIGN_CENTER
      margin = [::hdpx(30), 0, ::hdpx(25), 0]
      children = [experienceBar, experienceIntervals]
    }
    levelsLabels
    squadsRewards
    otherRewards
  ]
}

local function mkOpenSquadScene(armyId, squadId) {
  local squad = ::Computed(@() armySquadsById.value?[armyId][squadId])
  return @() {
    size = flex()
    behavior = Behaviors.Button
    xmbNode = ::XmbNode()
    onClick = @() unlockSquadScene.open(squad)
  }
}

local mkLevelFrame = @(children) {
  rendObj = ROBJ_BOX
  size = [flex(), sh(60)]
  borderWidth = hdpx(1)
  borderColor = progressBorderColor
  fillColor = defBgColor
  children = children
}

local rewardBaseParams = {
  size = [sw(40), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
}

local mkEmptyLevelUnlock = {
  behavior = Behaviors.Button
  xmbNode = ::XmbNode()
  children = [
    mkLevelFrame(txt({
      text = ::loc("willBeAvailableSoon")
      font = Fonts.medium_text
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
    }))
  ]
}.__update(rewardBaseParams)

local function mkSquadBlockByUnlock(unlock, armyData) {
  local squadId = unlock.unlockId
  local armyId = armyData.guid
  local squadCfg = ::Computed(@() squadsCfgById.value?[armyId][squadId])
  local squad = ::Computed(@() armySquadsById.value?[armyId][squadId])
  local unlockInfo = ::Computed(function() {
    if (squad.value?.locked != true)
      return null
    local reqLevel = unlock.level
    local isNext = curArmyNextUnlockLevel.value == reqLevel
    local canUnlock = armyData.level >= reqLevel && armyData.exp >= unlock.exp
    return {
      unlockText = !canUnlock ? ::loc("squads/unlockInfo", { level = reqLevel })
        : !isNext ? ::loc("squads/needUnlockPrev") : ""
      unlockCb = isNext && canUnlock
        ? @() unlockSquad(squadId)
        : null
    }
  })
  return @() {
    watch = [squadCfg, squad]
    children = mkLevelFrame([
      mkOpenSquadScene(armyId, squadId),
      (squad.value == null || squadCfg.value == null) ? null
        : mkSquadSmallCard({
            squad = squad.value
            squadCfg = squadCfg.value
            armyId = armyId
            unlockInfo = unlockInfo
          })
    ])
  }.__update(rewardBaseParams)
}

local function mkLevelRewardCard(unlock, armyData) {
  return @() {
    behavior = Behaviors.Button
    xmbNode = ::XmbNode()
    children = mkLevelFrame([
      itemRewardPromo({
        armyId = unlock.armyId
        itemTpl = unlock.rewardInfo.rewardId
        countText = unlock.rewardInfo.rewardCountText
        presentation = cratesPresentation?[unlock.unlockId]
        unlockInfo = ::Computed(function() {
          if (unlock.unlockGuid in receivedUnlocks.value)
            return null

          local reqLevel = unlock.level
          local isNext = curArmyNextUnlockLevel.value == reqLevel
          local canUnlock = armyData.level >= reqLevel
          return {
            unlockText = !canUnlock ? ::loc("squads/unlockInfo", { level = reqLevel })
              : !isNext ? ::loc("squads/needUnlockPrev") : ""
            unlockCb = isNext && canUnlock
              ? @() get_army_level_reward(armyData.guid, unlock.unlockGuid)
              : null
          }
        })
      })
    ])
  }.__update(rewardBaseParams)
}

local levelsUnlocks = function() {
  local army = curArmyData.value
  local sqUnlocks = curArmySquadsUnlocks.value
  local lvlUnlocks = curArmyLevelRewardsUnlocks.value
  local children = array(armyLevelsData.value.len() - 1)
    .map(function(u, idx) {
      local unlock = sqUnlocks.findvalue(@(v) v?.level == idx + 2)
      if (unlock != null)
        return mkSquadBlockByUnlock(unlock, army)

      unlock = lvlUnlocks.findvalue(@(v) v?.level == idx + 2)
      if (unlock != null)
        return mkLevelRewardCard(unlock, army)

      return mkEmptyLevelUnlock
    })

  return {
    watch = [curArmyData, curArmySquadsUnlocks, armyLevelsData, curArmyLevelRewardsUnlocks]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = children
  }
}

local unlocksBlock = @() {
  watch = curArmyData
  margin = [0, 0, bigGap, 0]
  flow = FLOW_VERTICAL
  children = [
    progressBlock
    levelsUnlocks
  ]
}

local noArmyUnlocks = {
  rendObj = ROBJ_SOLID
  size = flex()
  color = ModalBgTint
  children = {
    rendObj = ROBJ_DTEXT
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    font = Fonts.medium_text
    text = ::loc("willBeAvailableSoon")
  }
}

local isBtnArrowLeftVisible = Watched(false)
local isBtnArrowRightVisible = Watched(true)

local function updateArrowButtons(elem) {
  isBtnArrowLeftVisible(elem.getScrollOffsX() > 0)
  isBtnArrowRightVisible(elem.getContentWidth() - elem.getScrollOffsX() > safeAreaSize.value[0])
}

tblScrollHandler.subscribe(function(val) {
  local elem = tblScrollHandler.elem
  if (elem == null)
    return

  updateArrowButtons(elem)
})

local function updateProgressScrollPos() {
  local nextSquadLevel = forceScrollToLevel.value ?? curArmyNextUnlockLevel.value
  local jumpToLevel = nextSquadLevel != null ? nextSquadLevel : curArmyLevel.value
  local xPos = getPositionByExp(getLevelStartExp(jumpToLevel)) * levelWidth
  tblScrollHandler.scrollToX((xPos - safeAreaSize.value[0] / 2).tointeger())
  forceScrollToLevel(null)
}

local function buyArmyLevelMsg() {
  local { cost = 0 } = curBuyLevelData.value
  purchaseMsgBox({
    price = cost
    currencyId = "EnlistedGold"
    title = ::loc("armyLevel", { level = curArmyLevel.value + 1 })
    description = ::loc("buy/armyLevelConfirm")
    purchase = buyArmyLevel
    scrComponent = "buy_campaign_level"
  })
}

curArmyData.subscribe(debounce(@(v) updateProgressScrollPos(), 0.1))

console.register_command(@() showSubLevels(!showSubLevels.value), "ui.campaignRewardsToggle")

local scrollArrowBtnStyle = {
  rendObj = ROBJ_SOLID
  size = [::hdpx(60), flex()]
  margin = [0,0,::hdpx(16),0]
  color = Color(0,0,0,200)
  iconParams = {
    fontSize = ::hdpx(36)
  }
}

local function scrollByArrow(dir) {
  local elem = tblScrollHandler?.elem
  if (elem == null)
    return

  tblScrollHandler.scrollToX((elem.getScrollOffsX() + levelWidth * dir).tointeger())
  updateArrowButtons(elem)
}

return @() {
  watch = hasArmyUnlocks
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        armySelect()
        { size = flex() }
        campaignTitle
      ]
    }
    hasArmyUnlocks.value
      ? {
          size = [flex(), SIZE_TO_CONTENT]
          children = [
            makeHorizScroll({
              xmbNode = ::XmbContainer({
                canFocus = @() false
                scrollSpeed = 10.0
                isViewport = true
              })
              children = unlocksBlock
              onAttach = updateProgressScrollPos
            }, {
              size = [flex(), SIZE_TO_CONTENT]
              scrollHandler = tblScrollHandler
              rootBase = class {
                key = "unlocksListRoot"
                behavior = Behaviors.Pannable
                wheelStep = 1
              }
            })
            @() {
              watch = isBtnArrowLeftVisible
              size = [SIZE_TO_CONTENT, flex()]
              children = isBtnArrowLeftVisible.value
                ? fontIconButton(fa["angle-left"], scrollArrowBtnStyle.__merge({
                    onClick = @() scrollByArrow(-1)
                  }))
                : null
            }
            @() {
              watch = isBtnArrowRightVisible
              size = [SIZE_TO_CONTENT, flex()]
              hplace = ALIGN_RIGHT
              children = isBtnArrowRightVisible.value
                ? fontIconButton(fa["angle-right"], scrollArrowBtnStyle.__merge({
                    onClick = @() scrollByArrow(1)
                  }))
                : null
            }
          ]
        }
      : noArmyUnlocks
    hasArmyUnlocks.value
      ? @() {
          watch = [curArmyLevel, curBuyLevelData, monetization]
          flow = FLOW_HORIZONTAL
          hplace = ALIGN_CENTER
          children = monetization.value
            ? [
                promoLarge(null, "army_unlocks")
                curBuyLevelData.value != null
                  ? currencyBtn({
                      btnText = ::loc("btn/buyItem", {
                        item = ::loc("level/short", { level = curArmyLevel.value + 1 })
                      })
                      currency = enlistedGold
                      price = curBuyLevelData.value.cost
                      cb = buyArmyLevelMsg
                      style = primaryButtonStyle.__merge({
                        hotkeys = [[ "^J:Y", { description = {skip=true}} ]]
                      })
                    })
                  : null
              ]
            : null
        }
      : null
  ]
}
 