local JB = require("ui/control/gui_buttons.nut")
local hoverHoldAction = require("utils/hoverHoldAction.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local colors = require("ui/style/colors.nut")
local spinner = require("enlist/components/spinner.nut")
local campaignTitle = require("enlisted/enlist/campaigns/campaign_title_small.ui.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")
local { curSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { makeVertScroll } = require("darg/components/scrollbar.nut")
local { tooltip } = require("ui/style/cursors.nut")
local tooltipBox = require("ui/style/tooltipBox.nut")
local { safeAreaSize } = require("enlist/options/safeAreaState.nut")
local soldierClasses = require("enlisted/enlist/soldiers/model/soldierClasses.nut")
local { utf8ToLower } = require("std/string.nut")
local { getRomanNumeral } = require("std/math.nut")
local colorize = require("enlist/colorize.nut")
local { curArmy } = require("enlisted/enlist/soldiers/model/state.nut")
local { Transp } = require("enlist/components/textButton.nut")

local armySelect = require("enlisted/enlist/soldiers/army_select.ui.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local {
  bigPadding, defBgColor, defTxtColor, soldierLvlColor, scrollbarParams,
  titleTxtColor, activeTxtColor
} = require("enlisted/enlist/viewConst.nut")
local {
  curArmyShopLines, shopConfig, purchaseInProgress, curUnseenAvailableShopItems,
  curUnseenAvailableShopGroups, curArmyShopInfo
} = require("armyShopState.nut")
local mkShopItemPrice = require("mkShopItemPrice.nut")
local buyShopItem = require("buyShopItem.nut")
local { markShopItemSeen } = require("enlisted/enlist/shop/unseenShopItems.nut")
local { getCrateContentComp } = require("enlisted/enlist/soldiers/model/cratesContent.nut")
local { allItemTemplates } = require("enlisted/enlist/soldiers/model/all_items_templates.nut")
local { itemWeights, mkShopItem } = require("enlisted/enlist/soldiers/model/items_list_lib.nut")
local { getItemName } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local soldierItemTypeIcon = require("enlisted/enlist/soldiers/components/soldierItemTypeIcon.nut")
local { classIcon, className } = require("enlisted/enlist/soldiers/components/soldiersUiComps.nut")
local premiumWnd = require("enlisted/enlist/currency/premiumWnd.nut")
local textButtonTextCtor = require("enlist/components/textButtonTextCtor.nut")
local { sendBigQueryUIEvent } = require("enlist/bigQueryEvents.nut")
local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local { premiumImage } = require("enlisted/enlist/currency/premiumComp.nut")

const SHOP_CONTAINER_WIDTH = 120 // sh
const CARD_MAX_WIDTH       = 80  // sh
const CARD_MAX_RATIO       = 2.2
const CARD_DEFAULT_HEIGHT  = 40  // sh

local shopGroupItemsChain = persist("shopGroupItemsChain", @() Watched([]))
curArmy.subscribe(@(v) shopGroupItemsChain([]))
curSection.subscribe(@(v) shopGroupItemsChain([]))

local purchaseIsPossible = Watched(purchaseInProgress.value == null)
purchaseInProgress.subscribe(function(v){
  if (v != null)
    purchaseIsPossible(false)
  else
    ::gui_scene.setTimeout(1, @() purchaseIsPossible(true))
})

local curGroup = ::Computed(@() shopGroupItemsChain.value?[shopGroupItemsChain.value.len() - 1])

local curGroupLines = ::Computed(function() {
  local offerContainer = curGroup.value?.offerContainer ?? ""
  return curArmyShopLines.value
    .map(@(line) line.filter(@(shopItem) shopItem?.offerGroup == offerContainer))
})

local hoverBox = @(sf) {
  size = flex()
  rendObj = ROBJ_BOX
  borderWidth = sf & S_HOVER ? hdpx(4) : hdpx(1)
  borderColor = colors.borderColor(sf, false)
}

local mkShopItemImg = @(img, override = {}) (img ?? "").len() > 0
  ? {
      rendObj = ROBJ_IMAGE
      size = flex()
      keepAspect = true
      image = ::Picture(img)
    }.__update(override)
  : null

local mkPurchaseSpinner = @(shopItem) @() {
  watch = purchaseInProgress
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = purchaseInProgress.value == shopItem ? spinner : null
}

local bottomBlock = function(shopItem) {
  local itemName = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = [flex(), SIZE_TO_CONTENT]
    text = ::loc(shopItem.nameLocId)
    font = Fonts.medium_text
    halign = ALIGN_CENTER
  }
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = ::sh(10)
    vplace = ALIGN_BOTTOM
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = bigPadding
    color = defBgColor
    children = (shopItem?.offerContainer ?? "").len() > 0
      ? itemName
      : [
          itemName
          mkShopItemPrice(shopItem)
        ]
  }
}

