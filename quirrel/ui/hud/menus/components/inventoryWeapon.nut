local {unload_weapon_ammo_to_inventory, choose_weapon} = require("human_weap")
local {remove_item_from_weap_to_inventory, install_item_on_weap_by_eid, swap_weapon_mods} = require("humaninv")
local {draggedData,requestData, focusedData, requestItemData} = require("ui/hud/state/inventory_state.nut")
local cursors = require("ui/style/cursors.nut")
local {iconWeapon, weaponModImage, inventoryItemImage} = require("inventoryItemImages.nut")
local inventoryWeaponMod = require("inventoryWeaponMod.nut")
local {GROUND, INVENTORY} = require("inventoryItemTypes.nut")
local style = require("ui/hud/style.nut")
local {mkWeaponTypeIco} = require("ui/hud/components/itemWeaponTypeIcon.nut")
local {weaponTypeIconColor} = require("inventoryStyle.nut")

local curBorderColor = style.SELECTION_BORDER_COLOR
local weaponTextCurColor = Color(255,255,255)
local weaponTextColor = Color(180,180,180)
local weaponBgColor = Color(0,0,0,50)
local weaponBgCurColor = Color(30,30,30,50)
local weaponBgHoverColor = Color(70,70,70,210)
local weaponBorderHoverColor = Color(80,60,10,30)

local weaponTypeIconHeight = hdpx(25)
local function teamRequest(weapon){
  local requestAmmo = weapon.currentWeaponSlotName == "grenade" ? "request/weapon/moreGrenade" : "request/weapon/ammo"
  local requestWeapon = "request/weapon/{0}".subst(weapon.currentWeaponSlotName)
  return (weapon.name == "" || weapon.currentWeaponSlotName == "melee") ? requestWeapon : requestAmmo
}


