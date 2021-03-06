local { settings, onlineSettingUpdated } = require("enlist/options/onlineSettings.nut")
local { curArmy } = require("state.nut")
local {
  availArmyClasses, allSoldiersClasses, armyTrainings
} = require("enlisted/enlist/soldiers/model/trainingState.nut")

const SEEN_ID = "seen/classes"

local seen = ::Computed(@() settings.value?[SEEN_ID])

local unseen = ::Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}
  return allSoldiersClasses.value.map(function(list, armyId) {
    if (armyId in armyTrainings.value)
      return {}
    local seenClasses = seen.value?[armyId] ?? {}
    local availClasses = availArmyClasses.value?[armyId] ?? {}
    return list.reduce(function(res, name) {
      if (!(name in seenClasses) && (name in availClasses))
        res[name] <- true
      return res
    }, {})
  })
})

local unseenCurrent = ::Computed(@() unseen.value?[curArmy.value] ?? {})

local function markSeen(armyId, classesList) {
  local seenClasses = seen.value?[armyId] ?? {}
  local filtered = classesList.filter(@(name) !(name in seenClasses))
  if (filtered.len() == 0)
    return
  settings(function(set) {
    local saved = clone (set?[SEEN_ID] ?? {})
    local armySaved = clone (saved?[armyId] ?? {})
    filtered.each(@(name) armySaved[name] <- true)
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

local function markUnseen(armyId, classesList) {
  local seenClasses = seen.value?[armyId] ?? {}
  local filtered = classesList.filter(@(name) name in seenClasses)
  if (filtered.len() == 0)
    return
  settings(function(set) {
    local saved = clone (set?[SEEN_ID] ?? {})
    local armySaved = clone (saved?[armyId] ?? {})
    filtered.each(@(name) name in armySaved ? delete armySaved[name] : null)
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })

}

console.register_command(@() settings(@(s) delete s[SEEN_ID]), "meta.resetSeenClasses")
console.register_command(@(name) markSeen(curArmy.value, name), "meta.markSeenClass")
console.register_command(@(name) markUnseen(curArmy.value, name), "meta.markUnseenClass")

return {
  allUnseenClasses = unseen
  unseenClasses = unseenCurrent
  markSeenClasses = markSeen
  markUnseenClasses = markUnseen
} 