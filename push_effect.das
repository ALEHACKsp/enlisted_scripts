require ecs
require math.base
require game.es.events
require DagorMath
require GridCollision
require game.es.effects.effect_controller_common

[es(tag=server, track=(effect_controller_dot_state, effect_scale_randomizer_dot_scale))]
def convert_spawn_rate_to_push(evt : Event; effect_controller_dot_state: int;  effect_controller_dot_states: Array;
                               effect_scale_randomizer_dot_scale : float;
                               push_effect_dot_spawnRateThreshold : float; var push_effect_dot_active : bool&; var push_effect_dot_scale : float&)
  let stateParams = get_effect_state_params(effect_controller_dot_states, effect_controller_dot_state)
  let spawnRate = 0.5 * (stateParams.spawnRate.x + stateParams.spawnRate.y)

  push_effect_dot_active = spawnRate > push_effect_dot_spawnRateThreshold
  push_effect_dot_scale = effect_scale_randomizer_dot_scale

[es(tag=server, no_order)]
def push_effect_update(info : UpdateStageInfoAct; transform : float3x4; push_effect_dot_active : bool;
                       push_effect_dot_distance, push_effect_dot_vehicleDistance, push_effect_dot_distancePower : float;
                       push_effect_dot_powerLimits : float2; push_effect_dot_direction : float3;
                       push_effect_dot_vehicleEnergyScale, push_effect_dot_shipEnergyScale, push_effect_dot_immunityAmount : float;
                       push_effect_dot_speed, push_effect_dot_scale : float)
  if !push_effect_dot_active
    return
  let center = transform[3]
  for_each_object_in_grid(GridType GT_DEFAULT, BBox3(center, push_effect_dot_distance)) <| $(it:TraceableGridCollision#)
    let isHuman = it.eid |> has("human_net_phys")
    let maxDist = isHuman ? push_effect_dot_distance : push_effect_dot_vehicleDistance
    var dir = it.pos - center
    if length_sq(dir) > square(maxDist)
      return
    let dirLen = length(dir)
    dir *= safeinv(dirLen)
    let power = pow(1f - safediv(dirLen, maxDist), push_effect_dot_distancePower) * push_effect_dot_scale
    let fixedPower = clamp(power, push_effect_dot_powerLimits.x, push_effect_dot_powerLimits.y)
    if isHuman
      let vel = dir + push_effect_dot_direction * fixedPower * push_effect_dot_speed
      sendEvent(it.eid, [[CmdPushPhys vel=vel, push_immunity=push_effect_dot_immunityAmount]])
    else
      let scaledDir = dir + push_effect_dot_direction * fixedPower
      if it.eid |> has("vehicle_net_phys")
        sendEvent(it.eid, [[CmdVehiclePushPhys energyScaledDir=scaledDir * push_effect_dot_vehicleEnergyScale, arm=center, duration=0.0]])
      elif it.eid |> has("ship_net_phys")
        sendEvent(it.eid, [[CmdShipPushPhys energyScaledDir=scaledDir * push_effect_dot_shipEnergyScale, arm=center, duration=0.0]])
