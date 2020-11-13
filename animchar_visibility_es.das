require ecs

// One and only place that defines final visibility of a human.
def calc_human_visibility(isInVehicleHidden : bool; human_dot_visible : bool)
  return !isInVehicleHidden && human_dot_visible

// One and only place that defines final visibility of an attachable item (such as a gun, hat, grenade, etc.)
def calc_attachable_visibility(slot_attach_dot_attachedTo : ecs::EntityId; slot_attach_dot_visible : bool;
                               gun_dot_visible : bool; has_gun_dot_visible : bool)
  // Attachable is visible if it's human inventory visible or it's a weapon that's visible (i.e. not holstered)
  var res = slot_attach_dot_visible || gun_dot_visible
  if has_gun_dot_visible && !gun_dot_visible
    // If gun.visible component is present and it's false this means holstering logic
    // wants to detach this gun, but it may not necessarily destroy it (it may "cache" it),
    // so we need to hide it.
    res = false
  ecs::query(slot_attach_dot_attachedTo) <| $ [es](isInVehicleHidden : bool; human_dot_visible : bool)
    // If it's attached to a human and human is invisible, then the item is also invisible.
    res &&= calc_human_visibility(isInVehicleHidden, human_dot_visible)
  ecs::query(slot_attach_dot_attachedTo) <| $ [es](gun_dot_visible : bool;
                                                   slot_attach_dot_attachedTo : ecs::EntityId;
                                                   slot_attach_dot_visible : bool)
    let tmpRes = calc_attachable_visibility(slot_attach_dot_attachedTo, slot_attach_dot_visible, gun_dot_visible, true)
    // If it's attached to a weapon, then it's a weapon mod.
    if has_gun_dot_visible
      // Weapon attached to weapon, respect original gun_dot_visible.
      res &&= tmpRes
    else
      // Override visibility with weapon's visibility.
      res = tmpRes
  return res

// Recursively update visibilities of all attached stuff.
def update_attached_visibility(parentEid : ecs::EntityId)
  ecs::query() <| $ [es](eid : ecs::EntityId; slot_attach_dot_attachedTo : ecs::EntityId; var animchar_render_dot_enabled : bool&;
                         slot_attach_dot_visible : bool; gun_dot_visible : bool = false)
    if slot_attach_dot_attachedTo == parentEid
      animchar_render_dot_enabled = calc_attachable_visibility(slot_attach_dot_attachedTo, slot_attach_dot_visible,
        gun_dot_visible, has(eid, "gun.visible"))
      update_attached_visibility(eid)

[es (track=isInVehicleHidden, track=human_dot_visible, on_event=(EventEntityCreated, EventComponentsAppear))]
def animchar_human_visibility_es(evt : Event; eid : ecs::EntityId; isInVehicleHidden : bool; human_dot_visible : bool;
                                 var animchar_render_dot_enabled : bool&)
  animchar_render_dot_enabled = calc_human_visibility(isInVehicleHidden, human_dot_visible)
  update_attached_visibility(eid)
  ecs::query() <| $ [es](skeleton_attach_dot_attachedTo : ecs::EntityId; var animchar_render_dot_enabled : bool&;
                         slot_attach_dot_visible : bool)
    if skeleton_attach_dot_attachedTo == eid
      animchar_render_dot_enabled = calc_human_visibility(isInVehicleHidden, human_dot_visible) && slot_attach_dot_visible

[es (on_event=(EventEntityCreated, EventComponentsAppear), track=slot_attach_dot_visible, track=slot_attach_dot_attachedTo, track=gun_dot_visible)]
def animchar_attachable_visibility_es(evt : Event; eid : ecs::EntityId; slot_attach_dot_attachedTo : ecs::EntityId;
                                      var animchar_render_dot_enabled : bool &; slot_attach_dot_visible : bool;
                                      gun_dot_visible : bool = false)
  animchar_render_dot_enabled = calc_attachable_visibility(slot_attach_dot_attachedTo, slot_attach_dot_visible,
    gun_dot_visible, has(eid, "gun.visible"))
  update_attached_visibility(eid)

[es (on_event=(EventEntityCreated, EventComponentsAppear), track=skeleton_attach_dot_attachedTo, track=slot_attach_dot_visible)]
def animchar_skeleton_visibility_es(evt : Event; skeleton_attach_dot_attachedTo : ecs::EntityId;
                                    var animchar_render_dot_enabled : bool &; slot_attach_dot_visible : bool)
  ecs::query(skeleton_attach_dot_attachedTo) <| $ [es](isInVehicleHidden : bool; human_dot_visible : bool)
    animchar_render_dot_enabled = calc_human_visibility(isInVehicleHidden, human_dot_visible) && slot_attach_dot_visible
