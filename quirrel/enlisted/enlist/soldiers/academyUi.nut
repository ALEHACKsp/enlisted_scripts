local frp = require("std/frp.nut")
local colorize = require("enlist/colorize.nut")
local textButton = require("enlist/components/textButton.nut")
local spinner = require("enlist/components/spinner.nut")
local { getLinkedSquadGuid, getFirstLinkByType } = require("enlisted/enlist/meta/metalink.nut")
local { safeAreaSize } = require("enlist/options/safeAreaState.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { currencyBtn } = require("enlisted/enlist/currency/currenciesComp.nut")
local { enlistedGold } = require("enlisted/enlist/currency/currenciesList.nut")
local { purchaseMsgBox } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local { textarea } = require("enlist/components/text.nut")
local { makeVertScroll } = require("darg/components/scrollbar.nut")
local {
  slotBaseSize, slotMediumSize, gap, smallPadding, bigPadding, blurBgFillColor,
  blurBgColor, defTxtColor, titleTxtColor, scrollbarParams
} = require("enlisted/enlist/viewConst.nut")
local popupsState = require("enlist/popup/popupsState.nut")
local { mkSoldiersDataList } = require("model/collectSoldierData.nut")
local mkSoldiersList = require("mkSoldiersList.nut")
local mkTrainingBlock = require("mkTrainingBlock.nut")
local campaignTitle = require("enlisted/enlist/campaigns/campaign_title_small.ui.nut")
local { mkClassTab } = require("classesUiComps.nut")
local { perksData } = require("model/soldierPerks.nut")
local armySelect = require("army_select.ui.nut")
local { secondsToStringLoc } = require("utils/time.nut")
local { note } = require("enlisted/enlist/components/defcomps.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")(0.7)
local blinkingIcon = require("enlisted/enlist/components/blinkingIcon.nut")
local {
  allUnseenClasses, unseenClasses, markSeenClasses, markUnseenClasses
} = require("model/unseenClasses.nut")
local { curArmy } = require("model/state.nut")
local {
  trainingSoldiers, choosenSoldiers, soldiersList, hasArmyTraining,
  curArmyTraining, beginTraining, endTraining, checkMaxLevelToAddSoldier, curTrainingRestSec,
  removeSoldier, cancelTrainingByGuid, clearChoosenSoldiers, curSelectedClass,
  setSelectedClass, curSoldiersClasses, getTrainingCfgByTier, canFinishCurTraining,
  curArmyTrainingFinishCost, buyEndTraining, isTrainingRequestInProgress,
  curArmyAvailClasses, isAcademyVisible, hasTrainedSoldier
} = require("model/trainingState.nut")
local { gameProfile } = require("model/config/gameProfile.nut")
local { hasPremium } = require("enlisted/enlist/currency/premium.nut")
local mkValueWithBonus = require("enlisted/enlist/components/valueWithBonus.nut")
local { sound_play } = require("sound")

local isWindowActive = Watched(false)

local seenTrainResult = false

local checkForTrainingComplete = function() {
  if (!hasTrainedSoldier.value || !isWindowActive.value || seenTrainResult)
    return

  sound_play("ui/academy_training_complete")
  seenTrainResult = true
}

frp.subscribe([hasTrainedSoldier, isWindowActive], @(_) checkForTrainingComplete())

local soldiersBlockWidth = function() {
  local soldierWidth = slotBaseSize[0]
  local trainBlockWidth = max(soldierWidth * 1,5, sw(25))
  local sClassWidth = slotMediumSize[0]
  local gaps = bigPadding
  local totalFree = safeAreaSize.value[0] - trainBlockWidth - sClassWidth - 5 * gaps
  local slotAmount = (totalFree / soldierWidth).tointeger()
  return slotAmount * (soldierWidth + gaps) - gaps
}

local getEmptySlots = @(soldiers) (soldiers ?? []).filter(@(s) s == null).len()

local lockedTrainingPopup = @(s) popupsState.addPopup({
  id = "training_locked"
  text = ::loc("You can not change soldiers in active training!")
  styleName = "error"
})

local btnStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  margin = [0, bigPadding]
}

local timerTextareaStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  margin = [0, sh(2)]
  halign = ALIGN_CENTER
  color = defTxtColor
}

