local { logerr } = require("dagor.debug")
local client = require("enlisted/enlist/meta/clientApi.nut")
local servResearches = require("enlisted/enlist/meta/profile.nut").researches
local { configs } = require("enlisted/enlist/configs/configs.nut")
local {
  curArmies_list, armySquadsById, curSquadId, playerSelectedArmy
} = require("enlisted/enlist/soldiers/model/state.nut")
local squadsPresentation = require("enlisted/globals/researchSquadsPresentation.nut")
local prepareResearch = require("researchesPresentation.nut")
local { allItemTemplates } = require("enlisted/enlist/soldiers/model/all_items_templates.nut")

local isBuyLevelInProgress = ::Watched(false)
local isResearchInProgress = ::Watched(false)
local viewSquadId = Watched(null)
curSquadId.subscribe(@(id) viewSquadId(id))
viewSquadId(curSquadId.value)

local configResearches = ::Computed(function() {
  local src = configs.value?.researches ?? {}
  local res = {}
  foreach (armyId, armyConfig in src) {
    local presentList = squadsPresentation?[armyId]
    local armyPages = {}
    res[armyId] <- {
      squads = armyConfig?.squads
      pages = armyPages
    }
    foreach (squadId, pageList in armyConfig?.pages ?? {})
      armyPages[squadId] <- pageList.map(function(page, idx) {
        local pageContext = {
          templates = allItemTemplates.value?[armyId] ?? {}
        }
        page = (page ?? {}).__merge(presentList?[idx] ?? {})
        local prepared = (page?.tables ?? {}).values()
          .sort(@(a, b) a.line <=> b.line || a.tier <=> b.tier)
          .map(@(research) prepareResearch(research, pageContext))
        page.tables <- {}
        foreach (research in prepared)
          page.tables[research.research_id] <- research
        return page
      })
  }
  return res
})

local armiesResearches = ::Computed(function() {
  local res = {}
  foreach(armyId, armyConfig in configResearches.value) {
    local researchesMap = {}
    foreach(squadPages in armyConfig.pages)
      foreach(page in squadPages)
        foreach(research in page.tables)
          researchesMap[research.research_id] <- research

    res[armyId] <- {
      squads = armyConfig.squads
      pages = armyConfig.pages //pages by squadId
      researches = researchesMap
    }
  }
  return res
})

local stateResearches = ::Computed(@() servResearches.value.map(@(data, armyId) {
    guid = data.guid
    researched = data.researched ?? {}
    squadProgress = data.squadProgress ?? {}
  }))

local selectedResearch = Watched(null)
local selectedTable = persist("selectedTable", @() Watched(0))

local LOCKED = 0
local NOT_ENOUGH_EXP = 1
local CAN_RESEARCH = 2
local RESEARCHED = 3

local tableStructure = ::Computed(function() {
  local armyId = playerSelectedArmy.value
  local squadId = viewSquadId.value
  local curResearches = armiesResearches.value?[armyId]
  local ret = {
    armyId = armyId
    squadId = squadId
    tiersTotal = 0
    rowsTotal = 0
    researches = {}
    pages = []
  }

  if (!curResearches)
    return ret

  local pages = curResearches.pages?[squadId]
  if (pages == null)
    return ret

  ret.pages = pages
  ret.researches = curResearches.researches.filter(
    @(research) research.squad_id == squadId && research.page_id == selectedTable.value)

  foreach (research_id, def in ret.researches) {
    ret.tiersTotal = max(def.tier, ret.tiersTotal)
    ret.rowsTotal = max(def.line, ret.rowsTotal)
  }

  return ret
})

local isOpenResearch = @(research, researched)
  (research?.requirements ?? []).findindex(@(id) !researched?[id]) == null

local function isResearched(research, researched) {
  return researched?[research.research_id] ?? false
}

local allResearchStatus = ::Computed(function() {
  local res = {}
  foreach(armyId in curArmies_list.value) {
    local researches = armiesResearches.value?[armyId].researches ?? {}
    local researched = stateResearches.value?[armyId].researched ?? {}
    local squadProgress = stateResearches.value?[armyId].squadProgress
    local squads = armySquadsById.value?[armyId] ?? {}
    res[armyId] <- researches.map(@(research, researchId)
      isResearched(research, researched) ? RESEARCHED
        : (squads?[research.squad_id].locked ?? true) || !isOpenResearch(research, researched) ? LOCKED
        : research.price <= (squadProgress?[research.squad_id].points ?? 0) ? CAN_RESEARCH
        : NOT_ENOUGH_EXP)
  }
  return res
})

local allResearchProgress = ::Computed(function() {
  local res = {}
  foreach(armyId in curArmies_list.value) {
    local researches = armiesResearches.value?[armyId].researches ?? {}
    local researched = stateResearches.value?[armyId].researched ?? {}
    res[armyId] <- researched.reduce(@(cnt, val, key)
      val && (researches?[key].price ?? 0) > 0 ? cnt + 1 : cnt, 0)
  }
  return res
})

local researchStatuses = ::Computed(@() allResearchStatus.value?[playerSelectedArmy.value] ?? {})
local curArmySquadsProgress = ::Computed(@() stateResearches.value?[playerSelectedArmy.value].squadProgress)
local allSquadsPoints = ::Computed(@() (curArmySquadsProgress.value ?? {}).map(@(p) p.points))
local allSquadsLevels = ::Computed(@() (curArmySquadsProgress.value ?? {}).map(@(p) p.level))
local curSquadPoints = ::Computed(@() allSquadsPoints.value?[viewSquadId.value] ?? 0)

