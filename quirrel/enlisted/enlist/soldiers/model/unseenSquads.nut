local { armySquadsById } = require("state.nut")
local { settings, onlineSettingUpdated } = require("enlist/options/onlineSettings.nut")
local { squadsCfgById } = require("config/squadsConfig.nut")

const SEEN_ID = "seen/squads"

local seen = ::Computed(@() settings.value?[SEEN_ID])

local squadsToCheck = ::Computed(@() squadsCfgById.value.map(@(squadsList, armyId)
  squadsList
    .filter(@(s) (s?.unlockCost ?? 0) > 0)
    .map(@(_, squadId) armySquadsById.value?[armyId][squadId])))

local unseen = ::Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}
  return squadsToCheck.value.map(@(squadsList, armyId)
    squadsList.map(@(squad, squadId) squad != null && !(squad?.locked ?? false) && !(squadId in seen.value?[armyId])))
})

local function resetSeen() {
  settings[SEEN_ID] <- null
}

local function markSeen(armyId, squadIdsList) {
  local filtered = squadIdsList.filter(@(squadId) unseen.value?[armyId][squadId] ?? false)
  if (filtered.len() == 0)
    return
  settings(function(set) {
    local saved = clone (set?[SEEN_ID] ?? {})
    local armySaved = clone (saved?[armyId] ?? {})
    filtered.each(@(squadId) armySaved[squadId] <- true)
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

console.register_command(resetSeen, "meta.resetSeenSquads")

return {
  unseenSquads = unseen
  markSeenSquads = markSeen
} 