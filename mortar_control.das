require ecs
require Gun
require math
require game.utils.hero
require EnlistedHuman
require EnlistedDeviceAnim
require game.es.events

def manage_mortar_target(human_weap_dot_curGunSlot : int;
                         human_weap_dot_gunEids : ecs::EidList const;
                         human_weap_dot_mortarMode : bool)
  if human_weap_dot_mortarMode
    let alreadyExists = find_query() <| $ [es (REQUIRE=mortar_target)] ()
      return true
    if alreadyExists
      return
    let weapEid = human_weap_dot_gunEids[human_weap_dot_curGunSlot]
    query(weapEid) <| $[es (REQUIRE=mortar)] (mortar_dot_targetTemplate : string)
      createEntity(mortar_dot_targetTemplate)
  else
    query() <| $ [es (REQUIRE=mortar_target)] (eid : EntityId)
      destroyEntity(eid)

[es (tag=gameClient, REQUIRE=hero, track=human_weap_dot_mortarMode)]
def mortar_target_activator_mode_changed(evt : Event;
                                         human_weap_dot_curGunSlot : int;
                                         human_weap_dot_gunEids : ecs::EidList const;
                                         human_weap_dot_mortarMode : bool)
  manage_mortar_target(human_weap_dot_curGunSlot, human_weap_dot_gunEids, human_weap_dot_mortarMode)

[es (tag=gameClient, REQUIRE=hero)]
def mortar_target_activator_hero_changed(evt: EventHeroChanged)
  query(evt.eid) <| $ [es] (human_weap_dot_curGunSlot : int;
                            human_weap_dot_gunEids : ecs::EidList const;
                            human_weap_dot_mortarMode : bool)
    manage_mortar_target(human_weap_dot_curGunSlot, human_weap_dot_gunEids, human_weap_dot_mortarMode)

[es (tag=gameClient, track=mortar_dot_targetPos)]
def move_mortar_target(evt : Event; mortar_dot_targetPos : float3; gun_dot_owner : ecs::EntityId)
  if gun_dot_owner != get_controlled_hero()
    return
  query() <| $ [es (REQUIRE=mortar_target)] (var transform : float3x4)
    transform[3] = mortar_dot_targetPos

[es (tag=gameClient, track=human_weap_dot_mortarMode)]
def mortar_init_target_controls(evt : Event;
                                human_net_phys : HumanActor;
                                human_weap_dot_mortarMode : bool;
                                human_weap_dot_curGunSlot : int;
                                human_weap_dot_gunEids : ecs::EidList const)
  if human_weap_dot_mortarMode
    let weapEid = human_weap_dot_gunEids[human_weap_dot_curGunSlot]
    query(weapEid) <| $[es (REQUIRE=mortar)] (var mortar_dot_targetDistance : float&; var mortar_dot_initDir : float2&; mortar_dot_defaultTargetDistance : float = 30.0)
      mortar_dot_targetDistance = mortar_dot_defaultTargetDistance
      let dir = human_net_phys.phys.producedCT.wishShootDir
      mortar_dot_initDir.x = dir.x
      mortar_dot_initDir.y = dir.z

[es (on_event=CmdPostPhysUpdate)]
def mortar_rotate_body(evt : Event; var human_net_phys : HumanActor; human_weap_dot_mortarMode : bool)
  if human_weap_dot_mortarMode
    let wishShootdir = human_net_phys.phys.appliedCT.wishShootDir
    human_net_phys.phys.currentState.bodyOrientDir = float2(wishShootdir.x, wishShootdir.z);

[es (tag=gameClient, track=(device_anim_dot_state,device_anim_dot_progress))]
def mortar_lock_control(evt : Event;
                        device_anim_dot_state : int;
                        device_anim_dot_progress : float;
                        var mortar_dot_lockedControl : bool&;
                        mortar_dot_lockedProgress : float = 1.0)
  let fireState = int(DeviceAnimState DEVICE_STATE_FIRE)
  mortar_dot_lockedControl = device_anim_dot_state == fireState && device_anim_dot_progress <= mortar_dot_lockedProgress

[es (tag=gameClient, track=(mortar_dot_targetDir,mortar_dot_targetDistance))]
def mortar_input(evt : Event; gun : IGunHolder; mortar_dot_targetDir: float2; mortar_dot_targetDistance : float; var mortar_dot_targetPos : float3&)
  let pos = gun.shootNodePos
  let targetDir = mortar_dot_targetDir * mortar_dot_targetDistance
  mortar_dot_targetPos = float3(pos.x + targetDir.x, pos.y, pos.z + targetDir.y)
