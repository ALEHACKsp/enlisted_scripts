require ecs
require EnlistedWeapon

[es (on_event=EventEntityDestroyed, tag=server)]
def cleanup_equipment_on_destroy_es(evt:Event; human_equipment_dot_slots : ecs::Object)
  for it in human_equipment_dot_slots
    var obj = get_ecs_object(it.value)
    destroyEntity(deref(get_Eid(deref(deref(obj)["item"]))))
    for ent in deref(get_ecs_array(deref(deref(obj)["entities"])))
      destroyEntity(get_Eid(ent) ?? INVALID_ENTITY_ID)

[es (on_event=EventEntityDestroyed, tag=server)]
def cleanup_intentory_on_destroy_es(evt:Event; itemContainer : EidList)
  for itemEid in itemContainer
    destroyEntity(itemEid)

[es (on_event=EventEntityDestroyed, tag=server)]
def destroy_ammo_holder_in_real_gun_es(evt:Event; gun_dot_ammoHolderEid : ecs::EntityId)
  if gun_dot_ammoHolderEid != INVALID_ENTITY_ID
    destroyEntity(gun_dot_ammoHolderEid)

[es (on_event=EventEntityDestroyed, tag=server, REQUIRE=item_dot_weapTemplate)]
def destroy_ammo_holder_on_ground_es(evt:Event; var customProps : Object)
  human_gun_custom_props_cleanup(customProps)
