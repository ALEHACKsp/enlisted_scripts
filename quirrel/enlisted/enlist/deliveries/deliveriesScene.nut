local metalink = require("enlisted/enlist/meta/metalink.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local {secondsToStringLoc} = require("utils/time.nut")
local JB = require("ui/control/gui_buttons.nut")
local {safeAreaSize, safeAreaBorders} = require("enlist/options/safeAreaState.nut")
local { sceneWithCameraAdd, sceneWithCameraRemove } = require("enlisted/enlist/sceneWithCamera.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")
local {txt} = require("enlisted/enlist/components/defcomps.nut")
local textButton = require("enlist/components/textButton.nut")
local viewConst = require("enlisted/enlist/viewConst.nut")
local mkSoldierCard = require("enlisted/enlist/soldiers/mkSoldierCard.nut")
local mkItemWithMods = require("enlisted/enlist/soldiers/mkItemWithMods.nut")
local { collectSoldierData } = require("enlisted/enlist/soldiers/model/collectSoldierData.nut")
local { squadsCfgById } = require("enlisted/enlist/soldiers/model/config/squadsConfig.nut")
local {
  getItemIndex, curArmy
} = require("enlisted/enlist/soldiers/model/state.nut")
local {
  allItemTemplates, findItemTemplateByItemInfo
} = require("enlisted/enlist/soldiers/model/all_items_templates.nut")
local {
  sceneParams, openDelivery, purchaseDelivery, requestDelivery,
  curArmySoldiersDeliveries, curArmyDailyDeliveries,
  curArmySoldiersDelivery, curArmyDailyDelivery,
  curArmyDailyDeliveriesRefreshTime,
  freeDeliveriesPurchaseTime
} = require("deliveriesState.nut")
local {cratesContent} = require("enlisted/enlist/meta/profile.nut")

local COLUMNS = 6

local {bigPadding, slotBaseSize} = viewConst
local borders = safeAreaBorders.value
local screenWidth = safeAreaSize.value[0]
local infoBlockWidth = (2 * slotBaseSize[0] + bigPadding).tointeger()
local listContentWidth = ::max(((screenWidth - infoBlockWidth) * 0.7).tointeger(), sh(65))
local slotSize = ((listContentWidth - (COLUMNS - 1) * bigPadding) / COLUMNS).tointeger()
local slotIndexSize = (slotSize * 0.24).tointeger()

local indexAnimations = {animations = [{
  prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1, play = true, loop = true, easing = Blink
}]}

local curDeliveries = ::Computed(@() sceneParams.value?.category == "soldiers"
  ? curArmySoldiersDeliveries.value : curArmyDailyDeliveries.value)

local curDelivery = ::Computed(@() sceneParams.value?.category == "soldiers"
  ? curArmySoldiersDelivery.value : curArmyDailyDelivery.value)

local curContent = ::Computed(function() {
  local res = { soldiers = [], items = [] }
  local dGuid = curDelivery.value?.guid
  if (dGuid == null)
    return res

  local content = cratesContent.value?["content_data"] ?? {}
  foreach (soldier in content?.soldiers ?? {})
    if (metalink.getLinksByType(soldier, "delivery")?[0] == dGuid)
      res.soldiers.append(soldier)
  foreach (item in content?.items ?? {})
    if (metalink.getLinksByType(item, "delivery")?[0] == dGuid &&
        !metalink.isObjLinkedToAnyOfObjects(item, content?.soldiers ?? {}) &&
        !metalink.isObjLinkedToAnyOfObjects(item, content?.items ?? {}))
      res.items.append(item)

  return res
})

local refreshTime = Watched(-1)
local freePurchaseTime = Watched(-1)

local function close() {
  sceneParams(null)
}

local mkDeliveryImg = @(hasOpened) {
  rendObj = ROBJ_IMAGE
  size = flex()
  margin = bigPadding
  keepAspect = true
  image = ::Picture("!ui/uiskin/deliveries/{0}.png"
    .subst(hasOpened ? "delivery_opened" : "delivery"))
}

local mkDeliveryIndex = @(orderNumber, isSelected) {
  rendObj = ROBJ_SOLID
  size = [slotIndexSize, slotIndexSize]
  halign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  color = Color(0,0,0)
  children = txt(orderNumber.tostring())
    .__update({
      font = Fonts.small_text
      key = "{0}{1}".subst(orderNumber, isSelected ? "1" : "0")
    })
    .__update(isSelected ? indexAnimations : {})
}

local function mkDeliverySlot(delivery) {
  if (delivery == null)
    return null

  local isSelected = delivery.guid == curDelivery.value?.guid
  local hasOpened = delivery.hasOpened
  local hasReceived = delivery.hasReceived
  local orderNumber = getItemIndex(delivery) + 1
  return {
    rendObj = ROBJ_SOLID
    size = [slotSize, slotSize]
    color = isSelected ? viewConst.defPanelBgColorVer_1 : viewConst.airBgColor
    opacity = hasReceived ? 0.7 : 1
    children = [
      mkDeliveryImg(hasOpened)
      mkDeliveryIndex(orderNumber, isSelected)
    ]
  }
}


local function deliveryRefreshTimerComp() {
  local rTime = refreshTime.value ?? -1
  if (rTime <= 0)
    return null

  return @() {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = [
      txt({
        text = ::loc("delivery/timerHeader")
        font = Fonts.small_text
        color = viewConst.activeTxtColor
      })
      @() {
        watch = refreshTime
        flow = FLOW_HORIZONTAL
        gap = viewConst.gap
        children = refreshTime.value > 0
          ? [
              txt({
                rendObj = ROBJ_STEXT
                text = fa["clock-o"]
                font = Fonts.fontawesome
              })
              {
                rendObj = ROBJ_DTEXT
                font = Fonts.small_text
                text = secondsToStringLoc(rTime)
              }
            ]
          : null
      }
    ]
  }
}

local deliveryListHeader = @() {
  watch = refreshTime
  size = [listContentWidth, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    txt({
      text = ::loc("delivery/header_soldiers")
      font = Fonts.big_text
      color = viewConst.activeTxtColor
    })
    deliveryRefreshTimerComp()
  ]
}

local deliveryListBlock = @() {
  watch = [curDeliveries, curDelivery]
  size = flex()
  flow = FLOW_VERTICAL
  gap = 3 * bigPadding
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    deliveryListHeader
    wrap(curDeliveries.value.map(@(delivery) mkDeliverySlot(delivery)),
      {
        width = listContentWidth,
        hGap = viewConst.bigPadding,
        vGap = viewConst.bigPadding
      })
    textButton.Flat(::loc("Back"), close, {
      margin = 0
      minWidth = listContentWidth / 2
      hotkeys = [["^Esc | {0}".subst(JB.B), {description=::loc("Close")}]]
    })
  ]
}

local currencyBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  padding = bigPadding
  halign = ALIGN_RIGHT
  children = txt({ text = ::loc("Currency info"), font = Fonts.medium_text })
}

local btnStyle = {
  margin = 0
  size = [flex(), SIZE_TO_CONTENT]
}

local curPriceBlock = @() txt("${0}".subst(curDelivery.value?.cost ?? 0))
  .__update({
    font = Fonts.medium_text
    color = viewConst.selectedTxtColor
  })

local openBtn = textButton.PrimaryFlat(::loc("delivery/open"), function() {
  openDelivery(curDelivery.value?.guid)
}, btnStyle)

local purchaseBtn = @(isFree) textButton.Purchase(::loc("delivery/purchase"),
  function() {
    purchaseDelivery(curDelivery.value?.guid,
      isFree ? 0 : (curDelivery.value?.cost ?? 0))
  },
  textButton.onlinePurchaseStyle.__merge(btnStyle).__merge({
    textMargin = [sh(1), 0]
    textCtor = @(textField, params, handler, group, sf) {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = [0, sh(3)]
      gap = sh(1)
      children = [
        textField
        isFree ? null : curPriceBlock()
      ]
    }
  })
)

local mkPurchaseBtn = @() {
  watch = freePurchaseTime
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  children = [
    purchaseBtn(freePurchaseTime.value == 0)
    freePurchaseTime.value == 0 ? unseenSignal(0.8) : null
  ]
}

local mkSelDeliveryBtn = @(delivery) !delivery.hasOpened ? openBtn
  : !delivery.hasReceived ? mkPurchaseBtn
  : null

