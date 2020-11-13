local math = require("std/math.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local msgbox = require("enlist/components/msgbox.nut")
local { getLinkedObjectsValues } = require("enlisted/enlist/meta/metalink.nut")
local mkItemWithMods = require("enlisted/enlist/soldiers/mkItemWithMods.nut")
local textButtonStyle = require("daRg/components/textButton.style.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local {
  curCampItems, curArmy, itemCountByArmy
} = require("enlisted/enlist/soldiers/model/state.nut")
local { disassembleItem, upgradeItem } = require("enlisted/enlist/soldiers/model/itemActions.nut")
local { upgradeCostMultByArmy } = require("enlisted/enlist/researches/researchesSummary.nut")
local {
  allItemTemplates, findItemTemplate
} = require("enlisted/enlist/soldiers/model/all_items_templates.nut")
local {
  defTxtColor, bigPadding, smallPadding, u, warningColor, bonusColor
} = require("enlisted/enlist/viewConst.nut")
local {
  slotItems, curInventoryItem, viewItem, viewItemParts, mkItemPartsNumberComp, close
} = require("enlisted/enlist/soldiers/model/selectItemState.nut")
local { diffUpgrades } = require("itemDetailsPkg.nut")
local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { sound_play } = require("sound")

local getRangeText = @(vMin, vMax)
  vMax == null || vMin == vMax ? vMin : $"{vMin}-{vMax}"

local itemPartsAmountCtor = @(minVal, maxVal = null) @(text, params, handler, group, sf, isBig = false, defColor = null) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    text
    {
      rendObj = ROBJ_DTEXT
      color = defColor ?? (sf & S_HOVER ? textButtonStyle.TextHover : textButtonStyle.TextNormal)
      text = getRangeText(minVal, maxVal)
      font = isBig ? Fonts.big_text : Fonts.small_text
    }
    {
      rendObj = ROBJ_STEXT
      color = defColor ?? (sf & S_HOVER ? textButtonStyle.TextHover : textButtonStyle.TextNormal)
      font = Fonts.fontawesome
      text = fa["gear"]
    }
  ]
}

local function getUpgItemSacrificeGuids(item, modifyData, armyId) {
  local sacrificeItemTpl = item?.disassembly
  if (sacrificeItemTpl == null)
    return null

  local res = {}
  local costMult = upgradeCostMultByArmy.value?[armyId][item?.basetpl] ?? 1.0
  local reqItemParts = math.ceil(modifyData.upgradeRequired * costMult).tointeger()
  local itemParts = getLinkedObjectsValues(curCampItems.value, curArmy.value)
    .filter(@(item) item?.basetpl == sacrificeItemTpl)
  foreach (i in itemParts) {
    res[i.guid] <- ::min(i.count, reqItemParts)
    reqItemParts -= i.count
    if (reqItemParts <= 0)
      break
  }

  return reqItemParts <= 0 ? res : null
}

local function openItemPartsMsg(titleText, bodyText, mkResultObj, color = null) {
  msgbox.showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      gap = 5 * bigPadding
      halign = ALIGN_CENTER
      children = [
        txt({ text = ::loc(titleText), font = Fonts.medium_text })
        {
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          gap = bigPadding
          children = [
            txt(::loc(bodyText))
              .__update(color != null ? { color = color } : {})
            mkResultObj(null, null, null, null, 0, true, color)
              .__update({ gap = bigPadding })
          ]
        }
      ]
    }
    buttons = [{ text = ::loc("OK"), isCancel = true, action = function() {
      ::anim_start("modifyInfo")
    }}]
  })
}

local mkDisassembleInfo = @(item, mkResultObj) {
  flow = FLOW_VERTICAL
  gap = 5 * bigPadding
  halign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_VERTICAL
      gap = sh(2)
      halign = ALIGN_CENTER
      children = [
        txt(::loc("disassembleItemMsgHeader"))
          .__update({ font = Fonts.medium_text })
        txt(::loc("disassembleItemMsgText"))
      ]
    }
    {
      flow = FLOW_VERTICAL
      gap = sh(1)
      halign = ALIGN_CENTER
      children = [
        txt(::loc("itemWillBeLost"))
          .__update({ color = warningColor })
        mkItemWithMods({
          item = item.__merge({ count = 1 })
          itemSize = [7.0 * u, 2.0 * u]
          isInteractive = false
        })
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      gap = bigPadding
      children = [
        txt(::loc("youWillReceive"))
          .__update({ color = bonusColor })
        mkResultObj(null, null, null, null, 0, true, bonusColor)
          .__update({ gap = bigPadding })
      ]
    }
  ]
}

local function openDisassembleItemMsg(item, iGuid, armyId, mkResultObj) {
  if (iGuid == null)
    msgbox.show({
      text = ::loc("noFreeItemToDisassemble")
      buttons = [{ text = ::loc("OK"), isCancel = true }]
    })
  else
    msgbox.showMessageWithContent({
      content = mkDisassembleInfo(item, mkResultObj)
      buttons = [
        { text = ::loc("Yes")
          action = function() {
            local itemParts = mkItemPartsNumberComp(viewItem.value)
            local wasItemParts = itemParts.value
            sound_play("ui/weapon_disassemble")
            disassembleItem(armyId, iGuid, function(res) {
              local itemToSelect = item.basetpl == null ? null
                : slotItems.value.findvalue(@(i) i?.basetpl == item.basetpl)
              if (itemToSelect != null)
                curInventoryItem(itemToSelect)

              local addedItemParts = itemParts.value - wasItemParts
              openItemPartsMsg(::loc("disassembleSuccess"),
                               ::loc("youHaveReceived"),
                               itemPartsAmountCtor(addedItemParts),
                               bonusColor)
            })
          }
          isCurrent = true }
        { text = ::loc("Cancel"), isCancel = true }
      ]
    })
}

