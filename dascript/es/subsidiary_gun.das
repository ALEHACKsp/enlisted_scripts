require ecs
require game.es.events
require DaWeaponProps
require DaWeapons
require Gun
require EnlistedPhys
require DagorSystem

def update_gun(subsidiaryGunEid : ecs::EntityId; var gun : IGunHolder; evt : CmdWeapPhysUpdate; gun_dot_curShellId : ShellPropIds; var gun_dot_ammo : int&)
  var gunInput : GunInput
  gunInput.atTime = evt.atTime;
  gunInput.isForReal = evt.isForReal;
  gunInput.rndSeed = phys_time_to_seed(evt.atTime);
  gunInput.curShellId = gun_dot_curShellId;

  var gctrl : GunControls
  gctrl.shoot = false
  gctrl.wishShoot = false
  gctrl.boltActionMult = evt.gctrl.boltActionMult

  gun_update(gun, gunInput, gun_dot_ammo, gctrl, evt.gloc)

  ecs::query(subsidiaryGunEid) <| $ [es](var gun_dot_ammo : int&;
                                         var gun : IGunHolder;
                                         gun_dot_curShellId : ShellPropIds)
    var gunInput2 : GunInput
    gunInput2.atTime = evt.atTime;
    gunInput2.isForReal = evt.isForReal;
    gunInput2.rndSeed = phys_time_to_seed(evt.atTime);
    gunInput2.curShellId = gun_dot_curShellId;

    // We need to use original evt.gloc.gunShootPos here. It might be tempting to calculate it
    // via gun_calculate_shoot_tm, but server side doesn't have proper animchar world offsets, only client knows it
    // and sends it from human_phys_before_enqueue_ct. So we're sending the right thing from human_phys_before_enqueue_ct
    // now.
    gun_update(gun, gunInput2, gun_dot_ammo, evt.gctrl, evt.gloc)

[es]
def subsidiary_gun_phys_es(evt : CmdWeapPhysUpdate;
                           var gun : IGunHolder;
                           var gun_dot_ammo : int&;
                           gun_dot_curShellId : ShellPropIds;
                           subsidiaryGunEid : ecs::EntityId)
  if evt.isForReal
    update_gun(subsidiaryGunEid, gun, evt, gun_dot_curShellId, gun_dot_ammo)

[es (on_event=(EventEntityCreated, EventComponentsAppear), track=weapon_mod_dot_active, REQUIRE=subsidiaryGun)]
def subsidiary_gun_activation_es(evt : Event; eid : ecs::EntityId; slot_attach_dot_attachedTo : ecs::EntityId;
  weapon_mod_dot_active : bool)
  if weapon_mod_dot_active
    addSubTemplate(slot_attach_dot_attachedTo, "gun_with_subsidiary") <| $(var init)
      set(init, "subsidiaryGunEid", eid)
  else
    removeSubTemplate(slot_attach_dot_attachedTo, "gun_with_subsidiary")

[es (on_event=EventEntityDestroyed, REQUIRE=subsidiaryGun)]
def subsidiary_gun_destroyed_es(evt : Event; slot_attach_dot_attachedTo : ecs::EntityId)
  removeSubTemplate(slot_attach_dot_attachedTo, "gun_with_subsidiary")

[es (REQUIRE=subsidiaryGun, no_order)]
def subsidiary_gun_visibility_es(act : ecs::UpdateStageInfoAct;
                                 gun_dot_owner : EntityId;
                                 weapon_mod_dot_active : bool;
                                 var gun_dot_visible : bool&)
  query(gun_dot_owner) <| $[es](human_weap_dot_weapModActivateStartTime : float; menuChar : bool = false)
    gun_dot_visible = weapon_mod_dot_active || human_weap_dot_weapModActivateStartTime > 0.0f || menuChar
