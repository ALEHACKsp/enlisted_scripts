local { mkMainSoldiersBlock } = require("enlisted/enlist/soldiers/mkSoldiersList.nut")
local mkCurVehicle = require("enlisted/enlist/soldiers/mkCurVehicle.nut")
local {
  soldiersList, curSoldierIdx, canSpawnOnVehicleBySquad, vehicleInfo, squadIndexForSpawn
} = require("enlisted/ui/hud/state/respawnState.nut")

local canSpawnOnVehicle = ::Computed(@()
  canSpawnOnVehicleBySquad.value?[squadIndexForSpawn.value] ?? false)

return mkMainSoldiersBlock({
  soldiersListWatch = soldiersList
  hasVehicleWatch = ::Computed(@() vehicleInfo.value != null)
  curSoldierIdxWatch = curSoldierIdx
  curVehicleUi = mkCurVehicle({ canSpawnOnVehicle, vehicleInfo })
  canDeselect = false
})
 