local selDeliveryContentBlock = @() {
  watch = [curContent, squadsCfgById]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  halign = ALIGN_CENTER
  children = [
    txt({
      text = ::loc("delivery/contain_soldiers")
      font = Fonts.big_text
      margin = [bigPadding, 0]
    })
    wrap(curContent.value.soldiers.map(
      function(soldier, idx) {
        local sInfo = collectSoldierData(soldier)
        return mkSoldierCard({
          idx = idx
          soldierInfo = sInfo
          squadInfo = squadsCfgById.value?[sInfo?.armyId ?? ""][sInfo?.squadId ?? ""]
          sf = 0
        })
      }),
      {
        width = infoBlockWidth
        hGap = bigPadding
        vGap = bigPadding
      }
    )
    wrap(curContent.value.items.map(
      @(item, idx) mkItemWithMods({
        item = findItemTemplateByItemInfo(allItemTemplates, item)?.__merge?(item)
        itemSize = slotBaseSize
        isInteractive = false
      })),
      {
        width = infoBlockWidth
        hGap = bigPadding
        vGap = bigPadding
      }
    )
  ]
}

local function mkFreePurchaseTimer() {
  local timerChildren = @() freePurchaseTime.value > 0
    ? [
        txt({ text = "freeDeliveryText", font = Fonts.small_text })
        txt({ text = fa["clock-o"], font = Fonts.fontawesome, rendObj = ROBJ_STEXT })
        txt({
          text = secondsToStringLoc(freePurchaseTime.value)
          font = Fonts.medium_text
          color = viewConst.activeTxtColor
        })
      ]
    : null

  return {
    watch = freePurchaseTime
    flow = FLOW_HORIZONTAL
    gap = viewConst.gap
    valign = ALIGN_CENTER
    children = timerChildren()
  }
}

local function selDeliveryInfoBlock() {
  local function content() {
    local cDelivery = curDelivery.value
    local category = sceneParams.value.category
    if (cDelivery == null)
      return [
        txt({
          text = ::loc("mainmenu/congratulations")
          font = Fonts.big_text
        })
        txt({
          text = ::loc($"delivery/complete_{category}")
          font = Fonts.big_text
          margin = [0, 0, hdpx(30), 0]
        })
        textButton.PrimaryFlat(::loc("delivery/request"), function() {
          requestDelivery(curArmy.value, category)
        }, btnStyle)
      ]

    return [
      {
        size = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          txt({ text = ::loc($"delivery/next_{category}"), font = Fonts.big_text })
          mkDeliveryIndex(getItemIndex(cDelivery) + 1, true)
        ]
      }
      {
        size = [pw(50), pw(50)]
        children = mkDeliveryImg(cDelivery.hasOpened)
      }
      cDelivery.hasOpened ? selDeliveryContentBlock : null
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        margin = [bigPadding, 0]
        halign = ALIGN_CENTER
        children = [
          mkSelDeliveryBtn(cDelivery)
          mkFreePurchaseTimer
        ]
      }
    ]
  }

  return @() {
    watch = curDelivery
    size = flex()
    flow = FLOW_VERTICAL
    gap = viewConst.gap
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = content()
  }
}

local deliveryInfoBlock = @() {
  size = [infoBlockWidth, flex()]
  flow = FLOW_VERTICAL
  children = [
    currencyBlock
    selDeliveryInfoBlock()
  ]
}


local mainScene = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = [sw(100), sh(100)]
  flow = FLOW_HORIZONTAL
  color = viewConst.blurBgColorVer_1
  fillColor = viewConst.blurBgFillColor
  children = [
    deliveryListBlock
    {
      rendObj = ROBJ_SOLID
      size = [SIZE_TO_CONTENT, flex()]
      padding = borders
      color = viewConst.defPanelBgColorVer_1
      children = deliveryInfoBlock
    }
  ]
}

local function openScene() {
  refreshTime = sceneParams.value?.category == "soldiers"
    ? Watched(-1) : curArmyDailyDeliveriesRefreshTime

  freePurchaseTime = sceneParams.value?.category == "soldiers"
    ? Watched(-1) : freeDeliveriesPurchaseTime

  sceneWithCameraAdd(mainScene, "armory")
}

if (sceneParams.value != null)
  openScene()

sceneParams.subscribe(function(v) {
  if (v != null)
    openScene()
  else
    sceneWithCameraRemove(mainScene)
})

return null
 