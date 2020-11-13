local {throttle} = require("utils/timers.nut")
local {isEqual} = require("std/underscore.nut")
local grenades = persist("grenades", @() Watched({}))
local {Point2} = require("dagor.math")
local {EventHeroChanged} = require("gameevents")
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {is_item_potentially_useful, is_item_useful, INVALID_ITEM_ID} = require("humaninv")

local inventoryItems = persist("inventoryItems", @() Watched([]))
/*

   TODO (items):
     ! install weapMod doesnt cause itemContainer changes!
     ! taking coins doesnt cause itemContainer changes!

   TODO (grenades):
     * Optimize update (isEqual() replace state of grenades with list or table of Watched values)
     * Improve grenade slot in inventory screen
*/


local get_item_info_query = ::ecs.SqQuery("get_item_info_query", {
  comps_ro = [
    ["item.id", ::ecs.TYPE_INT, INVALID_ITEM_ID],
    ["gunAttachable.gunSlotName", ::ecs.TYPE_STRING, null],
    ["gunAttachable.slotTag", ::ecs.TYPE_STRING, null],
    ["item.iconOffset", ::ecs.TYPE_POINT2, Point2(0,0)],
    ["item.name", ::ecs.TYPE_STRING, ""],
    ["animchar.res", ::ecs.TYPE_STRING, ""],
    ["item.iconImage", ::ecs.TYPE_STRING, null],
    ["item.iconYaw", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconPitch", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconRoll", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconScale", ::ecs.TYPE_FLOAT, 1.0],
    ["item.volume", ::ecs.TYPE_FLOAT, 0.0],
    ["item.weight", ::ecs.TYPE_FLOAT, 0.0],
    ["item.count",::ecs.TYPE_INT, 1],
    ["item.equipToSlots", ::ecs.TYPE_ARRAY, null],
    ["item.useTime", ::ecs.TYPE_FLOAT, null],
    ["item.armorAmount", ::ecs.TYPE_FLOAT, null],
    ["item.ammoPropsId", ::ecs.TYPE_INT, -1],
    ["item.unusableName", ::ecs.TYPE_STRING, null],
    ["item.weapTemplate", ::ecs.TYPE_STRING, null],
    ["item.weapSlots", ::ecs.TYPE_ARRAY, null],
    ["item.nonDroppable", ::ecs.TYPE_TAG, null],
    ["item.baseSortScore", ::ecs.TYPE_INT, 0],
    ["item.unlockTime", ::ecs.TYPE_INT, -1],
    ["item.weapType", ::ecs.TYPE_STRING, null],
    ["item.animation", ::ecs.TYPE_STRING, null],
    ["playerItemOwner", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["animchar.objTexReplace", ::ecs.TYPE_OBJECT, null],
  ]
})
local function getItemInfo(eid, comp){
  local iconOffs = comp["item.iconOffset"]
  local equipSlots = comp["item.equipToSlots"]?.getAll?() ?? []
  local validWeaponSlots = []
  if ([null, ""].indexof(comp["item.weapTemplate"])==null && comp["item.weapSlots"]?.getAll()!=null)
    validWeaponSlots = comp["item.weapSlots"].getAll()
  local isUsable = (comp["item.useTime"] > 0) ?? false
  local isWeaponMod = comp["gunAttachable.gunSlotName"] != null
  local add = {}
  if (isWeaponMod) {
    add.__update({
      weapModSlotName = comp["gunAttachable.gunSlotName"]
      weapModTag = comp["gunAttachable.slotTag"]
    })
  }
  local heroEid = watchedHeroEid.value ?? INVALID_ENTITY_ID
  local ownerName = comp["playerItemOwner"] != INVALID_ENTITY_ID ? ::ecs.get_comp_val(comp["playerItemOwner"], "name") : ::loc("teammate")
  local itemDesc = isUsable ? comp["item.name"] : comp["item.unusableName"] ?? comp["item.name"] ?? "unknown"
  local key = $"{itemDesc}_{ownerName}"
  local objTexReplace = comp["animchar.objTexReplace"] ?? []
  local objTexReplaceS = []
  foreach(from, to in objTexReplace)
    objTexReplaceS.append("objTexReplace:t={0};objTexReplace:t={1};".subst(from, to))
  return {
    eid = eid
    eids = [eid]
    isUseful = is_item_useful(heroEid, eid)
    isPotentiallyUseful = is_item_potentially_useful(heroEid, eid)
    desc = itemDesc
    key = key
    iconImage = comp["item.iconImage"]
    iconName = comp["animchar.res"]
    iconYaw = comp["item.iconYaw"]
    iconPitch = comp["item.iconPitch"]
    iconRoll = comp["item.iconRoll"]
    iconOffsX = iconOffs.x
    iconOffsY = iconOffs.y
    iconScale = comp["item.iconScale"]
    unlockTime = comp["item.unlockTime"]
    volume = comp["item.volume"],
    weight = comp["item.weight"],
    countPerItem = comp["item.count"],
    id = comp["item.id"]
    count = 1,
    isEquipment = (equipSlots?.len?() ?? 0) > 0,
    canDrop = !(::type(comp["item.nonDroppable"])=="string"),
    isUsable = isUsable,
    equipmentSlots = equipSlots,
    validWeaponSlots = validWeaponSlots,
    isWeapon =  validWeaponSlots.len() > 0,
    weapType =  comp["item.weapType"],
    isWeaponMod = isWeaponMod
    isArmor = comp["item.armorAmount"]!=null,
    isAmmo = comp["item.ammoPropsId"] > -1,
    baseScore = comp["item.baseSortScore"],
    animation = comp["item.animation"],
    ownerNickname = ownerName,
    objTexReplace = "".join(objTexReplaceS)
  }.__update(add)
}

local function get_nearby_item_info(item_eid) {
  local info = get_item_info_query.perform(item_eid, getItemInfo) ?? null
  if (info != null)
    info.isUsable <- false
  return info
}

local get_grenade_type_query = ::ecs.SqQuery("get_grenade_type_query", {
  comps_ro = [
    ["item.grenadeType", ::ecs.TYPE_STRING]
  ]
})

local function updateInventory(items) {
  local res_table = {}
  foreach (item_eid in items){
    local item = get_item_info_query.perform(item_eid, getItemInfo)
    if (item==null)
      continue
    if (item.key in res_table) {
      res_table[item.key].count++
      res_table[item.key].eids.append(item.eid)
    } else
      res_table[item.key]<-item
  }
  local prevItems = inventoryItems.value

  local changed = false
  items = res_table.values()
  if (prevItems.len() != items.len())
    changed = true
  else {
    foreach (item in items){
      local oldItem = prevItems?[prevItems.findindex(@(olditem) olditem.desc == item.desc)] ?? null
      if (oldItem == null || oldItem.countPerItem != item.countPerItem || oldItem.eid != item.eid || oldItem.count != item.count || oldItem.unlockTime!=item.unlockTime){
        changed = true
        break
      }
    }
  }
  if (changed)
    inventoryItems(res_table.values())
}

local function trackGrenades(items) {
  local newGrenades = {}
  foreach (item_eid in items) {
    local grenadeType = get_grenade_type_query.perform(item_eid, function(eid, gcomp){
      return gcomp["item.grenadeType"]
    })
    if ([null, "shell"].indexof(grenadeType) != null)
      continue
    newGrenades[grenadeType] <- (newGrenades?[grenadeType] ?? 0) + 1
  }

  if (!isEqual(newGrenades, grenades.value)) {
    grenades(newGrenades)
  }
}

local function trackInventory(evt, eid, comp){
  local items = comp["itemContainer"]?.getAll() ?? []
  updateInventory(items)
  trackGrenades(items)
}
local function clearOnDestroy(evt, eid, comp) {
  inventoryItems([]); grenades({})
}
grenades.whiteListMutatorClosure(trackGrenades)
grenades.whiteListMutatorClosure(clearOnDestroy)
inventoryItems.whiteListMutatorClosure(updateInventory)
inventoryItems.whiteListMutatorClosure(clearOnDestroy)

::ecs.register_es("inventory_items_ui_es",
  {
    [["onInit", "onChange", EventHeroChanged, ::ecs.sqEvents.EventRebuiltInventory/*EventOnLootPickup*/]] = trackInventory,
    onDestroy = clearOnDestroy,
    onUpdate = trackInventory
  },
  {
    comps_rq = ["watchedByPlr"],
    comps_track = [["itemContainer", ::ecs.TYPE_EID_LIST]]
  },
  { updateInterval = 2, after="*", before="*" }
)

//workaround for non updating inventory
::ecs.register_es("local_inventory_items_ui_update_es",
  {[["onChange", "onInit"]] = @(evt, eid, comp) ::ecs.g_entity_mgr.sendEvent(watchedHeroEid.value, ::ecs.event.EventRebuiltInventory())},
  {
    comps_rq = ["item.owned_controllable_hero"]
    comps_track = [
      ["item.count",::ecs.TYPE_INT, 1],
      ["item.useTime", ::ecs.TYPE_FLOAT, null],
    ]
  }
)


local capacityVolume = Watched(0.0)
::ecs.register_es("capacity_volume_es",{
  [["onChange", "onInit"]] = @(eid, comp) capacityVolume(comp["human_inventory.capacity"]),
  onDestroy = @(eid,comp) capacityVolume(0.0)

},{comps_track = [["human_inventory.capacity", ::ecs.TYPE_FLOAT, 0.0]], comps_rq = ["watchedByPlr"]})

local canPickupItems = Watched(false)
::ecs.register_es("canPickupItems_es",{
  [["onChange", "onInit"]] = @(eid,comp) canPickupItems(comp["human.canPickupItems"]),
  onDestroy = @(eid, comp) canPickupItems(false)
}, {comps_track=[["human.canPickupItems",::ecs.TYPE_BOOL]], comps_rq=["human_input"]})

local carriedVolume = Watched(0.0)
local carriedWeight = Watched(0.0)
::ecs.register_es("hero_state_inv_stats_ui_es",
  {
    [["onInit","onChange"]] = function(eid,comp) {
      carriedVolume(comp["human_inventory.currentVolume"])
      carriedWeight(comp["human_inventory.currentWeight"])
    },
    onDestroy = function(eid,comp){carriedVolume(0.0);carriedWeight(0.0)}
  },
  {
    comps_track=[["human_inventory.currentVolume", ::ecs.TYPE_FLOAT, 0.0], ["human_inventory.currentWeight", ::ecs.TYPE_FLOAT, 0.0]]
    comps_rq=["watchedByPlr"]
  }
)

local itemsAround = persist("itemsAround", @() Watched([]))
const rebuildItemsAroundTime = 0.15
local function mkTrackItemsAround() {
  local _itemsAround = []
  local _get_items_around = throttle(@() itemsAround(_itemsAround.map(get_nearby_item_info).filter(@(v) v!=null)), rebuildItemsAroundTime, {leading=false, trailing=true})
  return function(evt,eid, comp){
    _itemsAround = comp["itemsAround"].getAll()
    _get_items_around()
  }
}

::ecs.register_es("hud_state_track_items_around_ui_es", {
  [["onInit","onChange"]] = mkTrackItemsAround()
  onDestroy = @(evt, eid, comp) itemsAround([])
}, { comps_track = [["itemsAround", ::ecs.TYPE_ARRAY]], comps_rq = ["watchedByPlr"]})

return {
  get_out_item_info = get_nearby_item_info,
  grenades,
  canPickupItems, carriedVolume, carriedWeight, capacityVolume,
  inventoryItems, itemsAround
}
 