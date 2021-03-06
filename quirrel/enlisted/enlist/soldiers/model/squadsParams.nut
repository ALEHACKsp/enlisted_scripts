local { tablesCombine } = require("std/underscore.nut")
local { squadsCfgById } = require("config/squadsConfig.nut")
local armyEffects = require("armyEffects.nut")

local function calcSquadParams(effects, squadId, squad) {
  local size = squad.size + (effects?.squad_size[squadId] ?? 0)
  return {
    size = size
    maxClasses = tablesCombine(squad.maxClasses,
      effects?.squad_class_limit[squadId] ?? {},
      @(a, b) ::min(a + b, size),
      0)
  }
}

local squadsParams = ::Computed(function() {
  local effects = armyEffects.value
  return squadsCfgById.value.map(
    @(armySquads, armyId) armySquads.map(
      @(squad, squadId) calcSquadParams(effects?[armyId], squadId, squad)))
})

return squadsParams 