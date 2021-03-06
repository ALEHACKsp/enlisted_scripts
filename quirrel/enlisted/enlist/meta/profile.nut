local servProfile = require("servProfile.nut")
local { items, soldiers, squads } = servProfile
local { getLinkedArmyName } = require("metalink.nut")
local { curCampaign } = require("curCampaign.nut")
local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local { allItemTemplates } = require("enlisted/enlist/soldiers/model/all_items_templates.nut")

const NO_ARMY = "__no_army__"

local divideByArmies = @(objList) objList.reduce(function(res, obj, guid) {
  local armyId = getLinkedArmyName(obj) ?? NO_ARMY
  if (armyId not in res)
    res[armyId] <- {}
  res[armyId][guid] <- obj
  return res
}, {})

local applyTemplatesByArmies = @(objByArmies, templates) objByArmies.map(@(list, armyId)
  list.map(@(obj) (templates?[armyId][obj?.basetpl] ?? {}).__merge(obj)))

local verify = @(list) list.filter(@(obj) obj?.hasVerified ?? true)

local itemsByArmies = ::Computed(@() applyTemplatesByArmies(divideByArmies(items.value), allItemTemplates.value))
local soldiersByArmies = ::Computed(@()
  applyTemplatesByArmies(divideByArmies(verify(soldiers.value)), allItemTemplates.value))
local squadsByArmies = ::Computed(@() divideByArmies(verify(squads.value)))

local curArmiesList = ::Computed(@() (gameProfile.value?.campaigns[curCampaign.value].armies ?? []).map(@(a) a.id))

local function mergeArmiesObjs(objsByArmies, armiesList) {
  local res = {}
  foreach(armyId in armiesList)
    res.__update(objsByArmies?[armyId] ?? {})
  return res
}

local curCampItems = ::Computed(@() mergeArmiesObjs(itemsByArmies.value, curArmiesList.value))
local curCampSoldiers = ::Computed(@() mergeArmiesObjs(soldiersByArmies.value, curArmiesList.value))
local curCampSquads = ::Computed(@() mergeArmiesObjs(squadsByArmies.value, curArmiesList.value))

return servProfile.__merge({
  curArmiesList = curArmiesList
  itemsByArmies = itemsByArmies
  soldiersByArmies = soldiersByArmies
  squadsByArmies = squadsByArmies
  curCampItems = curCampItems
  curCampSoldiers = curCampSoldiers
  curCampSquads = curCampSquads
}) 