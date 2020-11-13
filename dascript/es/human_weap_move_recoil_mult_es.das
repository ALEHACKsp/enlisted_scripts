require ecs
require math
require DagorMath

[es(before=gun_human_recoil_es)]
def human_weap_move_recoil_mult_es(act : ecs::UpdateStageInfoAct; var human_weap_dot_recoilMult : float&; human_weap_dot_gunAngleSpeed : float2;
                                   human_weap_dot_angleSpeedRecoilParams : float4)
  let len = length(human_weap_dot_gunAngleSpeed)
  human_weap_dot_recoilMult = cvt(len, human_weap_dot_angleSpeedRecoilParams.x, human_weap_dot_angleSpeedRecoilParams.y, human_weap_dot_angleSpeedRecoilParams.z, human_weap_dot_angleSpeedRecoilParams.w)
  //visual_log("{human_weap_dot_recoilMult} : {len}", E3DCOLOR(0xffffffff), 0)
