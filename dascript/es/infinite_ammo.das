require ecs

[es(tag=server, no_order)]
def infinite_ammo_update(evt:UpdateStageInfoAct; human_weap_dot_infiniteAmmo : bool; human_weap_dot_currentGunEid : EntityId)
  if human_weap_dot_infiniteAmmo
    query(human_weap_dot_currentGunEid) <| $[es](var gun_dot_ammo : int&; gun_dot_maxAmmo : int)
      gun_dot_ammo = gun_dot_maxAmmo
