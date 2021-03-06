local vehicle = require("vehicle")
local get_sync_time = require("net").get_sync_time
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")

local vehicleSeats = persist("vehicleSeats", @() Watched({
  owners = []
  controls = []
  order = []
  seats = []
  data = []
  switchSeatsTime = 0.0
  switchSeatsTotalTime = 0.0
}))

local function resetState() {
  vehicleSeats.update({
    vehicle = INVALID_ENTITY_ID
    owners = []
    controls = []
    order = []
    seats = []
    data = []
    switchSeatsTime = 0.0
    switchSeatsTotalTime = 0.0
  })
}

local function trackComponents(evt, eid, comp) {
  local hero = watchedHeroEid.value
  local vehicleWithWatched = ::ecs.get_comp_val(hero, "human_anim.vehicleSelected")

  if (vehicleWithWatched == INVALID_ENTITY_ID) {
    resetState()
    return
  }

  if (eid != vehicleWithWatched)
    return

  local owners = comp["vehicle_seats_owners"].getAll() ?? []
  local controls = comp["vehicle_seats_controls"].getAll() ?? []
  local order = comp["vehicle_seats_order"].getAll() ?? []
  local seats = comp["vehicle_seats.seats"].getAll() ?? []

  local arr = []
  for (local i = 0; i < order.len(); ++i) {
    local seatNo = order[i].seatNo
    arr.append({
      seatNo = seatNo
      owner = owners[i]
      controls = controls[i]
      order = order[i]
      seat = seats[i]
    })
  }
  arr.sort(@(a, b) a.seatNo <=> b.seatNo)

  vehicleSeats.update(function (v) {
    v.owners = owners
    v.controls = controls
    v.order = order
    v.seats = seats
    v.data = arr
  })
}

::ecs.register_es("vehicle_seats_ui_es",
  {
    onChange = trackComponents,
    onInit = trackComponents,
    onDestroy = @(...) resetState(),
    [::ecs.sqEvents.CmdTrackVehicleWithWatched] = trackComponents,
  },
  {
    comps_track = [
      ["vehicle_seats_owners", null],
      ["vehicle_seats_controls", null],
      ["vehicle_seats_order", null],
      ["vehicle_seats.seats", ::ecs.TYPE_SHARED_ARRAY],
    ]
    comps_rq = ["vehicleWithWatched"]
  }
)

::ecs.register_es("vehicle_seats_on_chage_seat_ui_es",
  {
    [vehicle.EventOnStartVehicleChangeSeat] = function(evt, eid, comp) {
      local curTime = get_sync_time()
      local timeMult = ::ecs.get_comp_val(watchedHeroEid.value, "entity_mods.vehicleChangeSeatTimeMult") ?? 1.0
      local totalTime = comp["vehicle_seats_switch_time.totalSwitchTime"] * timeMult
      local deltaTime = curTime - vehicleSeats.value.switchSeatsTime
      if (deltaTime < totalTime)
        return;
      vehicleSeats.update(function (v) {
        v.switchSeatsTime = curTime
        v.switchSeatsTotalTime = totalTime
      })
    },
    onChange = function(evt, eid, comp) {
      vehicleSeats.update(function (v) {
        v.switchSeatsTime = 0
        v.switchSeatsTotalTime = 0
      })
    }
  },
  {
    comps_ro = [
      ["vehicle_seats_switch_time.totalSwitchTime", ::ecs.TYPE_FLOAT],
    ]
    comps_track = [
      ["vehicle_seats_owners", null]
    ]
    comps_rq = ["heroVehicle"]
  }
)

::ecs.register_es("vehicle_changed_ui_es", {
  onInit = @(evt, eid, comp) ::ecs.g_entity_mgr.sendEvent(comp["human_anim.vehicleSelected"], ::ecs.event.CmdTrackHeroVehicle()),
  onChange = @(evt, eid, comp) ::ecs.g_entity_mgr.sendEvent(comp["human_anim.vehicleSelected"], ::ecs.event.CmdTrackHeroVehicle()),
},
{
  comps_track = [["human_anim.vehicleSelected", ::ecs.TYPE_EID]]
  comps_rq = ["hero"]
})

::ecs.register_es("vehicle_with_watched_changed_ui_es", {
  onInit = @(evt, eid, comp) ::ecs.g_entity_mgr.sendEvent(comp["human_anim.vehicleSelected"], ::ecs.event.CmdTrackVehicleWithWatched()),
  onChange = @(evt, eid, comp) ::ecs.g_entity_mgr.sendEvent(comp["human_anim.vehicleSelected"], ::ecs.event.CmdTrackVehicleWithWatched()),
},
{
  comps_track = [["human_anim.vehicleSelected", ::ecs.TYPE_EID]]
  comps_rq = ["watchedByPlr"]
})

return vehicleSeats 