local curSquadProgress = ::Computed(function() {
  local res = {
    level = 0
    exp = 0
    points = 0
    nextLevelExp = 0
    levelCost = 0
  }.__update(curArmySquadsProgress.value?[viewSquadId.value] ?? {})

  local squadCfg = armiesResearches.value?[playerSelectedArmy.value].squads[viewSquadId.value]

  local levelExp = squadCfg?.levels[res.level].exp ?? 0
  local levelCost = squadCfg?.levels[res.level].levelCost ?? 0
  local needExp = levelExp - res.exp

  res.nextLevelExp = levelExp
  if (levelExp > 0 && needExp > 0 && levelCost > 0)
    res.levelCost = ::max(levelCost * needExp / levelExp, 1)

  return res
})

local function addArmySquadExp(armyId, exp, squadId) {
  if (!(armyId in stateResearches.value)) {
    logerr($"Unable to charge exp for army {armyId}")
    return
  }

  client.add_army_squad_exp_by_id(armyId, exp, squadId)
}

local function research(researchId) {
  if (isResearchInProgress.value)
    return
  local researchV = tableStructure.value.researches?[researchId]
  local armyId = tableStructure.value.armyId
  if (!researchV
      || researchStatuses.value?[researchId] != CAN_RESEARCH
      || !(armyId in stateResearches.value))
    return

  isResearchInProgress(true)
  client.research(armyId, researchId, @(res) isResearchInProgress(false))
}

local closestTargets = ::Computed(function() {
  local ret = {}
  foreach(key, val in armiesResearches.value) {
    if (!val.researches.len())
      continue

    local resVals = val.researches
      .values()
      .sort(@(b, a) a.line <=> b.line || a.tier <=> b.tier)

    foreach(idx, res in resVals) {
      local status = researchStatuses.value?[res.research_id]
      if (!ret?[key])
          ret[key] <- {}

      if (!ret[key]?[res.squad_id])
          ret[key][res.squad_id] <- {}

      if (!ret[key][res.squad_id]?[res.page_id])
        ret[key][res.squad_id][res.page_id] <- null

      if (status != LOCKED && status != RESEARCHED)
        ret[key][res.squad_id][res.page_id] = res
    }

    foreach(squad_id, resBySquad in ret[key]) {
      foreach(page_id, resByPage in resBySquad) {
        if (resByPage == null) {
          local topResearch = resVals
            .filter(@(res) res.squad_id == squad_id && res.page_id == page_id)
            .reduce(@(res, v) !res || res.line < v.line || res.tier < v.tier ? v : res, null)
          ret[key][squad_id][page_id] = topResearch
        }
      }
    }
  }
  return ret
})

local function buySquadLevel(cb = null) {
  if (isBuyLevelInProgress.value)
    return

  local { nextLevelExp = 0, exp = 0, levelCost = 0 } = curSquadProgress.value
  local needExp = nextLevelExp - exp
  if (needExp <= 0 || levelCost <= 0)
    return

  isBuyLevelInProgress(true)
  client.buy_squad_exp(playerSelectedArmy.value, viewSquadId.value, needExp, levelCost,
    function(res) {
      isBuyLevelInProgress(false)
      cb?()
    })
}

local function findAndSelectClosestTarget(...) {
  local tableResearches = tableStructure.value.researches
    .values()
    .sort(@(a, b) a.line <=> b.line || a.tier <=> b.tier)
  foreach(key, val in tableResearches) {
    local status = researchStatuses.value?[val.research_id]
    if (status == CAN_RESEARCH || status == NOT_ENOUGH_EXP) {
      selectedResearch(val)
      return
    }
  }
  selectedResearch({
    research_id = ""
    name = "researches/allResearchesResearchedName"
    description = "researches/allResearchesResearchedDescription"
  })
}
researchStatuses.subscribe(findAndSelectClosestTarget)
tableStructure.subscribe(findAndSelectClosestTarget)
findAndSelectClosestTarget()

console.register_command(
  function(exp) {
    if (playerSelectedArmy.value && viewSquadId.value != null) {
      addArmySquadExp(playerSelectedArmy.value, exp, viewSquadId.value)
      ::log_for_user($"Add exp for {playerSelectedArmy.value} / {viewSquadId.value}")
    } else
      ::log_for_user("Army or squad is not selected")
  },
  "meta.addCurSquadExp")

return {
  closestTargets = closestTargets
  configResearches = configResearches
  armiesResearches = armiesResearches
  selectedTable = selectedTable
  tableStructure = tableStructure
  selectedResearch = selectedResearch
  viewArmy = playerSelectedArmy
  viewSquadId = viewSquadId

  allResearchStatus = allResearchStatus
  allResearchProgress = allResearchProgress
  researchStatuses = researchStatuses
  allSquadsLevels = allSquadsLevels
  allSquadsPoints = allSquadsPoints
  curSquadPoints = curSquadPoints
  curArmySquadsProgress = curArmySquadsProgress
  curSquadProgress = curSquadProgress
  buySquadLevel = buySquadLevel

  research = research
  isResearchInProgress = isResearchInProgress
  addArmySquadExp = addArmySquadExp

  LOCKED = LOCKED
  NOT_ENOUGH_EXP = NOT_ENOUGH_EXP
  CAN_RESEARCH = CAN_RESEARCH
  RESEARCHED = RESEARCHED

  BALANCE_ATTRACT_TRIGGER = "army_balance_attract"
}
 