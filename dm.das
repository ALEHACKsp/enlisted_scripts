require dm

[generic]
def DamageDesc(damage_type : DamageType;
               delta_hp : float;
               hit_pos : float3;
               hit_dir : float3 = float3();
               shell_id : int = -1;
               gun_props_id : int = -1;
               coll_node_id : int = -1;
               stopping_power : float = 0.0;
               action_props_id : int = -1;
               dmg_mult : float = 1.0;
               armor_mult : float = 1.0)
  return _builtin_make_damage_desc(damage_type, delta_hp, hit_pos, hit_dir, int16(shell_id), int16(gun_props_id), int16(coll_node_id), stopping_power, int16(action_props_id), dmg_mult, armor_mult)
