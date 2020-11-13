local heroState = require("ui/hud/state/hero_state.nut")
local scrollbar = require("ui/components/scrollbar.nut")
local cursors = require("ui/style/cursors.nut")
local fontIconButton = require("enlist/components/fontIconButton.nut")
local dropMarker = require("components/dropMarker.nut")
local paperdoll = require("components/inventoryPaperdoll.nut")
local inventoryItem = require("components/inventoryItem.nut")
local inventoryWeapon = require("components/inventoryWeapon.nut")
local {GROUND, INVENTORY} = require("components/inventoryItemTypes.nut")
local JB = require("ui/control/gui_buttons.nut")
local {isAlive} = require("ui/hud/state/hero_state_es.nut")
local {teammatesAliveNum} = require("ui/hud/state/human_teammates.nut")
local {sendQuickChatItemMsg} = require("ui/hud/huds/send_quick_chat_msg.nut")
local {itemHeight} = require("components/inventoryStyle.nut")
local mkMouseHint = require("components/mkMouseHint.nut")
local {focusedItem, draggedData,requestData, requestItemData, isShiftPressed, doForAllEidsWhenShift }
  = require("ui/hud/state/inventory_state.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local {controlHudHint} = require("ui/hud/components/controlHudHint.nut")
local hotkeysPanelStateComps = require("ui/hotkeysPanelStateComps.nut")
local {drop_item, drop_gear_from_slot, drop_weap_from_slot, pickup_item_entity_to_weap, pickup_item_entity,
  swap_weap_in_slots, remove_item_from_weap_to_inventory, remove_item_from_weap_to_ground} = require("humaninv")
local {itemsAround, inventoryItems} = require("ui/hud/state/inventory_items_es.nut")
local {playerEvents} = require("ui/hud/state/eventlog.nut")
local {mkPlayerEvents} = require("ui/hud/components/mkPlayerEvents.nut")

const HUD_GAMEMENU_HOTKEY  = "HUD.GameMenu"

local showInventory = persist("showInventory", @() Watched(false))

local playerEventsRoot = @(){
  children = mkPlayerEvents(playerEvents.events)
  size = [sw(40), sh(10)]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL

  pos = [0, sh(28)]
  watch = playerEvents.events
}

//ItemType {
//  INVENTORY
//  GROUND
//}
/*todo:
  - tooltips with proper description in inventory
*/

local function teamRequest(requestDataStr) {
  sendQuickChatItemMsg(requestDataStr, requestItemData.value ?? "")
}

local function close() {
  showInventory.update(false)
}

isAlive.subscribe(function(v) {
  if(!v)
    close()
})

local weaponSlotAnims = [
  { prop=AnimProp.translate,from=[sh(50),0], to=[0,0], duration=0.3, play=true, easing=OutCubic }
  { prop=AnimProp.translate,from=[0,0], to=[sh(50),0], duration=0.3, playFadeOut=true, easing=OutCubic }
]

local function weaponSlotWidget(weapon, idx){
  local weaponWidget = inventoryWeapon(weapon, idx)

  local stateFlags = ::Watched(0)
  return function() {
    local function canDropDragged(item) {
      local itemEquipped = "currentWeaponSlotName" in item

      local alreadyEquippedInThisWeaponSlot = itemEquipped
        && item.currentWeaponSlotName == weapon.currentWeaponSlotName

      local weaponSlots = weapon?.validWeaponSlots
      local swapAvailable = !itemEquipped
        || weaponSlots == null
        || weaponSlots.indexof(item.currentWeaponSlotName) != null

      return "validWeaponSlots" in item
        && swapAvailable
        && item.validWeaponSlots.indexof(weapon.currentWeaponSlotName) != null
        && !alreadyEquippedInThisWeaponSlot
    }

    local needMark = draggedData && draggedData.value && canDropDragged(draggedData.value)
    local sf = stateFlags.value
    return {
      size=[flex(1),flex(2)]
      rendObj=ROBJ_BOX
      margin=[hdpx(6),0]
      fillColor=Color(0,0,0,50)
      borderWidth = 0
      transform = {}
      behavior = [Behaviors.DragAndDrop]
      watch = [draggedData, stateFlags]
      onElemState = function(val) {stateFlags.update(val)}
      skipDirPadNav = true
      canDrop = canDropDragged

      function onDrop(item) {
        if ("currentWeaponSlotName" in item)
          // already equipped in some weapon slot
          swap_weap_in_slots(item.currentWeaponSlotName, weapon.currentWeaponSlotName)
        else
          // probably got from items around
          pickup_item_entity_to_weap(item.eid, weapon.currentWeaponSlotName)
      }
      animations = weaponSlotAnims
      children = [weaponWidget, needMark ? dropMarker(sf) : null]
    }
  }
}

local function weapons() {
  local padding = {size=[flex(1),flex(1)] }

  // it seems that if the weapon slot is empty there's still a kind of null-weapon entity in it

  return {
    flow = FLOW_VERTICAL
    size = [flex(2),flex(2)]
    watch = heroState.weaponsList
    children = [padding]
                .extend(heroState.weaponsList.value.map(weaponSlotWidget))
                .append(padding)
  }
}

local function onDropItem(data, list_type=GROUND) {
  // this is an equipped gear item
  if (data?.currentEquipmentSlotName)
    drop_gear_from_slot(data.currentEquipmentSlotName)
  else if (data?.currentWeaponSlotName) {
    // this is an equipped weapon mod
    if (data?.currentWeapModSlotName) {
      if (list_type == INVENTORY)
        remove_item_from_weap_to_inventory(data.currentWeaponSlotName, data.currentWeapModSlotName)
      if (list_type == GROUND)
        remove_item_from_weap_to_ground(data.currentWeaponSlotName, data.currentWeapModSlotName)
    }
    // this is an equipped weapon (can't drop melee weapon)
    else if (data.currentWeaponSlotName != "melee")
      drop_weap_from_slot(data.currentWeaponSlotName)
  }
  // this item is not equipped (moving between inventory and the ground)
  else if (data?.canDrop && list_type == GROUND && data?.eid !=null)
    doForAllEidsWhenShift(data, drop_item)
  else if (data?.canTake && list_type == INVENTORY  && data?.eid !=null)
    doForAllEidsWhenShift(data, pickup_item_entity)
  if (list_type == INVENTORY && data?.onDropInInventory != null) {
    data?.onDropInInventory()
  }
}

local itemsListAnims = [
  { prop=AnimProp.translate,from=[-sh(50),0], to=[0,0], duration=0.3, play=true, easing=OutCubic }
  { prop=AnimProp.translate,from=[0,0], to=[-sh(50),0], duration=0.3, playFadeOut=true, easing=OutCubic }
]

local mkInventoryListHdr = ::memoize(@(list_type){
  rendObj = ROBJ_DTEXT
  text = (list_type == INVENTORY ? ::loc("inventory/myItems") : ::loc("inventory/itemsNearby"))
  margin=[0,hdpx(15)] size = [flex(), SIZE_TO_CONTENT]
  color = Color(96,96,96,96)
})

local itemsListGap = hdpx(5)
local dropItemsArea = {
  behavior = [Behaviors.DragAndDrop]
  onDrop = @(data) onDropItem(data, GROUND)
  canDrop = @(data) data && data?.canDrop
  size = flex()
  skipDirPadNav = true
}

local scrollHandlers = ::memoize(@(v) ::ScrollHandler())
local xmbContainers = ::memoize(@(v) ::XmbContainer({
    canFocus = @() false
    scrollSpeed = 5.0
    isViewport = true
  })
)
local function itemsList(items, can_drop_dragged, list_type) {
  local children = items.map( @(item) inventoryItem({item=item, list_type=list_type}) )
  local onDropItemFunc = @(data) onDropItem(data,list_type)
  local stateFlags = ::Watched(0)
  local hasItems = items.len() > 0
  return function() {
    return {
      size = flex()
      transform ={}
      xmbNode = xmbContainers(list_type)
      animations = itemsListAnims

      children = [
        {
          behavior = [Behaviors.DragAndDrop]
          canDrop = can_drop_dragged
          onDrop = onDropItemFunc
          onElemState=function(sf) {stateFlags.update(sf)}
          eventPassThrough=true
          size = flex()
        }
        {
          size=flex() flow = FLOW_VERTICAL gap = itemsListGap
          children = [
            mkInventoryListHdr(list_type)
            scrollbar.makeVertScroll({
              flow = FLOW_VERTICAL
              size = [flex(1),SIZE_TO_CONTENT]
              gap = itemsListGap
              children = children
            },
            {
              scrollHandler = scrollHandlers(list_type)
            })
          ]
        }
        @(){
          children = draggedData?.value
              && (!can_drop_dragged || can_drop_dragged(draggedData.value))
              && draggedData.value?.fromList != list_type
           ? dropMarker(stateFlags.value) : null
           size = flex()
           watch =  [draggedData, stateFlags]
           behavior = hasItems ? null : Behaviors.DragAndDrop
        }
      ]
    }
  }
}


local leftpadding = @() {
  size=[sw(5), flex()]
  watch = [draggedData]
  canDrop = @(data) data && data?.canDrop
  onDrop = onDropItem
  children = dropItemsArea
  skipDirPadNav = true
}

local rightpadding = {size=[sw(5), flex()] children = dropItemsArea}
local bottompadding = {size=[flex(),sh(9)] children = dropItemsArea}
local toppadding = bottompadding
local closebutton = fontIconButton("close", {
  onClick = close
  size = [sh(5),sh(5)]
  hplace = ALIGN_RIGHT
  pos = [-sh(10),sh(5)]
})


local function mkScore(item){
  return (item.baseScore + (item.isWeapon ? 200 : 0) + (item.isAmmo ? 150 : 0) + (item.isUseful ? 75 : 0)
    + (item.isPotentiallyUseful ? 50 : 0) + (item.isArmor ? -5 : 0) + (item.isUsable ? -10 : 0)
    + ((item.isEquipment && !item.isPotentiallyUseful && !item.isUseful) ? -100 : 0) - (item?.countPerItem ?? 0))*100
    + (item.desc.hash())%97 //to reduce resorting when equal score is gathered we use hash from string name
}

local function patchItemNearby(item) {
  return item == null ? null : item.__merge({canDrop = false, canTake = true, score = mkScore(item)})
}

local function patchItemInventory(item) {
  return item == null ? null : item.__merge({score = mkScore(item)})
}

local function canDragDropToInventory(item) {
  return item?.currentWeapModSlotName // <- this means that player is drag-n-dropping weapon mod from slot back to inventory
    || item?.onDropInInventory != null
    || (item?.canTake && !item?.isEquipment && !item?.isWeapon)
}

local function inventoryItemsComp() {
  local inventoryItemsVal = (inventoryItems.value ?? [])
    .map(patchItemInventory)
    .sort(@(a, b) b.score <=> a.score)
  local children = itemsList(inventoryItemsVal, canDragDropToInventory, INVENTORY)
  return {
    size = flex()
    watch = [inventoryItems, heroState.weaponsList]
    children = children
  }
}

local function findItemInListByKey(itemList, key, countPerItem) {
  foreach (idx, item in itemList)
    if (item.key == key && item.countPerItem == countPerItem)
      return item
  return null
}

local function mergeNonUniqueItems(nearbyItems) {
  local outputList = []
  foreach (item in nearbyItems) {
    local existItem = findItemInListByKey(outputList, item.key, item.countPerItem)
    if (existItem == null) {
      outputList.append(item)
      continue
    }
    existItem.count++
    existItem.eids.append(item.eid)
  }
  return outputList
}

local function nearbyItems() {
  local nearbyItemsVal = itemsAround.value ? itemsAround.value.map(patchItemNearby) : []
  nearbyItemsVal = mergeNonUniqueItems(nearbyItemsVal)
  nearbyItemsVal.sort(@(a, b) b.score <=> a.score)
  local children = itemsList(nearbyItemsVal, @(data) data && data?.canDrop, GROUND)
  return {
    size = flex()
    watch = [itemsAround, heroState.weaponsList]
    children = children
  }
}

local nearyByItemsCursorAttractor = {
  size = [flex(), itemHeight]
  cursorNavAnchor = [::elemw(50), ::elemh(50)]
  behavior = Behaviors.RecalcHandler
  margin =[::calc_comp_size(mkInventoryListHdr(INVENTORY))[1] + itemsListGap,0,0,0]
  function onRecalcLayout(initial, elem){
    if (initial && isGamepad.value && itemsAround.value.len()>0) {
      ::move_mouse_cursor(elem, false)
    }
  }
}

local inventoryCursorAttractor = {
  size = [flex(), itemHeight]
  cursorNavAnchor = [::elemw(50), ::elemh(50)]
  behavior = Behaviors.RecalcHandler
  margin =[::calc_comp_size(mkInventoryListHdr(INVENTORY))[1] + itemsListGap,0,0,0]
  function onRecalcLayout(initial, elem){
    if (initial && isGamepad.value && itemsAround.value.len()==0 && inventoryItems.value.len()>0) {
      ::move_mouse_cursor(elem, false)
    }
  }
}

local containerAnims = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.25, play=true, easing=OutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[1,0.01], duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

const takeOrDropHotkey = "^J:Y"
const useHotkey = "^J:X"
const requestHelpHotkey  = "^J:RB"
const secondUseKey  = "^J:LB"

local emptyHotkey = {action = @() null, description = {skip=true}}
local hotkeysEater = {
  hotkeys = [takeOrDropHotkey, useHotkey, requestHelpHotkey, secondUseKey].map(@(v) [v, emptyHotkey])
}

local actionTextMap = {
  take = ::loc("controls/Inventory.Pickup")
  use = ::loc("controls/Inventory.UseItem")
  drop = ::loc("controls/Inventory.DropItem")
  secondUse = ::loc("controls/Inventory.EquipToSecondWeapon")
}

local function contextHotkeys(){
  local children = []
  local item = focusedItem.value
  local tryTake = item?.take
  local tryUse = item?.use
  local tryDrop = item?.drop
  local onSecondUse = item?.onSecondUse
  if (tryTake!=null)
    children.append({key = tryTake, hotkeys = [[takeOrDropHotkey, {action = tryTake, description=actionTextMap.take}]]})
  else if (tryDrop!=null)
    children.append({key = tryDrop, hotkeys = [[takeOrDropHotkey, {action = tryDrop, description=actionTextMap.drop}]]})
  if (tryUse != null)
    children.append({key = tryUse, hotkeys = [[useHotkey, {action = tryUse, description=actionTextMap.use}]]})
  if (item?.onSecondUse != null)
    children.append({key = onSecondUse, hotkeys = [[secondUseKey, {action = onSecondUse, description=actionTextMap.secondUse}]]})
  return {
    watch = focusedItem
    children = children
  }
}

local needRequestHotkey = ::Computed(@() (requestData.value ?? "") != "" && teammatesAliveNum.value > 0 && isAlive.value)
local quickHint = { action = @() teamRequest(requestData.value), description = ::loc("controls/HUD.QuickHint") }
local requestHotkey = @() {
  watch = needRequestHotkey
  children = !needRequestHotkey.value ? null
    : {
        hotkeys = [
          ["@HUD.QuickHint", quickHint ],
          [requestHelpHotkey, quickHint ],
        ]
      }
}

local function mkMouseKey(text, mbtns){
  return {
    flow = FLOW_HORIZONTAL
    size = SIZE_TO_CONTENT
    children = mkMouseHint(text, mbtns)
  }
}

local function makeHintText(locId) {
  return {
    rendObj = ROBJ_DTEXT
    color = Color(180,180,180,180)
    text = ::loc($"controls/{locId}")
  }
}
local gameMenuHint = @(){
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  watch = isGamepad
  children = isGamepad.value ? [controlHudHint(HUD_GAMEMENU_HOTKEY), makeHintText(HUD_GAMEMENU_HOTKEY)] : null
}

local function mkMouseKeys(item){
  return function(){
    local btns = {}
    foreach (btn in ["LMB","RMB","MMB"]) {
      local text = item.value?[btn]
      if (text==null)
        continue
      if (text in btns)
        btns[text].append(btn)
      else
        btns[text]<-[btn]
    }
    local children = btns.reduce(@(a, btn, text) a.append(mkMouseKey(text, btn)), [])
    return{
      watch = focusedItem
      flow = FLOW_HORIZONTAL
      size = SIZE_TO_CONTENT
      children = children
      vplace = ALIGN_CENTER
      gap = ::hdpx(20)
      pos = [::hdpx(100),0]
    }
  }
}

local scPressedMonitor = @(sc, watch) {
  behavior = Behaviors.Button
  onElemState = @(sf) watch((sf & S_ACTIVE) != 0)
  hotkeys = [[sc]]
  onDetach = @() watch(false)
}
local shiftPressedMonitor = scPressedMonitor("^L.Shift | R.Shift", isShiftPressed)

local function inventoryContainer() {
  //should be scrolling container
  return {
    key = "inventoryContainer"
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(120,120,120,250)
    size = [sw(100),sh(100)]
    cursor = cursors.normal
     //this is ugly hack. Better to find actions that are really working
    onAttach = @() hotkeysPanelStateComps.update(function(v) { v[HUD_GAMEMENU_HOTKEY] <- gameMenuHint})
    onDetach = @() hotkeysPanelStateComps.update(function(v) {if (HUD_GAMEMENU_HOTKEY in v) delete v[HUD_GAMEMENU_HOTKEY]})

    sound = {
      attach = "ui/inventory_on"
      detach = "ui/inventory_off"
    }
    children = [
      shiftPressedMonitor
      hotkeysEater
      playerEventsRoot
      {
        size = flex()
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        transform = {pivot = [0.5,0]}
        flow = FLOW_VERTICAL
        hotkeys = [
          ["^{0} | Esc".subst(JB.B), {action = close, description = ::loc("mainmenu/btnClose")}],
        ]
        children = [
          toppadding
          @(){
            size = flex()
            flow = FLOW_HORIZONTAL
            gap = hdpx(30)
            children = [
              leftpadding
              {size = flex(), children = [nearyByItemsCursorAttractor, nearbyItems]}
              {size = flex(), children = [inventoryCursorAttractor, inventoryItemsComp]}
              dropItemsArea
              paperdoll
              weapons
              rightpadding
            ]
            animations = containerAnims
          }
          contextHotkeys
          requestHotkey
          bottompadding.__merge({flow = FLOW_HORIZONTAL gap = ::hdpx(10) padding = [0,0,0,hdpx(50)] children = [mkMouseKeys(focusedItem)]})
        ]
      }
      closebutton
    ]
  }
}

return {
  inventoryUi = inventoryContainer
  showInventory = showInventory
}
 