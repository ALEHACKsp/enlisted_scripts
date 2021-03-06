local {
  settings, onlineSettingUpdated
} = require("enlist/options/onlineSettings.nut")
local { soldiersByArmies } = require("enlisted/enlist/meta/profile.nut")
local { curArmy } = require("state.nut")

const SEEN_ID = "seen/soldiers"

local seen = ::Computed(@() settings.value?[SEEN_ID])

local unseen = ::Computed(@() onlineSettingUpdated.value
  ? soldiersByArmies.value.map(function(list, armyId) {
      local seenSoldiers = seen.value?[armyId] ?? {}
      return list.reduce(function(res, soldier) {
        local guid = soldier.guid
        if (!(guid in seenSoldiers))
          res[guid] <- true
        return res
      }, {})
    })
  : {})

local unseenCurrent = ::Computed(@() unseen.value?[curArmy.value] ?? {})

local function markSeen(armyId, soldierGuid) {
  if (!(seen.value?[armyId][soldierGuid] ?? false))
    settings(function(set) {
      local saved = clone (set?[SEEN_ID] ?? {})
      local armySaved = clone (saved?[armyId] ?? {})
      armySaved[soldierGuid] <- true
      saved[armyId] <- armySaved
      set[SEEN_ID] <- saved
    })
}

local function markUnseen(armyId, soldierGuid) {
  if (seen.value?[armyId][soldierGuid] ?? false)
    settings(function(set) {
      local saved = clone (set?[SEEN_ID] ?? {})
      local armySaved = clone (saved?[armyId] ?? {})
      delete armySaved[soldierGuid]
      saved[armyId] <- armySaved
      set[SEEN_ID] <- saved
    })
}

return {
  unseenSoldiers = unseenCurrent
  markSoldierSeen = markSeen
  markSoldierUnseen = markUnseen
}
 