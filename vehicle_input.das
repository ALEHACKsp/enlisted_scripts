require game.es.events
require vehicle
require EnlistedWeapon
require game.utils.hero
require app
require ecs

[es (tag=gameClient, track=turret_input_dot_shootFlag)]
def vehicle_turret_broken_notification_es(evt : Event;
                                          turret_input_dot_shootFlag : ecs::BoolList;
                                          turret_can_shoot : TurretCanShoot;
                                          local_controls_state : VehicleControlsState;
                                          shootingBlockNotificationTime : int;
                                      var lastBlockNotificationAtTime : float&)
  let curTime = get_sync_time()
  let nextNofiticationAtTime = lastBlockNotificationAtTime + float(shootingBlockNotificationTime)
  if curTime < nextNofiticationAtTime || !can_control_turrets(local_controls_state)
    return
  let hero = get_controlled_hero()
  for i in iter_range(turret_input_dot_shootFlag)
    if turret_input_dot_shootFlag[i] && !can_shoot_turret(turret_can_shoot, i)
      sendEvent(hero, [[CmdHeroLogEvent event="vehicle_turret_shoot_blocked", text="vehicle/vehicle_turret_shoot_blocked", ttl=shootingBlockNotificationTime]])
      lastBlockNotificationAtTime = get_sync_time()
      return