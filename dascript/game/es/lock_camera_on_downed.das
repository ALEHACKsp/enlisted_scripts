require ecs
require ecs.common
require math
require math.base
require math.ang
require DagorMathUtils
require game.utils.hero
require EnlistedHuman
require HumanPhys

[es (tag=input, before=before_net_phys_sync)]
def lock_camera_on_downed_es (info: UpdateStageInfoAct;
                              var human_net_phys : HumanActor;
                              downedMaxAngles: float2;
                              isDowned: bool)
  if !isDowned
    return
  var lookAngles = dir_to_angles(human_net_phys.phys.producedCT.wishLookDir)
  var shootAngles = dir_to_angles(human_net_phys.phys.producedCT.wishShootDir)
  let bodyDir = float3(human_net_phys.phys.currentState.bodyOrientDir[0], 0.0f, human_net_phys.phys.currentState.bodyOrientDir[1])
  lookAngles = clamp_angles_by_dir(lookAngles, downedMaxAngles, bodyDir)
  shootAngles = clamp_angles_by_dir(shootAngles, downedMaxAngles, bodyDir)
  human_net_phys.phys.producedCT |> human_control_state_set_wish_look_dir(angles_to_dir(lookAngles))
  human_net_phys.phys.producedCT |> human_control_state_set_wish_shoot_dir(angles_to_dir(shootAngles))

