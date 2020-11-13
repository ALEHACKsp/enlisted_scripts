local {
  gap, bigPadding, soldierWndWidth, noteTxtColor, blurBgColor, blurBgFillColor,
  listBtnAirStyle, defTxtColor
} = require("enlisted/enlist/viewConst.nut")
local textButton = require("enlist/components/textButton.nut")
local { perksData, notChoosenPerkSoldiers } = require("model/soldierPerks.nut")
local soldierEquipUi = require("soldierEquip.ui.nut")
local soldierPerksUi = require("soldierPerks.ui.nut")
local {
  newPerksIcon, tierText, levelBlockWithProgress, classIcon, className,
  classTooltip, rankingTooltip
} = require("components/soldiersUiComps.nut")
local { getObjectName } = require("itemsInfo.nut")
local { mkSoldiersData } = require("model/collectSoldierData.nut")
local armyEffects = require("model/armyEffects.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")
local { withTooltip } = require("ui/style/cursors.nut")
local { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
local { curUnseenUpgradesBySoldier } = require("model/unseenUpgrades.nut")


local tabs = [
  {
    id = "weaponry"
    locId = "soldierWeaponry"
    content = soldierEquipUi
    childCtor = @(soldier, isSelected) soldier == null ? null
      : newPerksIcon(soldier.guid, isSelected, ::Computed(@()
          (unseenSoldiersWeaponry.value?[soldier?.guid].len() ?? 0) +
          (curUnseenUpgradesBySoldier.value?[soldier?.guid] ?? 0)
        ))
  }
  {
    id = "perks"
    locId = "soldierPerks"
    content = soldierPerksUi
    childCtor = @(soldier, isSelected) soldier == null ? null
      : newPerksIcon(soldier.guid, isSelected, ::Computed(@() notChoosenPerkSoldiers.value?[soldier.guid] ?? 0))
  }
]

local curTab = persist("soldierInfoTab", @() Watched(tabs[0]))
if (curTab.value != tabs[0])
  curTab(tabs.findvalue(@(t) t.locId == curTab.value?.locId) ?? tabs[0])

local hdrAnimations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic, trigger = "hdrAnim"}
  { prop = AnimProp.translate, from =[-hdpx(70), 0], to = [0, 0], duration = 0.15, easing = OutQuad, trigger = "hdrAnim"}
]

local mkClassBonus = @(classBonusWatch) function() {
  local res = { watch = classBonusWatch }
  local bonus = 100 * classBonusWatch.value
  if (bonus == 0)
    return res
  return withTooltip(res.__update({
    rendObj = ROBJ_DTEXT
    color = defTxtColor
    font = Fonts.small_text
    text = " ({0})".subst(::loc("bonusExp/short", { value = $"+{bonus}" }))
  }), ::loc("tooltip/soldierExpBonus"))
}

local function nameBlock(soldier) {
  local soldierWatch = mkSoldiersData(soldier)
  local perksWatch = ::Computed(@() clone perksData.value?[soldier.value?.guid])
  local classBonusWatch = ::Computed(function() {
    local soldierV = soldier.value
    if (soldierV == null)
      return 0
    return armyEffects.value?[getLinkedArmyName(soldierV)].class_xp_boost[soldierV.sClass] ?? 0
  })
  return function() {
    local sClass = soldierWatch.value?.sClass
    local classRarity = soldierWatch.value?.sClassRare ?? 0
    local tier = soldierWatch.value?.tier ?? 1
    return {
      watch = soldierWatch
      size = [flex(), hdpx(65)]
      flow = FLOW_VERTICAL
      animations = hdrAnimations
      transform = {}
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          valign = ALIGN_BOTTOM
          children = [
            withTooltip({
              flow = FLOW_HORIZONTAL
              gap = gap
              children = [
                tierText(tier).__update({ font = Fonts.big_text })
                {
                  rendObj = ROBJ_DTEXT
                  text = getObjectName(soldierWatch.value)
                  font = Fonts.big_text
                  color = noteTxtColor
                }
              ]
            }, rankingTooltip(tier))
            { size = flex() }
            levelBlockWithProgress(soldierWatch, perksWatch)
          ]
        }
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          valign = ALIGN_BOTTOM
          children = [
            {
              flow = FLOW_HORIZONTAL
              gap = gap
              valign = ALIGN_CENTER
              children = [
                withTooltip({
                  flow = FLOW_HORIZONTAL
                  gap = gap
                  valign = ALIGN_CENTER
                  children = [
                    classIcon(sClass, hdpx(30), classRarity)
                    className(sClass, classRarity)
                  ]
                }, classTooltip(sClass))
                mkClassBonus(classBonusWatch)
              ]
            }
          ]
        }
      ]
    }
  }
}

local mkAnimations = @(isMoveRight) [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[hdpx(150) * (isMoveRight ? -1 : 1), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[0, 0], playFadeOut = true, to = [hdpx(150) * (isMoveRight ? 1 : -1), 0], duration = 0.2, easing = OutQuad }
]

local listBtnStyle = @(isSelected, idx, total)
  listBtnAirStyle(isSelected, idx, total).__update({ size = [flex(), SIZE_TO_CONTENT] })

local tabsList = @(soldier) @() {
  animations = hdrAnimations
  transform = {}
  watch = [curTab, soldier]
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = gap
  children = tabs.map(@(tab, idx) {
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      textButton(::loc(tab.locId), @() curTab(tab), listBtnStyle(curTab.value == tab, idx, tabs.len()))
      tab?.childCtor(soldier.value, curTab.value == tab)
    ]
  })
}

local content = ::kwarg(@(
  soldier, canManage, animations, selectedKeyWatch, mkDismissBtn,
  onDoubleClickCb = null, onResearchClickCb = null
) {
  clipChildren = true
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  size = [soldierWndWidth, flex()]
  animations = animations
  transform = {}
  children = {
    size = [soldierWndWidth, flex()]
    gap = bigPadding
    flow = FLOW_VERTICAL
    padding = bigPadding
    children = [
      nameBlock(soldier)
      tabsList(soldier)
      @() {
        animations = hdrAnimations
        transform = {}
        watch = curTab
        size = flex()
        children = curTab.value.content({
          soldier = soldier.value
          canManage = canManage
          selectedKeyWatch = selectedKeyWatch
          onDoubleClickCb = onDoubleClickCb
          onResearchClickCb = onResearchClickCb
        })
      }
      mkDismissBtn(soldier.value)
    ]
  }
})

return ::kwarg(function(
  soldierInfoWatch, isMoveRight = true, selectedKeyWatch = Watched(null),
  onDoubleClickCb = null, onResearchClickCb = null, mkDismissBtn = @(s) null
) {
  local animations = mkAnimations(isMoveRight)
  local lastSoldierGuid = soldierInfoWatch.value?.guid
  return function soldierInfoUi() {
    local newSoldierGuid = soldierInfoWatch.value?.guid
    if (lastSoldierGuid != null && newSoldierGuid != lastSoldierGuid)
      ::anim_start("hdrAnim") //no need change content anim when window appear anim playing
    lastSoldierGuid = newSoldierGuid

    return {
      watch = soldierInfoWatch
      size = soldierInfoWatch.value != null ? [soldierWndWidth, flex()] : null
      children = soldierInfoWatch.value != null ? content({
        soldier = soldierInfoWatch
        canManage = true
        animations = animations
        selectedKeyWatch = selectedKeyWatch
        onDoubleClickCb = onDoubleClickCb
        onResearchClickCb = onResearchClickCb
        mkDismissBtn = mkDismissBtn
      }) : null
    }
  }
}) 