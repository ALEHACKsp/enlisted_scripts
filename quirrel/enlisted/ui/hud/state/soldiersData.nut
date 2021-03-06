local armyData = require("enlisted/ui/hud/state/armyData.nut")
local weaponSlots = require("globals/weapon_slots.nut")

local soldierFieldKeys = [
  "guid", "name", "surname", "sClass", "tier", "level", "maxLevel", "exp", "availPerks",
  "perksCount", "perksLimit"
]

local function getWeaponData(weapSlotIdx, soldier) {
  local weapTemplate = soldier?["human_weap.weapTemplates"][weaponSlots.weaponSlotsKeys[weapSlotIdx]]
  local weapInfo = soldier?["human_weap.weapInfo"][weapSlotIdx]

  local tplName = weapTemplate
  if (tplName == null || weapSlotIdx == weaponSlots.EWS_GRENADE)
    tplName = weapInfo?.reserveAmmoTemplate

  local db = ::ecs.g_entity_mgr.getTemplateDB()
  local template = tplName == null ? null : db.getTemplateByName(tplName)

  local gunMods = []
  weapInfo?.gunMods.each(function(modTplName, slotTag) {
    local modTemplate = db.getTemplateByName(modTplName)
    gunMods.append({
      templateName = modTplName
      name = ::loc(modTemplate.getCompValNullable("item.name") ?? modTplName)
    })
  })

  return {
    templateName = tplName
    isPrimary = weapSlotIdx == weaponSlots.EWS_PRIMARY || weapSlotIdx == weaponSlots.EWS_SECONDARY
    name = ::loc(template?.getCompValNullable("item.name") ?? $"weaponSlot/{weapSlotIdx}")
    gunMods = gunMods
  }
}

local function collectSoldierData(soldier, armyId, squadId, country) {
  local res = {}
  foreach (key in soldierFieldKeys)
    if (key in soldier)
      res[key] <- soldier[key]

  return res.__update({
    armyId = armyId
    squadId = squadId
    country = country
    weapons = array(weaponSlots.EWS_NUM, null).map(@(w, idx) getWeaponData(idx, soldier))
  })
}

local soldiers = Computed(function() {
  local res = {}
  local squadsList = armyData.value?.squads
  if (squadsList == null)
    return res

  local armyId = armyData.value.armyId
  local country = armyData.value.country
  foreach (squad in squadsList) {
    foreach (soldier in squad.squad)
      res[soldier.guid] <- collectSoldierData(soldier, armyId, squad.squadId, country)
  }
  return res
})

return soldiers 