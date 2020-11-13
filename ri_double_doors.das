require ecs
require game.es.events
require RendInst
require DagorMath
require CollRes
require LooseGrid


[es (tag=server, REQUIRE=connectDoubleDoors)]
def find_doors_grid_es(evt : EventEntityCreated; eid : EntityId)
  destroyEntity(eid)
  let doors_grid = find_loose_grid_holder(ecs_hash("doors"))
  ecs::query() <| $ [es (REQUIRE=isDoor)] (eid : EntityId;
                                           door_operations_dot_openedAngle : float;
                                           door_operations_dot_closedAngle : float;
                                           ri_extra : RiExtraComponent;
                                           transform : float3x4;
                                       var pair_door_dot_eid : EntityId&;
                                           pair_door_dot_searchDist : float = 3.0;
                                           pair_door_dot_checkScale : float = 1.04)
    if pair_door_dot_eid != ecs::INVALID_ENTITY_ID
      return

    var riType = handle_to_ri_type(ri_extra.handle)
    var collres = get_ri_gen_extra_collres(int(riType))
    if collres == null
      return

    let curDoorOpenedAngle = door_operations_dot_openedAngle
    let curDoorClosedAngle = door_operations_dot_closedAngle
    let curDoorTm = transform
    let curDoorBox = BBox3(collres.vFullBBox)
    var curDoorPair : EntityId& = pair_door_dot_eid

    let bounding = BSphere3(transform[3], pair_door_dot_searchDist)
    find_entity_in_loose_grid(doors_grid, bounding) <| $ (pairEid : EntityId)
      if pairEid == eid
        return false

      ecs::query(pairEid) <| $ [es] (door_operations_dot_openedAngle : float;
                                     door_operations_dot_closedAngle : float;
                                     ri_extra : RiExtraComponent;
                                     transform : float3x4;
                                 var pair_door_dot_eid : EntityId&)

        if pair_door_dot_eid != ecs::INVALID_ENTITY_ID
          return
        if door_operations_dot_openedAngle != -curDoorOpenedAngle && door_operations_dot_closedAngle != -curDoorClosedAngle
          return

        riType = handle_to_ri_type(ri_extra.handle)
        collres = get_ri_gen_extra_collres(int(riType))
        if collres == null
          return

        let box = BBox3(collres.vFullBBox)
        if check_bbox3_intersection(curDoorBox, curDoorTm, box, transform, pair_door_dot_checkScale)
          pair_door_dot_eid = eid
          curDoorPair = pairEid

      return curDoorPair != ecs::INVALID_ENTITY_ID
