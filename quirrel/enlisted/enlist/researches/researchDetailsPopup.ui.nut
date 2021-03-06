local style = require("enlisted/enlist/viewConst.nut")
local {statusIconLocked} =  require("enlisted/style/statusIcon.nut")
local {TextDefault} = require("ui/style/colors.nut")
local textButton = require("enlist/components/textButton.nut")
local hoverImage = require("enlist/components/hoverImage.nut")
local { makeVertScroll, thinStyle } = require("ui/components/scrollbar.nut")
local spinner = require("enlist/components/spinner.nut")({ height = ::hdpx(72) })
local state = require("researchesState.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { purchaseMsgBox } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local { sound_play } = require("sound")


local researchDef = null
local priceIconSize = ::hdpx(30)

local statusCfg = {
  [state.LOCKED] = {
    warning = ::loc("Need to research previous")
    onResearch = function() {
      foreach(researchId in researchDef.requirements)
        if (state.researchStatuses.value?[researchId] != state.RESEARCHED)
          hoverImage.attractToImage(researchId)
    }
  },
  [state.NOT_ENOUGH_EXP] = {
    warning = ::loc("Not enough army exp")
    onResearch = function() {
      ::anim_start(state.BALANCE_ATTRACT_TRIGGER)
      local cost = state.curSquadProgress.value?.levelCost ?? 0
      if (!monetization.value || cost <= 0)
        return
      purchaseMsgBox({
        price = cost
        currencyId = "EnlistedGold"
        title = ::loc("Not enough army exp")
        description = ::loc("buy/squadLevelConfirmForResearch")
        purchase = @() state.buySquadLevel(function() {
          sound_play("ui/upgrade_unlock")
          state.research(researchDef.research_id)
        })
        alwaysShowCancel = true
        srcComponent = "buy_researches_level_on_research"
      })
    }
  },
  [state.CAN_RESEARCH] = {
    onResearch = function() {
      sound_play("ui/upgrade_unlock")
      state.research(researchDef.research_id)
    }
  }
}

local researchDescription = @() {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_LEFT
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  font = Fonts.medium_text
  color = TextDefault
  text = ::loc(researchDef?.description)
}

local mkResearchBtn = @(onResearch) @() {
  watch = state.isResearchInProgress
  children = state.isResearchInProgress.value
    ? spinner
    : textButton.PrimaryFlat(::loc("research/researchBtnText"), onResearch, {
        hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
      })
}

local function researchInfoFooter() {
  local res = { watch = state.researchStatuses }
  local cfg = statusCfg?[state.researchStatuses.value?[researchDef.research_id]]
  if (!cfg?.onResearch)
    return res

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = style.bigGap
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        font = Fonts.medium_text
        text = cfg?.warning
        halign = ALIGN_CENTER
        color = statusIconLocked
      }
      {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = style.bigGap
        children = [
          {
            rendObj = ROBJ_DTEXT
            font = Fonts.medium_text
            text = ::loc("research/researchPrice", { price = researchDef.price })
          }
          {
            rendObj = ROBJ_IMAGE
            size = [priceIconSize, priceIconSize]
            image = ::Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(priceIconSize))
          }
        ]
      }
      mkResearchBtn(cfg.onResearch)
    ]
  })
}

local function researchInfoView() {
  local res = { watch = state.selectedResearch, size = flex() }
  researchDef = state.selectedResearch.value
  if (!researchDef)
    return res

  return res.__update({
    key = researchDef.research_id
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = style.blurBgColor
    fillColor = style.blurBgFillColor
    padding = style.researchListTabPadding
    transform = { pivot = [0, 0]}
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
      { prop = AnimProp.scale, from =[0, 1], to =[1, 1], play = true, duration = 0.15, easing = OutQuad }
    ]
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        font = Fonts.big_text
        text = ::loc(researchDef?.name)
      }
      {
        size = flex()
        margin = [style.researchListTabPadding]
        children = makeVertScroll(researchDescription, { styling = thinStyle })
      }
      researchInfoFooter
    ]
  })
}

return {
  flow = FLOW_VERTICAL
  size = flex()
  gap = style.gap
  children = researchInfoView
}
 