local mkItemRow = @(item) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = ::hdpx(5)
  children = [
    soldierItemTypeIcon({ itemType = item?.itemtype })
    txt({ text = getItemName(item) })
  ]
}

local itemsSort = @(a, b) (itemWeights?[b?.itemtype] ?? 0) <=> (itemWeights?[a?.itemtype] ?? 0)
  || (b?.tier ?? 0) <=> (a?.tier ?? 0)
  || (a?.basetpl ?? "") <=> (b?.basetpl ?? "")

local function mkCrateItemsInfo(armyId, content, header = ::loc("crateContentHeader"), addChild = null) {
  local contentItems = content?.items ?? []
  if (contentItems.len() == 0)
    return null
  return function() {
    local templates = allItemTemplates.value?[armyId]
    local hasParts = false
    local items = contentItems.map(function(tplId) {
      local tpl = templates?[tplId]
      if (tpl?.itemtype == "itemparts") {
        hasParts = true
        return null
      }
      return tpl == null ? null : mkShopItem(tplId, tpl, armyId)
    })
      .filter(@(i) i != null)
      .sort(itemsSort)

    return {
      watch = allItemTemplates
      flow = FLOW_VERTICAL
      children = [ txt({ text = header, color = activeTxtColor }) ]
        .extend(items.map(mkItemRow))
        .append(hasParts
          ? {
              flow = FLOW_HORIZONTAL
              valign = ALIGN_CENTER
              gap = ::hdpx(5)
              children = [
                soldierItemTypeIcon({ itemType = "itemparts" })
                txt(::loc("weaponsItemParts"))
              ]
            }
          : null, addChild)
    }
  }
}

local function mkCrateShuffleInfo(armyId, content) {
  local mainItemsData = (content?.mainItemsData ?? {}).filter(@(d) (d?.shuffleMax ?? 0) > 0)
  if (mainItemsData.len() == 0)
    return null

  local isOpenedOnce = content.openingsCount > 0
  local children = mainItemsData.values()
    .map(@(data) mkCrateItemsInfo(armyId, data, ::loc("shop/guaranteedContent", data),
      isOpenedOnce ? txt({ text = ::loc("shop/alreadyReceived", data), color = activeTxtColor }) : null))
  if (isOpenedOnce)
    children.append(txt({ text = ::loc("shop/totalOpened", content), color = activeTxtColor }))
  return {
    gap = bigPadding
    flow = FLOW_VERTICAL
    children
  }
}

local mkSClassRow = @(sClass) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = ::hdpx(5)
  children = [
    classIcon(sClass, hdpx(22), 0)
    className(sClass, 0)
  ]
}

local function mkCrateSoldiersInfo(content) {
  local contentClasses = content?.soldierClasses ?? []
  if (contentClasses.len() == 0)
    return null

  local sClasses = contentClasses.map(function(sClass) {
    local locId = soldierClasses?[sClass].locId
    return locId == null ? null
      : {
          sClass = sClass
          sortLoc = utf8ToLower(::loc(locId))
        }
  })
    .filter(@(s) s != null)
    .sort(@(a, b) a.sortLoc <=> b.sortLoc)
    .map(@(s) s.sClass)

  local { soldierTierMin, soldierTierMax } = content
  local tiersText = soldierTierMin == soldierTierMax ? getRomanNumeral(soldierTierMin)
    : $"{getRomanNumeral(soldierTierMin)}-{getRomanNumeral(soldierTierMax)}"
  return {
    flow = FLOW_VERTICAL
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = defTxtColor
        text = ::loc("crateContentSoldiers", { tiers = colorize(soldierLvlColor, tiersText) })
      }
    ]
      .extend(sClasses.map(mkSClassRow))
  }
}

