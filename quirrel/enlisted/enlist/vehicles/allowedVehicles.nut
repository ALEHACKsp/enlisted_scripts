local deep_merge = require("std/deep.nut")._merge
local { squadsCfgById } = require("enlisted/enlist/soldiers/model/config/squadsConfig.nut")
local { armiesResearches } = require("enlisted/enlist/researches/researchesState.nut")
local armyEffects = require("enlisted/enlist/soldiers/model/armyEffects.nut")


local allowedByEffects = ::Computed(@()
  squadsCfgById.value.map(function(squadsCfg, armyId) {
    local vehicleEff = armyEffects.value?[armyId].vehicle_usage ?? {}
    return squadsCfg.map(function(squad, squadId) {
      local res = {}
      foreach(vehicle in vehicleEff?[squadId] ?? [])
        res[vehicle] <- true
      local squadVehicle = squad?.startVehicle ?? "" //compatibility with prev profile version. 30.10.2020
      if (squadVehicle != "")
        res[squadVehicle] <- true
      foreach(vehicle in squad?.allowedVehicles ?? [])
        res[vehicle] <- true
      return res
    })
  }))

local allowedByResearches = ::Computed(@() armiesResearches.value
  .map(function(armyResearches, armyId) {
    local res = {}
    local { researches } = armyResearches
    foreach(research in researches)
      foreach(squadId, vehicles in research.effect?.vehicle_usage ?? {}) {
        if (vehicles.len() == 0)
          continue
        if (squadId not in res)
          res[squadId] <- {}
        foreach(vehicle in vehicles)
          res[squadId][vehicle] <- false
      }
    return res
  }))

return ::Computed(@() deep_merge(allowedByResearches.value, allowedByEffects.value))
 