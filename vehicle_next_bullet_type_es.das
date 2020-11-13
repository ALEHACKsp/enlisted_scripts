require ecs
require app
require DaWeaponProps
require Gun
require EnlistedWeapon

[es (tag=server, on_event=CmdNextBulletIdRequest, REQUIRE=turret_control)]
def next_bullet_id_request_es(evt: Event; eid: EntityId)
  let vehicleEid = eid
  ecs::query() <| $[es](gun : IGunHolder; var nextBulletId: int&; var currentBulletId : int&; var gun_dot_curShellId: ShellPropIds;
                        turret_dot_owner: EntityId; gun_dot_shell_prop_ids: GunShellPropIds; gun_dot_ammo : int;
                        turret_dot_canChangeShellDuringReload : bool = false)
    if turret_dot_owner == vehicleEid
      nextBulletId = (nextBulletId + 1) % length(gun_dot_shell_prop_ids)

      let isReloadChange = turret_dot_canChangeShellDuringReload && gun.nextShotAtTime > get_sync_time()
      if gun_dot_ammo == 0 || isReloadChange
        currentBulletId = nextBulletId
        gun_dot_curShellId = gun_dot_shell_prop_ids[currentBulletId]

[es (track=gun_dot_curShellId, REQUIRE=gun_dot_curShellId, before=turret_on_change_current_shell_es)]
def change_bullet_id_during_reload_delay(evt: Event;
                                         var gun : IGunHolder;
                                         gun_dot_ammo : int;
                                         var turret_dot_lastShellChangeTime : float&;
                                         turret_dot_shellChangeInReloadDelay : float = 1.0)
  let curTime = get_sync_time()
  let nextShotAtTime = gun.nextShotAtTime

  if gun_dot_ammo == 0 || nextShotAtTime <= curTime
    return

  let delay = min(curTime - turret_dot_lastShellChangeTime, turret_dot_shellChangeInReloadDelay)
  turret_dot_lastShellChangeTime = curTime
  gun_holder_force_next_shot_time(gun, nextShotAtTime + delay)

[es (tag=server, track=gun_dot_ammo, on_event=(EventEntityCreated, EventComponentsAppear), after=gun_init_es)]
def turret_bullet_id_es(evt: Event;
                        var nextBulletId: int&;
                        var currentBulletId: int&;
                        var lastBulletId: int&;
                        var gun_dot_curShellId: ShellPropIds&;
                        gun_dot_shell_prop_ids: GunShellPropIds;
                        gun_dot_ammo_by_shell: IntList;
                        gun_dot_ammo: int)
  lastBulletId = currentBulletId
  if currentBulletId == nextBulletId && gun_dot_ammo == 0
    for i in iter_range(gun_dot_shell_prop_ids)
      if i != currentBulletId && gun_dot_ammo_by_shell[i] >= 1
        nextBulletId = i
        break
  currentBulletId = nextBulletId
  gun_dot_curShellId = gun_dot_shell_prop_ids[currentBulletId]

[es (tag=gameClient, after=gun_init_es, on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_gun_events_es(evt: Event;
                          gun_dot_shell_prop_ids: GunShellPropIds;
                          currentBulletId: int;
                          var bulletName: das_string;
                          var bulletType: das_string;
                          var nextBulletName: das_string;
                          var nextBulletType: das_string)
  let bulletId = gun_dot_shell_prop_ids[currentBulletId]
  let shellId = int(bulletId.shellId)
  let entProps = get_shell_entity_props(shellId)
  nextBulletName := entProps?.bulletName ?? ""
  nextBulletType := entProps?.bulletType ?? ""
  bulletName := nextBulletName
  bulletType := nextBulletType

def set_bullet_type_name(shell_prop_ids; var out_type : das_string; var out_name: das_string)
  let shellId = int(shell_prop_ids.shellId)
  let entProps = get_shell_entity_props(shellId)
  out_name := entProps?.bulletName ?? ""
  out_type := entProps?.bulletType ?? ""

[es (tag=gameClient, track=nextBulletId)]
def vehicle_on_next_bullet_id_changed_es(evt: Event;
                                         nextBulletId: int;
                                         gun_dot_shell_prop_ids: GunShellPropIds;
                                         var nextBulletName: das_string;
                                         var nextBulletType: das_string)
  set_bullet_type_name(gun_dot_shell_prop_ids[nextBulletId], nextBulletType, nextBulletName)

[es (tag=gameClient, track=currentBulletId)]
def vehicle_on_current_bullet_id_changed(evt: Event;
                                         currentBulletId : int;
                                         gun_dot_shell_prop_ids: GunShellPropIds;
                                         var bulletName: das_string;
                                         var bulletType: das_string)
  set_bullet_type_name(gun_dot_shell_prop_ids[currentBulletId], bulletType, bulletName)
