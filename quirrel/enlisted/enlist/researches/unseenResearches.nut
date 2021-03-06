local { allResearchStatus, CAN_RESEARCH, RESEARCHED } = require("researchesState.nut")
local { settings } = require("enlist/options/onlineSettings.nut")

const SEEN_ID = "seen/researches"

local seen = ::Computed(@() settings.value?[SEEN_ID])

local unseen = ::Computed(@() allResearchStatus.value
  .map(@(armyResearches, armyId) armyResearches
    .filter(@(status, id) status == CAN_RESEARCH && !(seen.value?[armyId][id] ?? false))))

local function markSeen(armyId, researchesList) {
  local filtered = researchesList.filter(@(id) unseen.value?[armyId][id] ?? false)
  if (filtered.len() == 0)
    return

  local saved = settings.value?[SEEN_ID] ?? {}
  local armySaved = saved?[armyId] ?? {}
  //clear all researched from seen in profile
  local armyNewData = armySaved.filter(@(_, id) (allResearchStatus.value?[armyId][id] ?? RESEARCHED) != RESEARCHED)
  foreach(id in filtered)
    armyNewData[id] <- true
  settings(function(s) {
    local newSaved = clone saved
    newSaved[armyId] <- armyNewData
    s[SEEN_ID] <- newSaved
  })
}

local function resetSeen() {
  local reseted = (settings.value?[SEEN_ID] ?? []).len()
  if (reseted > 0)
    settings(@(s) delete s[SEEN_ID])
  return reseted
}

console.register_command(@() console_print("Reseted armies count = {0}".subst(resetSeen())), "meta.resetSeenResearches")

return {
  unseenResearches = unseen
  markSeen = markSeen
} 