local trainingTimeInfo = function(tier) {
  local commonTime = getTrainingCfgByTier(tier)?.trainingTimeSec ?? 0
  local premiumBonusWatch = ::Computed(@() hasPremium.value
    ? secondsToStringLoc(commonTime * (1 - 1 / (gameProfile.value?.premiumBonuses.premiumTrainSpeedMul ?? 1)))
    : null)
  return {
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = ::hdpx(5)
    children = [
      note(::loc("train/timeInfo"))
      mkValueWithBonus(secondsToStringLoc(commonTime), premiumBonusWatch)
    ]
  }
}

local mkStartTrainingBtn = function(soldiers, perks) {
  local emptySlots = getEmptySlots(soldiers)
  return emptySlots > 0
    ? textButton.Transp(::loc("retraining/startBtnHint", { amount = emptySlots }),
        @(event) null, btnStyle)
    : [
        trainingTimeInfo(soldiers[0].tier)
        textButton.PrimaryFlat(::loc("retraining/startBtn"),
          function(event) {
            local sGuids = soldiers.map(@(s) s.guid)
            local sClasses = soldiers.map(@(s) s.sClass)
            seenTrainResult = false
            sound_play("ui/avademy_start_training")
            beginTraining(sGuids, @(_) markUnseenClasses(curArmy.value, sClasses))
          }, btnStyle)
      ]
}

local trainingRestTimeInfo = @() {
  watch = curTrainingRestSec
  size = [flex(), SIZE_TO_CONTENT]
  children = (curTrainingRestSec.value > 0
    ? textarea(::loc("train/timeLeft", {
        timeLeft = colorize(titleTxtColor, secondsToStringLoc(curTrainingRestSec.value))
      }))
    : textarea(::loc("train/completed"))).__update(timerTextareaStyle)
}

local function buyEndTrainingMsg(training, priceWatch, soldiers) {
  purchaseMsgBox({
    price = priceWatch
    currencyId = "EnlistedGold"
    title = ::loc("retraining/finishEarlyBtn")
    description = ::loc("train/buyConfirm")
    purchase = function() {
      local soldierGuid = getFirstLinkByType(training, "trainee")
      local sClass = soldiers.findvalue(@(s) s.guid == soldierGuid)?.sClass
      buyEndTraining(training, priceWatch.value, function(res) {
        clearChoosenSoldiers()
        setSelectedClass(sClass)
      })
    }
    srcComponent = "buy_training_finish"
  })
}

local mkBuyFinishTrainingBtn = @(training, soldiers, currency) @() {
  watch = [curArmyTrainingFinishCost, monetization]
  size = [flex(), SIZE_TO_CONTENT]
  children = monetization.value
    ? currencyBtn({
        btnText = ::loc("retraining/finishEarlyBtn")
        currency = currency
        price = curArmyTrainingFinishCost.value
        cb = @() buyEndTrainingMsg(training, curArmyTrainingFinishCost, soldiers)
        style = btnStyle
      })
    : null
}

local mkFinishTrainingBtn = @(training, canFinish, soldiers) canFinish
  ? textButton.PrimaryFlat(::loc("retraining/finishBtn"),
      function(event) {
        local soldierGuid = getFirstLinkByType(training, "trainee")
        local sClass = soldiers.findvalue(@(s) s.guid == soldierGuid)?.sClass
        endTraining(training, function(res) {
          sound_play("ui/academy_training_popup")
          clearChoosenSoldiers()
          setSelectedClass(sClass)
        })
      }, btnStyle)
  : mkBuyFinishTrainingBtn(training, soldiers, enlistedGold)

local mkCancelTrainingBtn = @(training, canCancel) canCancel
  ? textButton.Flat(::loc("retraining/cancelBtn"),
      function(event) {
        local trainingGuid = training?.guid
        if (trainingGuid != null)
          cancelTrainingByGuid(trainingGuid)
      },
      btnStyle)
  : null

