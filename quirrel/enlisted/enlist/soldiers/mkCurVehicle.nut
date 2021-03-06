local { smallPadding, bigPadding, vehicleListCardSize, listCtors } = require("enlisted/enlist/viewConst.nut")
local { txtColor, bgColor } = listCtors
local { iconByGameTemplate, getItemName } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local { statusTier } = require("components/itemPkg.nut")

local comps = require("enlisted/enlist/components/defcomps.nut")
local txt = comps.txt
local note = comps.note

local hoverAddColor = Color(30,30,30,30)

local mkVehicleImage = @(vehicleInfo) (vehicleInfo?.gametemplate ?? "") == ""
  ? null
  : iconByGameTemplate(vehicleInfo.gametemplate, {
      width = vehicleListCardSize[0] - smallPadding * 2
      height = vehicleListCardSize[1] - smallPadding * 2
    })

local mkVehicleName = @(vehicleInfo, sf) {
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    txt({
      text = getItemName(vehicleInfo)
      color = txtColor(sf, false)
    })
    0 == (vehicleInfo?.crew ?? 0)
      ? null
      : note({
          text = " ".join([::loc("vehicleDetails/crew"), vehicleInfo.crew])
          color = txtColor(sf, false)
        })
  ]
}

local mkVehicleTier = @(vehicleInfo) {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = statusTier(vehicleInfo)
}

local function mkCurVehicle(
  openChooseVehicle = null, child = null, canSpawnOnVehicle = Watched(true),
  vehicleInfo = Watched(null)
) {
  return ::watchElemState(@(sf) {
    watch = [vehicleInfo, canSpawnOnVehicle]
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onClick = openChooseVehicle
    rendObj = ROBJ_SOLID
    color = canSpawnOnVehicle.value
      ? bgColor(sf, false)
      : bgColor(sf, false) + hoverAddColor
    padding = bigPadding
    children = vehicleInfo.value
      ? [
          mkVehicleImage(vehicleInfo.value)
          mkVehicleName(vehicleInfo.value, sf)
          mkVehicleTier(vehicleInfo.value)
          child
        ]
      : txt({
          hplace = ALIGN_CENTER
          text = ::loc("menu/vehicle/none")
          color = txtColor(sf, false)
        })
  })
}

return ::kwarg(mkCurVehicle) 