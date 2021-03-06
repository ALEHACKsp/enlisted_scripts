local { getSoldierItemSlots, objInfoByGuid } = require("state.nut")
local { isEqual } = require("std/underscore.nut")
local { allItemTemplates } = require("all_items_templates.nut")


local equalIgnore = { ctime = true, guid = true, guids = true, count = true, links = true, linkedItems = true }
local function countParamsToCompare(item) {
  local res = item.len()
  foreach(key, val in equalIgnore)
    if (key in item)
      res--
  return res
}

local function getLinkedItemsData(guid) {
  local res = {}
  foreach(data in getSoldierItemSlots(guid)) {
    local tpl = data.item?.basetpl
    if (!(data.slotType in res))
      res[data.slotType] <- {}
    res[data.slotType][data.slotId ?? -1] <- tpl
  }
  return res
}

local function mergeItems(item1, item2) {
  if (countParamsToCompare(item1) != countParamsToCompare(item2))
    return null
  foreach(key, val in item1)
    if (!equalIgnore?[key]
        && (!(key in item2) || !isEqual(val, item2[key])))
      return null

  local linkedItems = null
  if (item1?.equipScheme) {
    linkedItems = item1?.linkedItems ?? getLinkedItemsData(item1.guid)
    if (!isEqual(linkedItems, getLinkedItemsData(item2.guid)))
      return null
  }

  local guids = "guids" in item1 ? item1.guids : [item1?.guid]
  guids.append(item2?.guid)
  return item1.__merge({
    count = (item1?.count ?? 1) + (item2?.count ?? 1)
    guids = guids
    linkedItems = linkedItems
  })
}

local itemWeights = {
  // vehicle
  vehicle = 71,
  // special
  flamethrower = 62, mortar = 61,
  // heavy
  launcher = 52, antitank_rifle = 51,
  // assault
  mgun = 44, assault_rifle = 43, semiauto = 42, submgun = 41,
  // rifle and shotgun
  rifle_grenade_launcher = 37, shotgun = 36, boltaction_noscope = 34,
  carbine = 33, semiauto_sniper = 32, boltaction = 31,
  // pistol
  sideweapon = 29,
  // melee and equipment
  radio = 27, melee = 26, grenade = 25, scope = 24, medkits = 23, reapair_kit = 22,
  itemparts = 21
  // soldier
  soldier = 11,
}

local function prepareItems(items) {
  items = items
    .map(function(item) {
      if (typeof item == "string")
        return objInfoByGuid.value?[item]
      if ("guid" in item)
        return objInfoByGuid.value?[item.guid]
      return item
    })
    .filter(@(v) v != null)

  items.sort(@(a, b) (a?.basetpl ?? "") <=> (b?.basetpl ?? ""))

  local res = []
  foreach(item in items) {
    local isMerged = false
    local tpl = item?.basetpl
    for(local i = res.len() - 1; i >= 0; i--) {
      local tgtItem = res[i]
      if (tgtItem?.basetpl != tpl)
        break
      local merged = mergeItems(tgtItem, item)
      if (!merged)
        continue
      res[i] = merged
      isMerged = true
      break
    }
    if (!isMerged)
      res.append(item)
  }

  return res
}

local mkShopItem = @(templateId, template, armyId)
  template.__merge({ guid = "", basetpl = templateId, isShopItem = true, links = { [armyId] = "army"} })

local function addShopItems(items, armyId, templateFilter = @(templateId, template) true) {
  local usedTemplates = {}
  foreach(item in items)
    if (item?.basetpl)
      usedTemplates[item.basetpl] <- true

  foreach(templateId, template in (allItemTemplates.value?[armyId] ?? {})) {
    if (usedTemplates?[templateId]
        || (template?.isZeroHidden ?? false)
        || (("armies" in template) && template.armies.indexof(armyId) == null)
        || !templateFilter(templateId, template))
      continue

    items.append(mkShopItem(templateId, template, armyId))
  }
}

local itemsSort = @(item1, item2) (item1?.guid != null) <=> (item2?.guid != null)
  || (item1?.isShopItem ?? false) <=> (item2?.isShopItem ?? false)
  || (itemWeights?[item1?.itemtype] ?? 0) <=> (itemWeights?[item2?.itemtype] ?? 0)
  || ((item1?.tier ?? 0) - (item1?.upgradeIdx ?? 0)) <=> ((item2?.tier ?? 0) - (item2?.upgradeIdx ?? 0))
  || (item2?.itemsubtype ?? "") <=> (item1?.itemsubtype ?? "")
  || (item1?.gametemplate ?? "") <=> (item2?.gametemplate ?? "")
  || (item1?.tier ?? 0) <=> (item2?.tier ?? 0)

local preferenceSort = @(a, b) (b?.tier ?? 0) <=> (a?.tier ?? 0)
  || (itemWeights?[b?.itemtype] ?? 0) <=> (itemWeights?[a?.itemtype] ?? 0)
  || (a?.basetpl ?? "") <=> (b?.basetpl ?? "")

local function findItemByGuid(items, guid) {
  foreach(it in items)
    if ("guids" in it ? it.guids.indexof(guid) != null : it?.guid == guid)
      return it
  return null
}

local function putToStackTop(items, topItem) {
  local guid = topItem?.guid
  if (guid == null)
    return
  local item = findItemByGuid(items, guid)
  if (!("guids" in item) || item?.guid == guid)
    return

  item.guid <- guid
  if ("links" in topItem)
    item.links <- topItem.links
  item.guids.sort(@(a, b) (b == guid) <=> (a == guid))
}

return {
  itemWeights = itemWeights
  prepareItems = prepareItems
  mkShopItem = mkShopItem
  addShopItems = addShopItems
  itemsSort = itemsSort
  preferenceSort = preferenceSort
  findItemByGuid = findItemByGuid
  putToStackTop = putToStackTop
} 