local mkHotkeyToRemoveScope = @(action) {hotkeys=[["^J:X", {action = action, description=::loc("Inventory/remove_scope")}]]}
local function weaponWidget(weapon, idx){
  local showWeaponAmmoUnload = ::Watched(false)
  local showRemoveScope = ::Watched(false)
  local group = ::ElemGroup()
  local curWeapSlotName = weapon.currentWeaponSlotName

  local hotkeyToRemoveMod
  local weaponModWidgets = []
  foreach (modSlotName_, modSlot_ in weapon?.mods ?? {}) {
    local modSlotName = modSlotName_
    local modSlot = modSlot_
    local function onDrop(item) {
      if (item?.fromList == GROUND || item?.fromList == INVENTORY)
        install_item_on_weap_by_eid(item.eid, curWeapSlotName, modSlotName)
      else if ("currentWeapModSlotName" in item)
        swap_weapon_mods(item.currentWeaponSlotName, item.currentWeapModSlotName, curWeapSlotName, modSlotName)
    }
    local function canDropDragged(item) {
      local alreadyAttachedHere = (item?.currentWeapModSlotName == modSlotName && item?.currentWeaponSlotName == curWeapSlotName)

      return !alreadyAttachedHere && item?.weapModSlotName == modSlotName &&
        (!("weapModTag" in item) || modSlot.array_tags.indexof(item.weapModTag) != null)
    }
    local dropData = (modSlot.itemPropsId == 0) ? {} : {
      canDrop=true
      // slot info
      currentWeaponSlotName=curWeapSlotName
      currentWeapModSlotName=modSlotName
      // mod item info
      id=modSlot.itemPropsId
      weapModSlotName=modSlot?.attachedItemModSlotName
      weapModTag=modSlot?.attachedItemModTag
    }
    if ((modSlot?.attachedItemModTag ?? "") != "")
      hotkeyToRemoveMod = mkHotkeyToRemoveScope(@() remove_item_from_weap_to_inventory(curWeapSlotName, modSlotName))
    weaponModWidgets.append(
      inventoryWeaponMod(
        {dropData=dropData,
          image=weaponModImage(modSlot),
          size=[sh(14),sh(5.5)],
          canDropDragged=canDropDragged,
          onDrop = onDrop,
          text = ::loc(modSlot.attachedItemName),
          isUnloadable = (modSlot.itemPropsId ?? 0) != 0
          compsOnHover = [hotkeyToRemoveMod]
        }
      )
    )
  }

  local hotkeyToUnload = {hotkeys=[["^J:LB", {action = @() unload_weapon_ammo_to_inventory(curWeapSlotName), description=::loc("Inventory/unload_ammo")}]]}
  local hotkeyToUnloadByWeapon = @() { watch = showWeaponAmmoUnload children = showWeaponAmmoUnload.value ? hotkeyToUnload : null }
  if (weapon?.ammo) {
    local function onDropInInventory() {unload_weapon_ammo_to_inventory(curWeapSlotName)}
    weaponModWidgets.append({size=[flex(),0]},
       inventoryWeaponMod({
         dropData={onDropInInventory = onDropInInventory},
         image = inventoryItemImage(weapon.ammo),
         size = [sh(5.5),sh(5.5)],
         canDropDragged = @(item) false,
         onDrop = @(val) null,
         text = "{0}/{1}".subst(weapon.curAmmo, weapon.totalAmmo),
         isUnloadable = weapon.curAmmo > 0 && weapon?.isUnloadable
         compsOnHover = [hotkeyToUnload]
       })
    )
  }

  local isCurrent = (weapon?.isEquiping || (weapon?.isCurrent && !weapon?.isHolstering)) ?? false
  local weaponText = {
    rendObj = ROBJ_DTEXT
    text=::loc(weapon.name)
    font=Fonts.big_text
    color = isCurrent ? weaponTextCurColor : weaponTextColor,
    clipChildren = true,
  }
  local weapTypeIco = mkWeaponTypeIco(weapon?.weapType, weaponTypeIconHeight)
  if (weapTypeIco != null) {
    weapTypeIco = {
      size = [weaponTypeIconHeight, weaponTypeIconHeight]
      pos = [0, hdpx(2)]
      vplace = ALIGN_CENTER
      color = weaponTypeIconColor
      rendObj = ROBJ_IMAGE
      image = weapTypeIco
    }
  }

  local weaponName = {flow = FLOW_HORIZONTAL children = [weapTypeIco, weaponText] size = [flex(), SIZE_TO_CONTENT] gap= hdpx(10)}
  local children = [weaponName]

  if (weaponModWidgets.len()){
    children.append(
      {size=flex()}
      {size=[flex(),SIZE_TO_CONTENT] flow=FLOW_HORIZONTAL gap=hdpx(5) children = weaponModWidgets}
    )
  }
  local isRemovableWeapon = ["melee", "grenade"].indexof(curWeapSlotName) == null

  local descLoc = ::loc("{0}/desc".subst(weapon?.name ?? ""), "")
  local hotkeyToRemoveScope = @(){watch = showRemoveScope, children = showRemoveScope.value ? hotkeyToRemoveMod : null}
  local function onHover(on){
    requestData.update(on ? teamRequest(weapon) : "")
    requestItemData.update(on ? weapon.name : "")
    if (isRemovableWeapon && weapon?.isWeapon)
      focusedData(on ? weapon.__merge({canDrop=true}) : null)
    else
      focusedData(null)
    showWeaponAmmoUnload(on && (weapon?.curAmmo ?? 0)> 0 && weapon?.isUnloadable)
    showRemoveScope(on)
    cursors.tooltip.state(on && descLoc != "" ? descLoc : null)
  }

  local stateFlags = ::Watched(0)

  local function background() {
    local sf =  stateFlags.value;
    local isHovered = ((sf & S_HOVER) || (sf & S_DRAG)) && (weapon?.itemPropsId ?? -1) != -1
    return {
      watch = stateFlags
      size = [flex(), flex()]
      rendObj = ROBJ_BOX
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      fillColor = isCurrent ? weaponBgCurColor
        : isHovered ? weaponBgHoverColor
        : weaponBgColor
      borderWidth = isCurrent ? hdpx(1.5)
        : isHovered ? hdpx(1.0)
        : 0
      borderColor = isCurrent ? curBorderColor
        : isHovered ? weaponBorderHoverColor
        : 0
    }
  }

  local ret = {
    function onElemState(sf) {
      stateFlags(sf)
      if (sf & S_HOVER){
        showWeaponAmmoUnload((weapon?.curAmmo ?? 0)> 0 && weapon?.isUnloadable)
        showRemoveScope(true)
      }
    }
    size = flex()
    key = "weapon_{0}".subst(idx)
    group = group
    children = [
      background
      { size = [flex(), flex()] padding = hdpx(6) children = iconWeapon(weapon) }
      { size = [flex(), flex()] padding = hdpx(6) flow = FLOW_VERTICAL valign = ALIGN_BOTTOM halign = ALIGN_CENTER gap = hdpx(4) children = children }
      hotkeyToUnloadByWeapon
      hotkeyToRemoveScope
    ]
    behavior = Behaviors.Button
    onHover = onHover
    function onClick() {
      choose_weapon(curWeapSlotName)
    }
  }

  if (isRemovableWeapon && weapon?.isWeapon) {
    ret.__update({
      behavior = Behaviors.DragAndDrop
      transform = {}
      dropData = weapon.__merge({canDrop = true})
      function onDragMode(on, item) {
        draggedData.update(on ? item : null)
      }
    })
  }
  return ret
}
return weaponWidget
 