local function mkUpgradeItemInfo(currentItem, upgradedItem, mkSacrificeObj, modifyData) {
  local chance = modifyData.upgradeChance
  local upgradesList = diffUpgrades(currentItem)
  return {
    size = [sw(90), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        children = [
          txt(::loc("upgradeItemMsgHeader")).__update({
            hplace = ALIGN_CENTER
            font = Fonts.medium_text
          })
          itemPartsAmountCtor(viewItemParts.value)(null, null, null, null, 0, true).__update({
            hplace = ALIGN_RIGHT
          })
        ]
      }
      chance >= 1.0 ? null : txt(::loc("upgradeItemWarning"))
      {
        flow = FLOW_HORIZONTAL
        gap = 5 * bigPadding
        valign = ALIGN_TOP
        margin = 5 * bigPadding
        children = [
          mkItemWithMods({
            item = currentItem.__merge({ count = 1 })
            itemSize = [7.0 * u, 2.0 * u]
            isInteractive = false
          })
          {
            size = [SIZE_TO_CONTENT, 2.0 * u]
            valign = ALIGN_CENTER
            text = fa["arrow-circle-right"]
            rendObj = ROBJ_STEXT
            font = Fonts.fontawesome
            fontSize = hdpx(30)
            color = defTxtColor
          }
          {
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              mkItemWithMods({
                item = upgradedItem.__merge({ count = 1 })
                itemSize = [7.0 * u, 2.0 * u]
                isInteractive = false
              })
              upgradesList.len() <= 0 ? null : {
                rendObj = ROBJ_TEXTAREA
                size = [flex(), SIZE_TO_CONTENT]
                text = ", ".join(upgradesList)
                behavior = Behaviors.TextArea
                color = defTxtColor
              }
            ]
          }
        ]
      }
      {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_CENTER
        children = [
          txt(::loc("upgradeItemSpendText")).__update({
            color = warningColor
          })
          mkSacrificeObj(null, null, null, null, 0, true, warningColor)
            .__update({ gap = bigPadding })
        ]
      }
      {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_CENTER
        children = [
          txt(::loc("upgradeItemChanceText"))
          txt({ text = $"{(chance * 100).tointeger()}%", font = Fonts.big_text })
        ]
      }
    ]
  }
}

local countItemsByTemplate = @(armyId, basetpl) itemCountByArmy.value?[armyId][basetpl] ?? 0

local mkUpgradeItemButtons = @(basetpl, upgradeitem, armyId, iGuid, sGuids, mkSacrificeObj) [
  { text = ::loc("Yes")
    action = function() {
      local itemsCount = countItemsByTemplate(armyId, upgradeitem)
      upgradeItem(armyId, iGuid, sGuids, function(_) {
        itemsCount = countItemsByTemplate(armyId, upgradeitem) - itemsCount
        local addedItem = slotItems.value.findvalue(@(i)
          !(i?.isShopItem ?? false) && i?.basetpl == upgradeitem && !i.wasSeen)
        local itemToSelect = addedItem == null
          ? slotItems.value.findvalue(@(i) i?.basetpl == basetpl)
          : slotItems.value.findvalue(@(i) i?.basetpl == upgradeitem && i.wasSeen)
        if (itemToSelect != null)
          curInventoryItem(itemToSelect)

        if (itemsCount <= 0)
          openItemPartsMsg(::loc("upgradeFailed"), ::loc("itemPartsSpend"),
            mkSacrificeObj, warningColor)
        }
      )
    }
    isCurrent = true }
  { text = ::loc("Cancel"), isCancel = true }
]

local function openUpgradeItemMsg(currentItem, iGuid, armyId, modifyData, mkSacrificeObj) {
  if (iGuid == null || (currentItem?.guid ?? "") == "") {
    msgbox.show({ text = ::loc("noFreeItemToUpgrade") })
    return
  }

  local sGuids = getUpgItemSacrificeGuids(currentItem, modifyData, armyId)
  if (sGuids == null) {
    msgbox.show({
      text = ::loc("noItemPartsToUpgrade")
      buttons = [
        {
          text = ::loc("GoToShop")
          action = function() {
            close()
            setCurSection("SHOP")
          }
        }
        { text = ::loc("OK"), isCancel = true, isCurrent = true }
      ]
    })
    return
  }

  local { basetpl, upgradeitem } = currentItem
  local upgradedItem = findItemTemplate(allItemTemplates, armyId, upgradeitem)
  if (upgradedItem == null)
    // it's definitely setup error but it shouldn't break ui
    return
  upgradedItem = currentItem.__merge(upgradedItem)
  msgbox.showMessageWithContent({
    content = mkUpgradeItemInfo(currentItem, upgradedItem, mkSacrificeObj, modifyData)
    buttons = mkUpgradeItemButtons(basetpl, upgradeitem, armyId, iGuid, sGuids, mkSacrificeObj)
  })
}

return {
  openDisassembleItemMsg
  openUpgradeItemMsg
  itemPartsAmountCtor
}
 