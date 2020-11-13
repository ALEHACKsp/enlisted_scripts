require ecs
require HumanPhys

[es (tag=server, on_event=EventEntityDied, REQUIRE=(lootable,lootableGunOnly))]
def destroy_nonlootable_weapons(evt: Event; var human_weap_dot_gunEids: EidList; var human_weap_dot_gunMods: EidList)
  let slot = int(HUWeaponSlots EWS_SECONDARY)
  destroyEntity(human_weap_dot_gunEids[slot])
  human_weap_dot_gunEids[slot] = INVALID_ENTITY_ID
  // Destroy gun mods as well, otherwise they'll be hanging around
  // in the midair. Gun mods are attached to the gun and when the gun is destroyed
  // gun mods won't be able to move and they can't be interacted with.
  destroyEntity(human_weap_dot_gunMods[slot])
  human_weap_dot_gunMods[slot] = INVALID_ENTITY_ID