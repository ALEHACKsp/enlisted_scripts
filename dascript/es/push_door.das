require ecs
require net
require game.es.events
require HumanPhys
require EnlistedHuman
require RendInst
require DagorMath
require CollRes


[es (tag=gameClient, after=hero_human_use_door_object_es, REQUIRE=hero)]
def push_door_es(info : UpdateStageInfoAct;
                 eid : EntityId;
                 isAlive : bool;
                 human_use_object_dot_selectedObject : EntityId;
                 human_net_phys : HumanActor;
                 collres : CollisionResource;
                 transform : float3x4;
                 human_push_door_dot_minAngleDot : float = 0.525;
                 human_push_door_dot_extrapolatePosTime : float = 0.2)
  let isSprinting = (int(human_net_phys.phys.currentState.states) & int(StateFlag ST_SPRINT)) != 0
  if !isAlive || !isSprinting
    return

  let humanEid = eid
  let humanBox = BBox3(collres.vFullBBox)
  var humanTm := transform

  ecs::query(human_use_object_dot_selectedObject) <| $ [es (REQUIRE=isDoor)] (eid : EntityId;
                                                                              rendinst_axis_rotation_dot_targetAngle : float;
                                                                              door_operations_dot_openedAngle : float;
                                                                              door_operations_dot_closedAngle : float;
                                                                              door_operations_dot_omniRotate : bool = false;
                                                                              ri_extra : RiExtraComponent;
                                                                              transform : float3x4)
    let isDoorClosed = rendinst_axis_rotation_dot_targetAngle == door_operations_dot_closedAngle
    if !isDoorClosed
      return
    let doorDir = transform[2]
    let openerDir = transform[3] - humanTm[3]
    let angleDot = dot(doorDir, openerDir)
    if abs(angleDot) < human_push_door_dot_minAngleDot
      return
    if !door_operations_dot_omniRotate && angleDot * (door_operations_dot_openedAngle - door_operations_dot_closedAngle) > 0.0
      return
    let riType = handle_to_ri_type(ri_extra.handle)
    let doorCollres = get_ri_gen_extra_collres(int(riType))
    if doorCollres == null
      return

    humanTm[3] += human_net_phys.phys.currentState.velocity * max(info.dt, human_push_door_dot_extrapolatePosTime)
    let doorBox = BBox3(doorCollres.vFullBBox)
    if check_bbox3_intersection(humanBox, humanTm, doorBox, transform)
      sendEvent(humanEid, [[HumanUseObjectRequest objectEid=eid]])
