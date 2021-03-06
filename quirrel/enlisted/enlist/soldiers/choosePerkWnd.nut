local { gap, blurBgColor, bigGap, defTxtColor } = require("enlisted/enlist/viewConst.nut")
local { sound_play } = require("sound")
local { navHeight } = require("enlisted/enlist/mainMenu/mainmenu.style.nut")
local modalWindows = require("daRg/components/modalWindows.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local textButton = require("enlist/components/textButton.nut")
local spinner = require("enlist/components/spinner.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")
local { mkPerksPointsBlock, mkRollBigSlot } = require("components/perksPackage.nut")
local { classIcon, levelBlockWithProgress } = require("components/soldiersUiComps.nut")
local { getObjectName } = require("itemsInfo.nut")
local { currencyBtn } = require("enlisted/enlist/currency/currenciesComp.nut")
local { enlistedGold } = require("enlisted/enlist/currency/currenciesList.nut")
local { curCampSoldiers } = require("model/state.nut")
local {
  perkChoiceWndParams, perksData, getPerkPointsInfo, choosePerk, showActionError,
  perkActionsInProgress, changePerkCost, changePerks
} = require("model/soldierPerks.nut")
local availablePerksWnd = require("availablePerksWnd.nut")
local { purchaseMsgBox } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { mkSoldiersData } = require("model/collectSoldierData.nut")

const WND_UID = "choose_perk_wnd"

local selectedPerk = Watched(null)
local isRollAnimation = Watched(false)

local localGap = bigGap * 3

local sPerks = ::Computed(@() perksData.value?[perkChoiceWndParams.value?.soldierGuid])
local soldier = mkSoldiersData(::Computed(@() curCampSoldiers.value?[perkChoiceWndParams.value?.soldierGuid]))
local perkPointsInfoWatch = ::Computed(@() sPerks.value == null ? null
  : getPerkPointsInfo(sPerks.value, [sPerks.value?.prevPerk]))
local needShow = ::Computed(@() sPerks.value != null
  && (perkChoiceWndParams.value?.choice.len() ?? 0) > 0)

local close = function() {
  if (isRollAnimation.value) {
    isRollAnimation(false)
    ::anim_skip("perks_roll_anim")
    return
  }
  perkChoiceWndParams(null)
}

perkChoiceWndParams.subscribe(function(v) {
  local choice = v?.choice ?? []
  if (choice.len() == 0)
    return
  local prevPerk = perksData.value?[v?.soldierGuid].prevPerk
  if ((prevPerk ?? "") == "")
    prevPerk = choice[0]
  selectedPerk(prevPerk)
})

local function onChoose(perkId) {
  if (!needShow.value)
    return
  local { soldierGuid, tierIdx, slotIdx } = perkChoiceWndParams.value
  choosePerk(soldierGuid, tierIdx, slotIdx, perkId,
    function(res) {
      if (!res?.isSuccess)
        showActionError(res?.errorText ?? "unknown error")
      else {
        ::gui_scene.setTimeout(0.05, function() {
          ::anim_start($"tier{tierIdx}slot{slotIdx}")
          ::anim_start($"{soldierGuid}lvl_anim")
        })
      }
      close()
    })
  sound_play("ui/craft")
}

local closeButton = closeBtnBase({ onClick = close })

local mkText = @(text) { rendObj = ROBJ_DTEXT, font = Fonts.big_text, color = defTxtColor, text = text }

local header = {
  size = [hdpx(300) * 3 + localGap * 2, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = mkText(::loc("choose_new_perk"))
  }
}

local perksChoice = function() {
  local choice = perkChoiceWndParams.value?.choice ?? []
  return {
    watch = [perkChoiceWndParams, isRollAnimation]
    flow = FLOW_HORIZONTAL
    gap = localGap
    children = choice.map(@(perkId, idx)
      mkRollBigSlot({
        idx = idx
        total = choice.len()
        perkId = perkId
        selectedPerk = selectedPerk
        onClick = function() {
          if (isRollAnimation.value == false)
            selectedPerk(perkId)
        }
        onDoubleClick = function() {
          if (isRollAnimation.value == false)
            onChoose(perkId)
        }
        isRollAnimation = isRollAnimation
        hasRoll = perkChoiceWndParams.value.isNewChoice && isRollAnimation.value
      }))
  }
}

local applyButton = @() {
  watch = selectedPerk
  children = textButton.PrimaryFlat(::loc("Ok"),
    function() {
      if (selectedPerk.value != null)
        onChoose(selectedPerk.value)
    },
    {
      margin = 0
      isEnabled = selectedPerk.value != null
    })
}

local function changePerksAction() {
  if (!needShow.value)
    return
  local { soldierGuid, tierIdx, slotIdx } = perkChoiceWndParams.value
  changePerks(soldierGuid, tierIdx, slotIdx,
    @(choiceData) "errorText" in choiceData ? showActionError(choiceData.errorText)
      : perkChoiceWndParams(choiceData))
}

local changePerksMsg = @() purchaseMsgBox({
  price = changePerkCost.value
  currencyId = "EnlistedGold"
  title = ::loc("msg/changePerks")
  purchase = changePerksAction
  dontShowMeTodayId = "change_perks"
  fromId = "window_perks_change_perk"
})

local function changePerksButton() {
  local res = { watch = [changePerkCost, monetization] }
  local cost = changePerkCost.value
  if (cost <= 0 || !monetization.value)
    return res
  return res.__update({
    children = currencyBtn({
      btnText = ::loc("btn/changePerks"),
      currency = enlistedGold,
      price = cost,
      cb = changePerksMsg,
      style = { margin = 0 }
    })
  })
}

local buttons = @() {
  watch = [perkActionsInProgress, isRollAnimation]
  size = [SIZE_TO_CONTENT, sh(10)]
  flow = FLOW_HORIZONTAL
  gap = gap
  children = isRollAnimation.value ? null
    : perkActionsInProgress.value.len() > 0 ? spinner
    : [
        changePerksButton
        applyButton
      ]
}

local function currentPerksBtn() {
  local perks = sPerks.value
  return {
    watch = sPerks
    children = textButton.SmallBordered(::loc("current_perks_list"),
      @(event) availablePerksWnd.openCurrentPerks(event.targetRect, perks, [perks?.prevPerk]), {margin = 0})
  }
}

local soldierInfo = {
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  gap = gap
  children = [
    @() {
      watch = soldier
      flow = FLOW_HORIZONTAL
      gap = gap
      children = [
        classIcon(soldier.value?.sClass, hdpx(30), soldier.value?.sClassRare)
        mkText(getObjectName(soldier.value))
      ]
    }
    levelBlockWithProgress(soldier, sPerks, { halign = ALIGN_RIGHT })
    mkPerksPointsBlock(perkPointsInfoWatch)
    currentPerksBtn
  ]
}

local function choosePerkWnd() {
  isRollAnimation(perkChoiceWndParams.value.isNewChoice)
  return {
    size = flex()
    padding = [navHeight, 0, 0, 0]
    children = [
      {
        hplace = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        children = [
          closeButton
          soldierInfo
        ]
      }
      {
        size = [sw(60), flex()]
        hplace = ALIGN_CENTER
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        gap = localGap
        children = [
          header
          perksChoice
          buttons
        ]
      }
    ]
  }
}

local open = @() modalWindows.add({
  key = WND_UID
  size = [sw(100), sh(100)]
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  children = choosePerkWnd()
  onClick = close
})

if (needShow.value)
  open()

needShow.subscribe(@(v) v ? open() : modalWindows.remove(WND_UID))
 