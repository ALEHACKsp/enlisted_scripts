options remove_unused_symbols = false
module mortar_common
require ecs
require DagorSystem
require DaWeaponProps
require Gun

def get_shell_speed(shellPropsId : ShellPropIds) : float
  let shellStartProps = get_shell_start_props(int(shellPropsId.shellId))
  if shellStartProps == null
    logerr("Missing ShellStartProps. shellId: {shellPropsId.shellId}");

  let DEFAULT_MORTAR_SHELL_SPEED = 50.0;
  return shellStartProps?.speed ?? DEFAULT_MORTAR_SHELL_SPEED

def get_shoot_pos(gun : IGunHolder; gloc : GunLocation)
  var shootTm : float3x4
  let visTm : float3x4 const? = gloc.visTm
  let physTm : float3x4 const? = gloc.physTm
  gun_calculate_shoot_tm(gun, gloc.gunShootDir, gloc.gunPos, visTm, physTm, shootTm)
  return shootTm[3]