local {
  curArmy, curSquadId, curVehicle, curCampSoldiers,
  curSquadSoldiersInfo, getSoldierItem, objInfoByGuid
} = require("state.nut")

local curSoldierIdx = persist("curSoldierIdx", @() Watched(null))
local defSoldierGuid = persist("defSoldierGuid", @() Watched(null))

local function deselectSoldier() {
  curSoldierIdx(null)
  defSoldierGuid(null)
}
curArmy.subscribe(@(_) deselectSoldier())
curSquadId.subscribe(@(_) deselectSoldier())

local curSoldierInfo = ::Computed(@() curSquadSoldiersInfo.value?[curSoldierIdx.value]
  ?? curCampSoldiers.value?[defSoldierGuid.value])

local curSoldierGuid = ::Computed(@() curSoldierInfo.value?.guid)

local curSoldierMainWeapon = ::Computed(function() {
  local guid = curSoldierGuid.value
  if (!guid)
    return null

  return ["primary", "secondary", "side", "melee"]
    .reduce(@(res, slot) res ?? getSoldierItem(guid, slot), null)?.guid
})

local vehicleCapacity = ::Computed(@() objInfoByGuid.value?[curVehicle.value].crew ?? 0)

return {
  curSoldierIdx = curSoldierIdx
  curSoldierInfo = curSoldierInfo
  curSoldierGuid = curSoldierGuid
  soldiersList = curSquadSoldiersInfo
  vehicleCapacity = vehicleCapacity
  curSoldierMainWeapon = curSoldierMainWeapon
  defSoldierGuid = defSoldierGuid
}
 