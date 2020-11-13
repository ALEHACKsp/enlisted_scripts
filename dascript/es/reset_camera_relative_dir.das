require ecs
require game.es.events

[es (tag=gameClient)]
def reset_camera_relative_dir_es(evt: CmdSwitchCamera; possessed: ecs::EntityId)
  let vehicleEid = get_Eid(possessed, "human_anim.vehicleSelected") ?? INVALID_ENTITY_ID
  if vehicleEid != INVALID_ENTITY_ID
    if has(vehicleEid, "camera.relative_angle")
      set(vehicleEid, "camera.relative_angle", float2())
    if has(vehicleEid, "camera.wish_relative_angle")
      set(vehicleEid, "camera.wish_relative_angle", float2())
