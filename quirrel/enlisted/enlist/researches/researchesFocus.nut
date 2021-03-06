local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")
local {
  configResearches, armiesResearches, allResearchStatus,
  viewSquadId, selectedTable, selectedResearch,
  NOT_ENOUGH_EXP, CAN_RESEARCH, RESEARCHED
} = require("researchesState.nut")
local { armySquadsById } = require("enlisted/enlist/soldiers/model/state.nut")

local researchToShow = ::Watched(null)

local function closestResearch(army_id, researches) {
  local resStatus = allResearchStatus.value?[army_id] ?? {}
  return researches
    .map(@(res) res.__merge({ army_id, status = resStatus?[res.research_id] }))
    .filter(@(res) res.status != RESEARCHED)
    .sort(@(a, b) (b.status == CAN_RESEARCH) <=> (a.status == CAN_RESEARCH)
      || (b.status == NOT_ENOUGH_EXP) <=> (a.status == NOT_ENOUGH_EXP)
      || a.line <=> b.line
      || a.tier <=> b.tier)?[0]
}

local function focusResearch(research) {
  local { army_id = null, squad_id = null, page_id = null, research_id = null } = research
  local researchData = armiesResearches.value?[army_id].researches[research_id]
  if (squad_id == null || page_id == null || researchData == null)
    return
  // do not switch army, because all visible researches are belong to the current army
  viewSquadId(squad_id)
  selectedTable(page_id)
  selectedResearch(researchData)
  setCurSection("RESEARCHES")
  researchToShow(researchData)
}

local function findResearchById(research_id) {
  foreach (army_id, armyConfig in configResearches.value)
    foreach (squad_id, squadList in armyConfig?.pages ?? {}) {
      local resFound = squadList.findvalue(@(res) research_id in (res?.tables ?? {}))
      if (resFound != null)
        return { army_id, squad_id, page_id = resFound?.page_id ?? 0, research_id }
    }
  return null
}

local function findClosestResearch(armyId, checkFunc) {
  local researches = []
  local allResearches = armiesResearches.value?[armyId].researches ?? {}
  local armySquads = armySquadsById.value?[armyId] ?? {}
  foreach (researchData in allResearches)
    if (checkFunc(researchData) && armySquads?[researchData.squad_id].locked != true)
      researches.append(researchData)
  return closestResearch(armyId, researches)
}

local function findResearchMaxClassLevel(soldier) {
  if (soldier == null)
    return null
  local armyId = getLinkedArmyName(soldier)
  local sClass = soldier?.sClass
  return findClosestResearch(armyId, @(researchData)
    (researchData?.effect.max_class_level?[sClass] ?? 0) > 0)
}

local function findResearchSlotUnlock(soldier, slotType, slotId = -1) {
  if (soldier == null || slotType == null)
    return null
  local armyId = getLinkedArmyName(soldier)
  local sClass = soldier?.sClass
  return slotId >= 0
    ? findClosestResearch(armyId, @(researchData)
        (researchData?.effect.slot_enlarge?[slotType][sClass] ?? 0) > 0)
    : findClosestResearch(armyId, @(researchData)
        (researchData?.effect.slot_unlock?[sClass] ?? []).indexof(slotType) != null)
}

local function findResearchWeaponUnlock(item, soldier) {
  if (item == null || soldier == null)
    return null
  local basetpl = item?.basetpl
  local armyId = getLinkedArmyName(soldier)
  local sClass = soldier?.sClass
  return findClosestResearch(armyId, @(researchData)
    (researchData?.effect.weapon_usage?[sClass] ?? []).indexof(basetpl) != null)
}

local function findResearchUpgradeUnlock(armyId, item) {
  if (item == null)
    return null
  local upgradetpl = item?.upgradeitem
  return findClosestResearch(armyId, @(researchData)
    (researchData?.effect.weapon_upgrades ?? []).indexof(upgradetpl) != null)
}

local function findResearchTrainClass(soldier) {
  if (soldier == null)
    return null
  local armyId = getLinkedArmyName(soldier)
  local sClass = soldier?.sClass
  return findClosestResearch(armyId, @(researchData)
    (researchData?.effect.class_training?[sClass] ?? 0) > 0)
}

console.register_command(@(researchId)
  focusResearch(findResearchById(researchId)), "meta.focusResearch")

return {
  researchToShow = researchToShow
  focusResearch = focusResearch
  findResearchMaxClassLevel = findResearchMaxClassLevel
  findResearchSlotUnlock = findResearchSlotUnlock
  findResearchWeaponUnlock = findResearchWeaponUnlock
  findResearchUpgradeUnlock = findResearchUpgradeUnlock
  findResearchTrainClass = findResearchTrainClass
  findClosestResearch = findClosestResearch
}
 