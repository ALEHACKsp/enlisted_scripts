local userInfo = require("enlist/state/userInfo.nut")
local { configs } = require("enlisted/enlist/configs/configs.nut")
local { permissions } = require("globals/client_user_permissions.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")

/*
  adhoc 'typesystem'
  slots_of_items - dictionary with key as slotname and value is items of possible itemstemplates
  slots_of_types - dictionary with key as slotname and value is items of possible _itemtypes,
  item_of_types - one item of listed _itemtypes
  item_of_items - one item of listed items
  list<_itemtypes>  - list of items of listed itemtype
  list<item>  - list of items of listed itemtype
*/
local config = [
  { armies = ["normandy_allies", "tunisia_allies"], files = ["normandy_usa_vehicles.nut"] }
  { armies = ["normandy_axis", "tunisia_axis"],     files = ["normandy_germany_vehicles.nut"] }
  { armies = ["moscow_axis"],                       files = ["moscow_germany_vehicles.nut"] }
  { armies = ["moscow_allies"],                     files = ["moscow_ussr_vehicles.nut"] }
  { armies = ["berlin_axis"],                       files = ["berlin_germany_vehicles.nut"] }
  { armies = ["berlin_allies"],                     files = ["berlin_ussr_vehicles.nut"] }
]

local function loadArmyTemplates(files) {
  local target = {}
  foreach(f in files) {
    local armyTemplates = require($"item_templates/{f}")
    target.__update(armyTemplates)
  }
  return target
}

local function prepareLocalTemplates(cfg) {
  local result = {}
  result["generic"] <- {}
  foreach (c in cfg) {
    if (c.armies == null) {
      result["generic"].__update(loadArmyTemplates(c.files))
    } else {
      foreach (army in c.armies) {
        if (!(army in result)) { result[army] <- {} }
        result[army].__update(loadArmyTemplates(c.files))
      }
    }
  }
  return result
}

local templatesLocal = prepareLocalTemplates(config)

local templatesCombined = ::Computed(function() {
  local all = clone templatesLocal
  local genericLocal = all?["generic"] ?? {}
  local templatesServer = configs.value?.items_templates ?? {}
  foreach (armyId, armyTemplates in templatesServer) {
    if (armyId not in all)
      all[armyId] <- {}
    foreach (key, item in genericLocal)
      all[armyId][key] <- (all[armyId]?[key] ?? {}).__merge(item)
    foreach (key, item in armyTemplates)
      all[armyId][key] <- (all[armyId]?[key] ?? {}).__merge(item)
  }
  return all
})

local equipSchemesByArmy = ::Computed(function() {
  local schemesAll = {}
  foreach (armyId, armyTemplates in templatesCombined.value) {
    local equipSchemes = configs.value?.equip_schemes ?? {}
    schemesAll[armyId] <- equipSchemes.map(@(scheme) scheme.map(function(slot) {
      local isDisabled = true
      foreach (itemTpl in slot.items)
        if (itemTpl in armyTemplates) {
          isDisabled = false
          break
        }
      if (isDisabled)
        foreach (itemtype in slot.itemTypes)
          if (armyTemplates.findvalue(@(tpl) tpl.itemtype == itemtype) != null) {
            isDisabled = false
            break
          }
      return (clone slot).__update({ isDisabled })
    }))
  }
  return schemesAll
})

local allItemTemplates = ::Computed(@() templatesCombined.value.map(function(armyTemplates, armyId) {
  local isDebugShow = permissions.value?[userInfo.value?.userId].debug_items_show ?? false
  local equipSchemes = equipSchemesByArmy.value?[armyId] ?? {}
  return armyTemplates
    .filter(@(tpl) !(tpl?.isShowDebugOnly ?? false) || isDebugShow)
    .map(function(tpl) {
      local { slot = "", equipSchemeId = null } = tpl
      if (slot == "" && "slot" in tpl)
        delete tpl["slot"]
      if (equipSchemeId in equipSchemes)
        tpl.equipScheme <- equipSchemes[equipSchemeId]
      return tpl
    })
  }))

local function findItemTemplate(templates, army, tpl) {
  return templates.value?[army][tpl]
}

local function findItemTemplateByItemInfo(templates, itemInfo) {
  return findItemTemplate(templates, getLinkedArmyName(itemInfo), itemInfo?.basetpl)
}

local singleSlotItemTypes = @(subSchemeGetter) function(scheme, resTypes) {
  local iTypes = subSchemeGetter(scheme)?.itemTypes
  if (iTypes)
    foreach (iType in iTypes)
      resTypes[iType] <- true
}

local slotTypesConfig = {
  function mainWeapon(scheme, resTypes) {
    foreach (key in ["primary", "secondary"])
      foreach (iType in scheme?[key].itemTypes ?? [])
        resTypes[iType] <- true
  }
  primary = singleSlotItemTypes(@(scheme) scheme?.primary)
  secondary = singleSlotItemTypes(@(scheme) scheme?.secondary)
}

local itemTypesInSlots = ::Computed(function() {
  local equipSchemes = configs.value?.equip_schemes ?? {}
  return slotTypesConfig.map(function(handler) {
    local resTypes = {}
    equipSchemes.each(@(s) handler(s, resTypes))
    return resTypes
  })
})

return {
  equipSchemesByArmy
  allItemTemplates
  findItemTemplate
  findItemTemplateByItemInfo
  itemTypesInSlots
}
 