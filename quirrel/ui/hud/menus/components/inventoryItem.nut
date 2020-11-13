local {install_item_on_weap_by_eid, pickup_item_entity, drop_item, use_item} = require("humaninv")
local fa = require("daRg/components/fontawesome.map.nut")
local {secondsToString} = require("utils/time.nut")
local colors = require("ui/style/colors.nut")
local {inventoryItemImage} = require("inventoryItemImages.nut")
local {weaponTypeIconColor,itemHeight} = require("inventoryStyle.nut")
local { focusedData, draggedData, doForAllEidsWhenShift } = require("ui/hud/state/inventory_state.nut")
local cursors = require("ui/style/cursors.nut")
local {weaponsList} = require("ui/hud/state/hero_state.nut")
local {capacityVolume, carriedVolume, canPickupItems} = require("ui/hud/state/inventory_items_es.nut")
local {entityToUse, itemUseProgress} = require("ui/hud/state/entity_use_state.nut")
local {controlledHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {GROUND, INVENTORY} = require("inventoryItemTypes.nut")
local {mkWeaponTypeIco} = require("ui/hud/components/itemWeaponTypeIcon.nut")
local {mkCountdownTimerPerSec} = require("ui/helpers/timers.nut")
local remap_nick = require("globals/remap_nick.nut")

//!!!COLOR BELOW ARE CHECKED TO BE REASONABLE PALETTE FOR COLORBLIND PEOPLE
local itemUsableColor = Color(80,200,0,255)
local itemUsefulColor = Color(138,43,226,255)
local itemPotentUsefulColor = Color(70,70,70,255)
local itemBorderHoverColor = Color(80,60,10,30)
local itemFillColorActive = Color(20,20,20,205)
local itemFillColorHovered = Color(70,70,70,210)
local itemFillColorDef = Color(40,40,40,210)
local itemTxtColorNotAllowed = Color(175,80,80)
local itemImageBkg = Color(14,14,14,0)
//!!!COLOR ABOVE ARE CHECKED TO BE REASONABLE FOR COLORBLIND PPL


local function isWeaponModsForItem(item, weaponMods){
  return (weaponMods ?? {})
    .filter(@(modSlot, modSlotName) item?.weapModSlotName == modSlotName && modSlot.array_tags.indexof(item?.weapModTag) != null)
    .len()>0
}
local function getWeaponsWithSuitableMods(weapons, item){
  return weapons.filter(@(weapon) weapon?.mods!=null && isWeaponModsForItem(item, weapon.mods) && (item?.currentWeaponSlotName != weapon.currentWeaponSlotName))
}
local function mkTryUseMod(item, secondUse=false){
  if (!item || !item?.weapModSlotName)
    return null
  local weaponsWithSuitableMods = getWeaponsWithSuitableMods(weaponsList.value, item)
  if (weaponsWithSuitableMods.len() == 0 || (weaponsWithSuitableMods.len()<2 && secondUse))
    return null
  return function() {
    if (item?.fromList == GROUND || item?.fromList == INVENTORY) {
      if (secondUse)
        weaponsWithSuitableMods = weaponsWithSuitableMods.reverse()
      foreach (weapon in weaponsWithSuitableMods) {
        if (!weapon.mods[item.weapModSlotName]?.itemPropsId){
          install_item_on_weap_by_eid(item.eid, weapon.currentWeaponSlotName, item.weapModSlotName)
          return
        }
      }
      // Every suitable weapon already has a mod in this slot. Mount on the first one.
      install_item_on_weap_by_eid(item.eid, weaponsWithSuitableMods[0].currentWeaponSlotName, item.weapModSlotName)
    }
  }
}
local mkTrySecondUseMod = @(item) mkTryUseMod(item, true)

local shadow = {rendObj=ROBJ_SOLID size = [flex(),hdpx(2)] vplace=ALIGN_BOTTOM pos=[0,hdpx(2)] color=Color(0,0,0,60)}

local function textColor(sf) {
  if (sf & S_HOVER)
    return Color(255, 255, 255, 255)
  return Color(200, 200, 200, 255)
}

local weaponIconHeight = ::hdpx(20)
local function itemComp(stateFlags, item, height, group, list_type=null) {
  return function(){
    local canTake = (list_type != GROUND)
                    || (canPickupItems.value && (item?.volume ?? 0) + carriedVolume.value <= capacityVolume.value)
    local sf = stateFlags.value

    local usefullnessColor  = item?.isUsable ? itemUsableColor
      : item?.isUseful ? itemUsefulColor
      : (item.isEquipment && !item.isPotentiallyUseful && !item.isUseful) ? itemPotentUsefulColor
      : 0
    local isHovered = (sf & (S_HOVER | S_DRAG)) > 0
    local weapTypeIco = mkWeaponTypeIco(item?.weapType, weaponIconHeight)
    if (weapTypeIco != null) {
      weapTypeIco = {
        size = [weaponIconHeight, weaponIconHeight]
        color = weaponTypeIconColor
        rendObj = ROBJ_IMAGE
        image = weapTypeIco
      }
    }
    local itemCount = (item?.count ?? 0).tointeger()

    return {
      size = [flex(),height]
      rendObj = ROBJ_BOX
      valign = ALIGN_CENTER
      fillColor = (sf & S_ACTIVE)
        ? itemFillColorActive
        : isHovered
          ? itemFillColorHovered
          : itemFillColorDef
      borderColor = isHovered ? itemBorderHoverColor : 0
      borderWidth = isHovered ? hdpx(1.0) : 0
      flow = FLOW_HORIZONTAL
      watch = [stateFlags, carriedVolume, capacityVolume, canPickupItems]

      padding = [0,hdpx(5),0,0]
      gap = hdpx(5) //should be font size
      children = [
        {
          size = [height, height]
          children = [
            {size = [hdpx(8)/2.5,height]  vplace = ALIGN_TOP hplace=ALIGN_LEFT rendObj = ROBJ_SOLID color=usefullnessColor}
            {rendObj=ROBJ_SOLID color = itemImageBkg size=[height,height]}
            inventoryItemImage(item)
          ]
        }
        weapTypeIco
        { //text
            size = [flex(), SIZE_TO_CONTENT]
            behavior = Behaviors.Marquee
            group = group
            scrollOnHover = true
            rendObj = ROBJ_DTEXT
            text = ::loc(item.desc, {count = item?.countPerItem,  nickname = remap_nick(item?.ownerNickname)})
            key = item.desc
            color = canTake ? textColor(sf) : itemTxtColorNotAllowed
        }
        itemCount > 1
          ? {
              rendObj = ROBJ_DTEXT
              size = SIZE_TO_CONTENT
              text = itemCount
            }
          : null
      ]
    }
  }
}


local itemAnims = [
  { prop=AnimProp.scale, from=[1,0.01], to=[1,1], duration=0.25, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.25, play=true, easing=OutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[1,0.01], duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]


local function mkItemLockComp(unlockTime) {
  local timeToUnlock = mkCountdownTimerPerSec(::Watched(unlockTime))
  return @(){
    watch = timeToUnlock
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_RIGHT
    children = timeToUnlock.value > 0
      ? [
          {
            rendObj = ROBJ_DTEXT
            color = colors.Inactive
            font = Fonts.small_text
            text = secondsToString(timeToUnlock.value)
          }
          {
            rendObj = ROBJ_STEXT
            color = colors.Inactive
            padding = hdpx(4)
            font = Fonts.fontawesome
            fontSize = hdpx(11)
            text = fa["lock"]
          }
        ]
      : null
  }
}

local function inventoryItem(params = {}) {
  local isDragged = ::Watched(false)
  local function dragMode(on, item) {
    draggedData.update(on ? item : null)
    isDragged.update(on)
  }

  local item = params?.item
  local list_type = params?.list_type
  //should be button with text of item name and right click for use (and left for drag-n-drop or move to myitems)
  local stateFlags = ::Watched(0)
  local group = ::ElemGroup()

  local tryTake = (item?.canTake && item?.eid) ? @() doForAllEidsWhenShift(item, pickup_item_entity) : null
  local tryDrop = (item?.canDrop && item?.eid) ? @() doForAllEidsWhenShift(item, drop_item) : null
  local contextItem = item.__merge({fromList=list_type})
  if (contextItem?.isUsable)
    contextItem.onUse <- @() use_item(controlledHeroEid.value, contextItem?.eid ?? INVALID_ENTITY_ID, controlledHeroEid.value)
  else {
    contextItem.onUse <- mkTryUseMod(contextItem)
    contextItem.onSecondUse <- mkTrySecondUseMod(contextItem)
  }
  local tryUse = contextItem.onUse
  local rmbAction = tryTake ?? tryDrop
  local mmbAction = tryUse
  local lmbAction = tryUse ?? tryTake
  local mouseDoubleLMBAction = tryUse ?? tryTake ?? tryDrop

  local hasLockTimer = (item?.unlockTime ?? 0)> 0
  local function onClickAction(event) {
    if (event.button == 0) {
      lmbAction?()
    }
    if (event.button == 1) {
      rmbAction?()
    }
    if (event.button == 2) {
      tryUse?()
    }
  }

  local function doubleAction(event) {
    if (event.button == 0) {
      mouseDoubleLMBAction?()
    }
  }
  local descLoc = ::loc("{0}/desc".subst(contextItem?.desc ?? ""), "") ?? ""

  local mkClick = @(action)
    action == null ? null
      : action == tryTake ? "item/action/take"
      : action == tryUse ? "item/action/use"
      : action == tryDrop ? "item/action/drop"
      : null

  contextItem = contextItem.__merge({
    LMB = mkClick(lmbAction),
    RMB = mkClick(rmbAction),
    MMB = mkClick(mmbAction),
  })

  local function onHover(on) {
    focusedData.update(on ? contextItem : null)
    cursors.tooltip.state(on && descLoc != "" ? descLoc : null)
  }

  local uniqueKey = "".concat((item?.eid ?? item?.id ?? item?.desc), "x", (item?.count ?? 0), (item?.countPerItem ?? 0))
  local function itemUseProgressComp(){
    local itemUseProgressVal = 0.0
    if (entityToUse.value == item.eid)
      itemUseProgressVal = clamp(itemUseProgress.value.tointeger(), 0, 100)
    return {
      size = [pw(itemUseProgressVal), itemHeight/10.0 ]
      rendObj=ROBJ_SOLID color=Color(100,120,90,40)
      vplace = ALIGN_BOTTOM
      margin = sh(0.1)
      watch = [itemUseProgress, entityToUse, weaponsList]
    }
  }
  local xmbNode = ::XmbNode()

  return function() {
    return {
      key = uniqueKey
      size = [flex(), itemHeight]
      watch = [isDragged]

      function onElemState(sf) {
        stateFlags.update(sf)
      }

      behavior = Behaviors.DragAndDrop
      group = group
      sound = {
        click  = "ui/button_click_inactive"
        hover  = "ui/menu_highlight"
      }
      xmbNode = xmbNode
      onHover = onHover
      dropData = contextItem
      onDragMode = dragMode
      dragMouseButton = 0
      onDoubleClick = doubleAction
      onClick = onClickAction
      transform = {
        pivot = [0, 0.2]
      }
      children = [
        itemComp(stateFlags, item, itemHeight, group, list_type)
        hasLockTimer ? mkItemLockComp(item.unlockTime) : null
        itemUseProgressComp
        !isDragged.value ? shadow : null
      ]
      animations = itemAnims
    }
  }
}

return inventoryItem
 