local function makeToolTip(shopItem) {
  local crateId = shopItem?.crateId ?? ""
  if (crateId == "")
    return null
  local crateContent = getCrateContentComp(shopItem.armyId, crateId)
  return tooltipBox(@() {
    watch = crateContent
    gap = bigPadding
    flow = FLOW_VERTICAL
    children = crateContent.value == null ? spinner
      : [
          mkCrateItemsInfo(shopItem.armyId, crateContent.value)
          mkCrateShuffleInfo(shopItem.armyId, crateContent.value)
          mkCrateSoldiersInfo(crateContent.value)
        ]
  })
}

local function activatePremiumText(sf) {
  local bonus = gameProfile.value?.premiumBonuses.soldiersReserve ?? 0
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = [hdpx(8), hdpx(20), hdpx(8), hdpx(50)]
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_DTEXT
        color = colors.textColor(sf, false, colors.TextActive)
        font = Fonts.big_text
        text = ::loc("btn/reserveSize", {addSize = bonus})
      }
      premiumImage(::hdpx(30))
    ]
  }
}

local activatePremiumBttn = {
  customStyle = {
    textCtor = function(textComp, params, handler, group, sf) {
      textComp = activatePremiumText(sf)
      params = { font = Fonts.big_text }
      return textButtonTextCtor(textComp, params, handler, group, sf)
    }
  }
  action = function() {
    premiumWnd()
    sendBigQueryUIEvent("open_premium_window", "army_shop", "reserve_full_message")
  }
}

local function mkShopSlot(shopItem, config = {}) {
  local stateFlags = ::Watched(0)
  local isGroupContainer = (shopItem?.offerContainer ?? "").len() > 0

  return function () {
    local sf = stateFlags.value
    local hasUnseenSignal = shopItem.offerContainer == ""
      ? curUnseenAvailableShopItems.value.findindex(@(i) i == shopItem) != null
      : curUnseenAvailableShopGroups.value.findindex(@(i) i == shopItem) != null
    return {
      watch = [stateFlags, curUnseenAvailableShopItems, curUnseenAvailableShopGroups]
      size = flex()
      halign = ALIGN_CENTER
      behavior = Behaviors.Button
      onElemState = @(newSF) stateFlags(newSF)
      onHover = function(on) {
        tooltip.state(on ? makeToolTip(shopItem) : null)
        if (!isGroupContainer && hasUnseenSignal)
          hoverHoldAction("unseenShop", shopItem.guid, @(guid) markShopItemSeen(guid))(on)
      }
      function onClick() {
        if (isGroupContainer)
          shopGroupItemsChain(@(v) v.append(shopItem))
        else if (purchaseIsPossible.value)
          buyShopItem(shopItem,
            mkShopItemImg(shopItem.image, {
              size = [sh(30), sh(30)]
            }),
            activatePremiumBttn)
      }
      clipChildren = true
      children = {
        rendObj = ROBJ_SOLID
        size = flex()
        maxWidth = ::sh((config?.height ?? 0) > 0 ? config.height * CARD_MAX_RATIO : CARD_MAX_WIDTH)
        color = defBgColor
        children = [
          mkShopItemImg(shopItem.image, {
            keepAspect = KEEP_ASPECT_FILL
            imageHalign = ALIGN_CENTER
            imageValign = ALIGN_TOP
          })
          bottomBlock(shopItem)
          mkPurchaseSpinner(shopItem)
          hoverBox(sf)
          hasUnseenSignal ? unseenSignal() : null
        ]
      }
    }
  }
}

local repeatLast = @(arr, idx) (arr?.len() ?? 0) == 0 ? null
  : arr[min(idx, arr.len() - 1)]

