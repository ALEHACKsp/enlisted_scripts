local { perksData } = require("soldierPerks.nut")
local { armies, getSoldierItem, curCampSquads } = require("state.nut")
local { classPerksLimitByArmy } = require("enlisted/enlist/researches/researchesSummary.nut")
local { getLinkedArmyName, getLinkedSquadGuid } = require("enlisted/enlist/meta/metalink.nut")

local getPerksCount = @(perks) (perks?.tiers ?? [])
  .reduce(@(res, tier) res + (tier?.slots ?? []).filter(@(v) (v ?? "") != "").len(), 0)

local function collectSoldierDataImpl(soldier, perksDataV, classPerksLimitByArmyV, curCampSquadsV, armiesV) {
  local guid = soldier?.guid
  if (guid == null)
    return soldier

  local armyId = getLinkedArmyName(soldier)
  local perks = perksDataV?[guid]
  local { level = 1, maxLevel = 1 } = perks
  local perksCount = getPerksCount(perks)

  return soldier.__merge({
    primaryWeapon = getSoldierItem(guid, "primary")
      ?? getSoldierItem(guid, "secondary")
      ?? getSoldierItem(guid, "side")
    country = armiesV?[armyId].country
    level = ::min(level, maxLevel)
    maxLevel = maxLevel
    perksCount = perksCount
    perksLimit = min(classPerksLimitByArmyV?[armyId][soldier?.sClass] ?? 0, maxLevel)
    armyId = armyId
    squadId = curCampSquadsV?[getLinkedSquadGuid(soldier)].squadId
  })
}

return {
  collectSoldierData = @(soldier)
    collectSoldierDataImpl(soldier, perksData.value, classPerksLimitByArmy.value,
      curCampSquads.value, armies.value)
  mkSoldiersData = @(soldier) soldier instanceof ::Watched
    ? ::Computed(@() collectSoldierDataImpl(soldier.value, perksData.value, classPerksLimitByArmy.value,
        curCampSquads.value, armies.value))
    : ::Computed(@() collectSoldierDataImpl(soldier, perksData.value, classPerksLimitByArmy.value,
        curCampSquads.value, armies.value))
  mkSoldiersDataList = @(soldiersListWatch) ::Computed(
    @() soldiersListWatch.value.map(@(soldier)
      collectSoldierDataImpl(soldier, perksData.value, classPerksLimitByArmy.value, curCampSquads.value, armies.value)))
} 