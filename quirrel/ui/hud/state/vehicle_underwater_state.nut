local vehicleUnderWaterEndTime = persist("vehicleUnderWaterEndTime",@() Watched(-1.0))
local vehicleUnderWaterMaxTime = persist("vehicleUnderWaterMaxTime",@() Watched(-1.0))
local controlledHeroEid = require("hero_state_es.nut").controlledHeroEid

local function trackSelectedVehicle(evt,eid,comp){
  if (eid == controlledHeroEid.value && comp["human_anim.vehicleSelected"] == INVALID_ENTITY_ID)
    vehicleUnderWaterEndTime(-1)
}

::ecs.register_es("hero_vehicle_under_water_ui_es", { onChange = trackSelectedVehicle, onInit = trackSelectedVehicle}, {
    comps_track = [
      ["human_anim.vehicleSelected", ::ecs.TYPE_EID]
    ]
  },
  {tags="gameClient"})

local function trackVehicleUnderWater(evt,eid,comp){
  local hero = controlledHeroEid.value
  local heroVehicle = ::ecs.get_comp_val(hero, "human_anim.vehicleSelected")

  if (heroVehicle == eid){
    if (comp["underWaterStartTime"] > 0) {
      vehicleUnderWaterEndTime(comp["underWaterStartTime"] + comp["underWaterMaxTime"])
      vehicleUnderWaterMaxTime(comp["underWaterMaxTime"])
    }
    else
      vehicleUnderWaterEndTime(-1.0)
  }
}

::ecs.register_es("vehicleUnderWaterEndTimeEs",{
  onInit = trackVehicleUnderWater,
  onChange = trackVehicleUnderWater,
  [::ecs.EventEntityDestroyed] = @(evt,eid,comp) vehicleUnderWaterEndTime(-1.0)
  }, {
    comps_track=[["underWaterStartTime",::ecs.TYPE_FLOAT]]
    comps_ro = [["underWaterMaxTime",::ecs.TYPE_FLOAT],["last_driver",::ecs.TYPE_EID]]
  })

return {
  vehicleUnderWaterEndTime = vehicleUnderWaterEndTime,
  vehicleUnderWaterMaxTime = vehicleUnderWaterMaxTime
}
 