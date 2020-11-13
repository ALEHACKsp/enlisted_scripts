require ecs
require math

[es (on_event=EventOnMovingZoneStarted)]
def zone_damage_change_es(evt : Event; var dmgzone_dot_damage : float&; dmgzone_dot_damageIncrease : float; dmgzone_dot_damageCap : float)
  dmgzone_dot_damage = min(dmgzone_dot_damage * dmgzone_dot_damageIncrease, dmgzone_dot_damageCap)