local function mkShopLine(line, config = {}) {
  local count = (line ?? []).len()
  if (count == 0)
    return null

  return {
    size = [flex(), ::sh(config?.height ?? CARD_DEFAULT_HEIGHT)]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = line.map(@(shopItem) mkShopSlot(shopItem, config))
  }
}

local function shopContentUi() {
  local sConfig = shopConfig.value
  local allLines = curGroupLines.value
  local res = {
    watch = [curGroup, curGroupLines, shopConfig, safeAreaSize]
    valign = ALIGN_CENTER
  }
  if (allLines.len() == 0)
    return res

  local curGroupV = curGroup.value ?? {}
  local rowsHeight = curGroupV?.rowsHeight ?? sConfig?.rowsHeight
  local shopWidth = ::min(
    sh(sConfig?.container.widthScale ?? SHOP_CONTAINER_WIDTH),
    safeAreaSize.value[0]
  )
  return res.__update({
    size = [SIZE_TO_CONTENT, flex()]
    children = makeVertScroll({
      size = [shopWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = bigPadding
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = allLines.map(@(line, idx) mkShopLine(line, curGroupV.__merge({
        height = repeatLast(rowsHeight, idx)
      })))
    }, scrollbarParams)
  })
}

local function moveToGroup(groupId) {
  if (groupId == null) {
    shopGroupItemsChain([])
    return
  }

  local chain = shopGroupItemsChain.value
  local groupIdx = chain.findindex(@(v) v?.offerContainer == groupId)
  if (groupIdx != null)
    shopGroupItemsChain(chain.slice(0, groupIdx + 1))
}

local mkGroupBtn = @(groupItem, isLast, hasHotkey) isLast
  ? txt({
      text = ::loc(groupItem?.nameLocId)
      font = Fonts.medium_text
      margin = sh(1)
      color = titleTxtColor
    })
  : Transp(::loc(groupItem?.nameLocId ?? "shopMainMenu"),
    @() moveToGroup(groupItem?.offerContainer),
    {
      margin = 0
      textMargin = sh(1)
      borderWidth = [0,0,::hdpx(1),0]
      hotkeys = !hasHotkey ? null
        : [["^{0} | Esc".subst(JB.B), {
            action = @() moveToGroup(groupItem?.offerContainer)
            description = { skip = true }
          }]]
    })

local rightArrow = txt({
  text = fa["caret-right"]
  font = Fonts.fontawesome
  padding = sh(1)
})

local groupsChainUi = function() {
  local groupsChain = shopGroupItemsChain.value
  local gChainLen = groupsChain.len()
  local chainChildren = []
  if (gChainLen > 0)
    chainChildren.append(mkGroupBtn(null, false, gChainLen == 1))
      .extend(groupsChain.map(@(v, idx)
        mkGroupBtn(v, idx == gChainLen - 1, idx == gChainLen - 2)))

  return {
    watch = shopGroupItemsChain
    flow = FLOW_HORIZONTAL
    gap = rightArrow
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = chainChildren
  }
}

local msg = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  font = Fonts.medium_text
  color = Color(180,180,180)
  halign = ALIGN_CENTER
  text = text
}

local noGoodsMessageUi = {
  size = [sh(80), SIZE_TO_CONTENT]
  pos = [0, -sh(5)]
  padding = sh(5)
  rendObj = ROBJ_SOLID
  color = defBgColor
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    msg(::loc("menu/enlistedShopDesc"))
    @() {
      size = [flex(), SIZE_TO_CONTENT]
      watch = curArmyShopInfo
      children = curArmyShopInfo.value.unlockLevel <= 0 ? null
        : msg(::loc("shop/unlockByArmyLevel", curArmyShopInfo.value))
    }
  ]
}

local hasContent = Computed(@() curArmyShopLines.value.len() > 0)
local mainContent = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = [
        armySelect()
        groupsChainUi
      ]
    }
    @() {
      watch = hasContent
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = hasContent.value ? shopContentUi
        : noGoodsMessageUi
    }
  ]
}

return {
  size = flex()
  halign = ALIGN_RIGHT
  children = [
    mainContent
    campaignTitle
  ]
}
 