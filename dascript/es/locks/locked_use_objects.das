require ecs
require game.es.vehicle.vehicle_events

[es (on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=locked_use_object_dot_lockGrenadeRethrowing)]
def lock_grenade_rethrowing_set_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var human_use_object_dot_lockGrenadeRethrowing : bool&)
    human_use_object_dot_lockGrenadeRethrowing = true

[es (on_event=EventEntityDestroyed, REQUIRE=locked_use_object_dot_lockGrenadeRethrowing)]
def lock_grenade_rethrowing_unset_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var human_use_object_dot_lockGrenadeRethrowing : bool&)
    human_use_object_dot_lockGrenadeRethrowing = false


[es (on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=locked_use_object_dot_lockVehicleUse)]
def lock_vehicle_use_set_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var human_use_object_dot_lockVehicleUse : bool&; var human_vehicle_dot_can_take_seat : bool&)
    human_use_object_dot_lockVehicleUse = true
    human_vehicle_dot_can_take_seat = false

[es (on_event=EventEntityDestroyed, REQUIRE=locked_use_object_dot_lockVehicleUse)]
def lock_vehicle_use_unset_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var human_use_object_dot_lockVehicleUse : bool&; var human_vehicle_dot_can_take_seat : bool&)
    human_use_object_dot_lockVehicleUse = false
    human_vehicle_dot_can_take_seat = true

[es(track=human_use_object_dot_lockVehicleUse)]
def force_exit_from_vehicle_on_lock(evt:Event; eid : EntityId; human_use_object_dot_lockVehicleUse : bool; human_anim_dot_vehicleSelected : EntityId)
  if human_use_object_dot_lockVehicleUse && !!human_anim_dot_vehicleSelected
    sendEvent(human_anim_dot_vehicleSelected, [[CmdKickFromVehicle eid=eid]])

[es (on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=locked_use_object_dot_lockStationaryGunUse)]
def lock_stationary_gun_use_set_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var human_use_object_dot_lockStationaryGunUse : bool&)
    human_use_object_dot_lockStationaryGunUse = true

[es (on_event=EventEntityDestroyed, REQUIRE=locked_use_object_dot_lockStationaryGunUse)]
def lock_stationary_gun_use_unset_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var human_use_object_dot_lockStationaryGunUse : bool&)
    human_use_object_dot_lockStationaryGunUse = false

[es (on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=locked_use_object_dot_lockDoorUse)]
def lock_door_use_set_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var human_use_object_dot_lockDoorUse : bool&)
    human_use_object_dot_lockDoorUse = true

[es (on_event=EventEntityDestroyed, REQUIRE=locked_use_object_dot_lockDoorUse)]
def lock_door_use_unset_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var human_use_object_dot_lockDoorUse : bool&)
    human_use_object_dot_lockDoorUse = false
