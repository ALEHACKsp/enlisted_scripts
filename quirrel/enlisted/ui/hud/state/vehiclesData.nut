local armyData = require("enlisted/ui/hud/state/armyData.nut")

local function getCrewCount(template) {
  local gametemplate = template == null ? null
    : ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  if (gametemplate == null)
    return 0
  return gametemplate.getCompValNullable("vehicle_seats.seats")?.len() ?? 0
}

local function collectVehicleData(vehicle, armyId, squadId, country) {
  local res = {}
  foreach(key in ["guid", "gametemplate"])
    res[key] <- vehicle[key]

  return res.__update({
    armyId = armyId
    squadId = squadId
    country = country
    crew = getCrewCount(vehicle.gametemplate)
  })
}

local vehicles = Computed(function() {
  local res = {}
  local squadsList = armyData.value?.squads
  if (squadsList == null)
    return res

  local armyId = armyData.value.armyId
  local country = armyData.value.country
  foreach(squad in squadsList) {
    local vehicle = squad.curVehicle
    if (vehicle != null)
      res[vehicle.guid] <- collectVehicleData(vehicle, armyId, squad.squadId, country)
  }
  return res
})

return vehicles 