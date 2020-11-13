require ecs
require app
require player
require AnimV20
require HumanPhys
require EnlistedHuman

[es (on_event=CmdPutOutFireStart)]
def put_out_fire_start(evt : Event; burning_dot_isBurning : bool; var burning_dot_isPuttingOut: bool&)
  if burning_dot_isBurning
    burning_dot_isPuttingOut = true

[es (on_event=CmdPutOutFireStop)]
def put_out_fire_stop(evt : Event; var burning_dot_isPuttingOut : bool&)
  burning_dot_isPuttingOut = false

[es (track=burning_dot_isBurning)]
def put_out_fire_burning_stop(ect : Event; burning_dot_isBurning : bool; var burning_dot_isPuttingOut : bool&)
  if !burning_dot_isBurning
    burning_dot_isPuttingOut = false

[es (tag=server, no_order)]
def put_out_progress(info : UpdateStageInfoAct; var burning_dot_force : float&; burning_dot_putOutForce : float; burning_dot_isPuttingOut : bool;
                     human_net_phys : HumanActor)
  if !burning_dot_isPuttingOut
    return
  let ct & = human_net_phys.phys.currentState
  if ct.standState == HUStandState ESS_CRAWL && ct.moveState != HUMoveState EMS_STAND
    return
  burning_dot_force -= burning_dot_putOutForce * info.dt

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def init_put_out_fire_anim_vars(evt : Event;
                                burning_dot_animPutOutEnumName : string;
                                var burning_dot_animPutOutEnum : int&)
  burning_dot_animPutOutEnum = animV20_get_enum_value_by_name(burning_dot_animPutOutEnumName)