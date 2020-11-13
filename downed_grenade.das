require ecs
require net
require HumanPhys
require EnlistedHuman
require game.es.events
require DaWeapons
require DaWeaponProps
require EnlistedWeapon

def reload_projectile(owner_eid : EntityId;
                      grenade_eid : EntityId;
                      gun_dot_ammo : int;
                      prev_ammo_type : int;
                      gun_dot_curShellId : ShellPropIds;
                      gun_dot_wishAmmoItemType: int;
                      var gun_dot_serverAmmo : int&)
  if !is_server()
    return
  if prev_ammo_type != gun_dot_wishAmmoItemType
    destroyEntity(obtain_owned_projectile_entity(owner_eid, HUWeaponSlots EWS_GRENADE))
  if reload_impl(owner_eid, int(HUWeaponSlots EWS_GRENADE), ReloadAmmoMode CONSUME)
    reload_projectile(owner_eid, grenade_eid, gun_dot_curShellId)
    gun_dot_serverAmmo = gun_dot_ammo

def try_enable_throw_mode(owner_eid : EntityId;
                          grenade_eid : EntityId;
                          shoot : bool;
                          is_fast_throw_exclusive: bool;
                          ct : HumanControlState;
                          gun_dot_ammo : int;
                          gun_dot_totalAmmo : int;
                          gun_dot_curShellId : ShellPropIds;
                          var gun_dot_wishAmmoItemType: int&;
                          var gun_dot_serverAmmo : int&;
                          var human_weap_dot_throwMode : bool&)
  if !shoot
    return false

  let prevAmmoType = gun_dot_wishAmmoItemType

  if is_fast_throw_exclusive
    human_weap_dot_throwMode = gun_dot_totalAmmo > 0 || gun_dot_ammo > 0
  else
    var newAmmoType : int
    human_weap_dot_throwMode = search_grenade_for_fast_throw(newAmmoType, owner_eid, grenade_eid, prevAmmoType, ct)
    if human_weap_dot_throwMode
      gun_dot_wishAmmoItemType = newAmmoType

  if human_weap_dot_throwMode
    reload_projectile(owner_eid, grenade_eid, gun_dot_ammo, prevAmmoType,
      gun_dot_curShellId, gun_dot_wishAmmoItemType, gun_dot_serverAmmo)

  return human_weap_dot_throwMode

def downed_grenade_update(eid : EntityId;
                          transform : float3x4;
                          at_time : float;
                          dt : float;
                          is_for_real : bool;
                          isThrowingAllowed : bool;
                          ct : HumanControlState;
                          human_net_phys : HumanActor;
                          human_weap_dot_gunEids : EidList;
                          human_weap_dot_fastThrowExclusive : bool;
                          var human_weap_dot_throwMode : bool&)
  if !is_for_real
    return

  let grenadeSlotEid = human_weap_dot_gunEids[int(HUWeaponSlots EWS_GRENADE)]

  query(grenadeSlotEid) <| $[es] (grenade_thrower : GrenadeThrower;
                                  gun_dot_ammo : int;
                                  gun_dot_totalAmmo : int;
                                  gun_dot_curShellId : ShellPropIds;
                                  var gun_dot_wishAmmoItemType: int&;
                                  var gun_dot_serverAmmo : int&)
    let shoot = isThrowingAllowed && is_control_bit_set(ct, HumanPhysControlType HCT_THROW)

    if (!human_weap_dot_throwMode &&
        !try_enable_throw_mode(eid, grenadeSlotEid, shoot, human_weap_dot_fastThrowExclusive, ct,
                               gun_dot_ammo, gun_dot_totalAmmo, gun_dot_curShellId, gun_dot_wishAmmoItemType,
                               gun_dot_serverAmmo, human_weap_dot_throwMode))
      return

    var gctrl : GunControls
    gctrl.shoot = shoot
    let dir = normalize(float3(0.14, -0.99, 0.0)) // approximative down
    send_immediate_weap_phys_update(grenadeSlotEid, eid, at_time, dt, is_for_real, int(HUWeaponSlots EWS_GRENADE), gctrl,
                                    dir, dir, human_net_phys.phys.currentState.velocity, transform, transform)

    update_reload(eid, at_time, dt)

    if grenade_thrower.state == (GrenadeThrowState GTS_READY)
      human_weap_dot_throwMode = false

[es (REQUIRE=(human_weap,canDropGrenadeInDowned), REQUIRE_NOT=human_input)]
def downed_grenade_thrower_post_phys(evt : CmdPostPhysUpdate;
                                     eid : EntityId;
                                     isAlive : bool;
                                     isDowned : bool;
                                     human_net_phys : HumanActor;
                                     transform : float3x4;
                                     human_weap_dot_gunEids : EidList;
                                     var human_weap_dot_throwMode : bool&;
                                     human_weap_dot_lockedGrenadeThrowingCounter : int = 0;
                                     human_weap_dot_fastThrowExclusive : bool = true)
  if !isAlive || !isDowned
    return
  let atTime = float(evt.tick + 1) * evt.dt
  let isThrowingAllowed = human_weap_dot_lockedGrenadeThrowingCounter == 0
  downed_grenade_update(eid, transform, atTime, evt.dt, evt.isForReal, isThrowingAllowed,
                        human_net_phys.phys.appliedCT, human_net_phys, human_weap_dot_gunEids,
                        human_weap_dot_fastThrowExclusive, human_weap_dot_throwMode)


[es (REQUIRE=(human_input,human_weap,canDropGrenadeInDowned), after=after_net_phys_sync)]
def downed_grenade_thrower(info : UpdateStageInfoAct;
                           eid : EntityId;
                           isAlive : bool;
                           isDowned : bool;
                           human_net_phys : HumanActor;
                           transform : float3x4;
                           human_weap_dot_gunEids : EidList;
                           var human_weap_dot_throwMode : bool&;
                           human_weap_dot_lockedGrenadeThrowingCounter : int = 0;
                           human_weap_dot_fastThrowExclusive : bool = true)
  if !isAlive || !isDowned
    return
  let dt = info.dt;
  let atTime = info.curTime;
  let isThrowingAllowed = human_weap_dot_lockedGrenadeThrowingCounter == 0
  downed_grenade_update(eid, transform, atTime, dt, true, isThrowingAllowed,
                        human_net_phys.phys.producedCT, human_net_phys, human_weap_dot_gunEids,
                        human_weap_dot_fastThrowExclusive, human_weap_dot_throwMode)