local function navBlock() {
  local training = curArmyTraining.value
  local trSoldiers = trainingSoldiers.value
  local chSoldiers = choosenSoldiers.value
  local perks = perksData.value
  return {
    watch = [curArmyTraining, choosenSoldiers, trainingSoldiers, perksData, canFinishCurTraining, isTrainingRequestInProgress]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    margin = [sh(3), 0,0,0]
    halign = ALIGN_CENTER
    children = isTrainingRequestInProgress.value ? spinner
      : curArmyTraining.value == null ? mkStartTrainingBtn(chSoldiers, perks)
      : [
          trainingRestTimeInfo
          mkFinishTrainingBtn(training, canFinishCurTraining.value, trSoldiers)
          mkCancelTrainingBtn(training, !canFinishCurTraining.value)
        ]
  }
}

local armySelectWithMarks = armySelect({
  function addChild(armyId, sf) {
    local count = ::Computed(@() allUnseenClasses.value?[armyId].len() ?? 0)
    return function() {
      local res = { watch = count, pos = [hdpx(25), 0], key = armyId }
      if (count.value <= 0)
        return res
      return blinkingIcon("arrow-up", count.value, false).__update(res)
    }
  }
})

local unseenMark = @(className) function() {
  local isUnseen = unseenClasses.value?[className] ?? false
  local availCount = curArmyAvailClasses.value?[className] ?? 0
  return {
    watch = [unseenClasses, curArmyAvailClasses]
    hplace = ALIGN_RIGHT
    children = isUnseen ? unseenSignal
      : availCount > 0 ? blinkingIcon("arrow-up", availCount, false)
      : null
  }
}

local function onClassSelect(className) {
  markSeenClasses(curArmy.value, [className])
  setSelectedClass(className)
}

local classesScrolledBlock = @(children)
  @() {
    xmbNode = ::XmbContainer({
      canFocus = @() false
      scrollSpeed = 5.0
      isViewport = true
    })
    size = [slotMediumSize[0], flex()]
    children = makeVertScroll({
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      children = children
    }, scrollbarParams)
  }

local classesTabs = @() {
  watch = [curSoldiersClasses, curSelectedClass]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_VERTICAL
  gap = smallPadding
  padding = bigPadding
  children = [
    note(::loc("soldiers/classes")).__update({ size = SIZE_TO_CONTENT })
    classesScrolledBlock({
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = curSoldiersClasses.value.map(@(sClass)
          mkClassTab(sClass, curSelectedClass.value == sClass, onClassSelect, unseenMark(sClass)))
      })
  ]
}

local academyBlock = @() {
  watch = hasArmyTraining
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = gap
  children = [
    classesTabs
    mkSoldiersList.trainingList({
      width = soldiersBlockWidth()
      reserveSoldiersWatch = mkSoldiersDataList(::Computed(@() soldiersList.value.filter(@(s) getLinkedSquadGuid(s) == null)))
      squadsSoldiersWatch = mkSoldiersDataList(::Computed(@() soldiersList.value.filter(@(s) getLinkedSquadGuid(s) != null)))
      onSlotClickCb = !hasArmyTraining.value
        ? checkMaxLevelToAddSoldier
        : lockedTrainingPopup
    })
    mkTrainingBlock({
      choosenSoldiers = hasArmyTraining.value ? trainingSoldiers : choosenSoldiers
      curTrainingWatch = curArmyTraining
      onSlotClickCb = !hasArmyTraining.value
        ? removeSoldier
        : lockedTrainingPopup
      navBlock = navBlock
    })
  ]
}

local mainContent = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    armySelectWithMarks
    academyBlock
  ]
}

local academyUnavailable = {
  size = [flex(), sh(50)]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  pos = [0, sh(10)]
  gap = hdpx(50)
  children = [
    {
      font = Fonts.huge_text
      text = ::loc("menu/academyLocked")
      rendObj = ROBJ_DTEXT
    }
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      font = Fonts.big_text
      size = [sw(50), SIZE_TO_CONTENT]
      color = Color(180,180,180)
      text = ::loc("menu/academyLockedDesc")
    }
  ]
}

return @(){
  watch = isAcademyVisible
  size = flex()
  halign = ALIGN_RIGHT
  onAttach = @() isWindowActive(true)
  onDetach = @() isWindowActive(false)
  children = isAcademyVisible.value ? [
    mainContent
    campaignTitle
  ] : academyUnavailable
} 