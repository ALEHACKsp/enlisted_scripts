require ecs
require math
require EnlistedHumanAnim
require EnlistedHuman
require PhysVars
require DagorRandom
require DagorMath
require DagorConsole
require DagorSystem

def safeinv(val: float): float
  return val > 1e-19 ? 1.0/val : val < -1e-19 ? 1.0/val : 0.0

def safeinv(val: float3): float3
  return float3(safeinv(val.x), safeinv(val.y), safeinv(val.z))

def random_p3(mu, sigma: float3) : float3
  return mu + sigma * float3(gauss_rnd(0), gauss_rnd(0), gauss_rnd(0))

def recoil_update(var pos: float3&; var vel: float3&; spring, damp, inertia: float3; dt: float)
  let invInertia = safeinv(inertia)
  // -k*x - c*v
  let updateRate = 1.0/60.0 // not less than 60fps for smooth and predicatable integration
  var critDamping = 4.f * spring * inertia
  critDamping.x = sqrt(critDamping.x)
  critDamping.y = sqrt(critDamping.y)
  critDamping.z = sqrt(critDamping.z)
  let resDamping = damp * critDamping
  var remainingDt = dt
  while remainingDt > 0.f
    let curDt = min(remainingDt, updateRate)
    let acc = -(spring * pos + resDamping * vel) * invInertia
    pos += vel * curDt + acc * curDt * curDt * 0.5f
    vel += acc * curDt
    remainingDt -= updateRate

def constraint_movement(var pos: float3&; var vel: float3&; limit: float3)
  for i in range(0, 3)
    if pos[i] < -limit[i] || pos[i] > limit[i]
      vel[i] = 0.f;
    pos[i] = clamp(pos[i], -limit[i], limit[i])

[es(no_order)]
def human_anim_weap(info: UpdateStageInfoAct; human_anim: HumanAnimCtx;
                                              human_net_phys: HumanActor;
                                              var phys_vars: PhysVars;
                                              human_weap_dot_gunEids: EidList;
                                              human_weap_dot_currentGunSlot: int;
                                              human_weap_dot_gunAngleSpeed: float2;
                                              human_weap_dot_gunAngleSpeedToVelocityMult: float3;
                                              human_weap_dot_gunAngleSpeedToOmegaMult: float3;
                                              var human_weap_dot_recoil: float&;
                                              var human_weap_dot_gunOffset: float3&;
                                              var human_weap_dot_gunVelocity: float3&;
                                              human_weap_dot_gunOffsetSpring: float3;
                                              human_weap_dot_gunOffsetDamping: float3;
                                              var human_weap_dot_gunRotation: float3&;
                                              var human_weap_dot_gunOmega: float3&;
                                              human_weap_dot_gunRotationSpring: float3;
                                              human_weap_dot_gunRotationDamping: float3;
                                              human_weap_dot_curRecoilMult: float;
                                              human_weap_dot_gunOffsAngles: float3;
                                              var prevVisualBoltActionProgress: float&;
                                              boltActionProgress: float;
                                              human_weap_dot_gunOffsetLimit: float3;
                                              human_weap_dot_gunRotationLimit: float3;
                                              human_weap_dot_recoilToImpulseMult: float = 20.f)
  if human_weap_dot_currentGunSlot < 0
    return
  let gunEid = human_weap_dot_gunEids[human_weap_dot_currentGunSlot]
  ecs::query(gunEid) <| $ [es](gun_dot_inertialMass: float;
                               gun_dot_rotInertia, gun_dot_recoilOffsetMean, gun_dot_recoilOffsetDeviation,
                               gun_dot_recoilRotationMean, gun_dot_recoilRotationDeviation: float3;
                               gun_dot_recoilAmount: float;
                               gun_dot_recoilOriMultInAim: float3;
                               gun_dot_rotationSpringMult: float3;
                               gun_dot_visualRecoilMult: float = 1.0;
                               gun_dot_visualBoltRecoilMult: float = 0.3)
    let massInertia = float3(gun_dot_inertialMass, gun_dot_inertialMass, gun_dot_inertialMass)
    let rotInertia = gun_dot_rotInertia * gun_dot_inertialMass
    let invMoi = safeinv(rotInertia)
    if boltActionProgress > 0.5 && prevVisualBoltActionProgress <= 0.5
      human_weap_dot_recoil = gun_dot_recoilAmount * gun_dot_visualRecoilMult * human_weap_dot_curRecoilMult * gun_dot_visualBoltRecoilMult
    if human_weap_dot_recoil > 0.f
      let invMass = safeinv(massInertia)
      let velRecoilMult = random_p3(gun_dot_recoilOffsetMean, gun_dot_recoilOffsetDeviation)
      let recoilOriMult = human_net_phys.phys.currentState.aimPosition > 0.5 ? gun_dot_recoilOriMultInAim : float3(1.0, 1.0, 1.0)
      human_weap_dot_gunVelocity += human_weap_dot_recoil * human_weap_dot_recoilToImpulseMult * invMass * velRecoilMult

      let omegaRecoilMult = random_p3(gun_dot_recoilRotationMean, gun_dot_recoilRotationDeviation)
      human_weap_dot_gunOmega += human_weap_dot_recoil * human_weap_dot_recoilToImpulseMult * invMoi * omegaRecoilMult * recoilOriMult

    human_weap_dot_gunOmega += human_weap_dot_gunOffsAngles
    let invMass = safeinv(gun_dot_inertialMass)
    prevVisualBoltActionProgress = boltActionProgress
    human_weap_dot_recoil = 0.f
    human_weap_dot_gunVelocity.y += human_weap_dot_gunAngleSpeed.y * human_weap_dot_gunAngleSpeedToVelocityMult.y * invMass
    human_weap_dot_gunVelocity.z += human_weap_dot_gunAngleSpeed.x * human_weap_dot_gunAngleSpeedToVelocityMult.z * invMass
    human_weap_dot_gunOmega.x += human_weap_dot_gunAngleSpeed.x * human_weap_dot_gunAngleSpeedToOmegaMult.x * invMoi.x
    human_weap_dot_gunOmega.y += human_weap_dot_gunAngleSpeed.x * human_weap_dot_gunAngleSpeedToOmegaMult.y * invMoi.y
    human_weap_dot_gunOmega.z += human_weap_dot_gunAngleSpeed.y * human_weap_dot_gunAngleSpeedToOmegaMult.z * invMoi.z

    recoil_update(human_weap_dot_gunOffset, human_weap_dot_gunVelocity,
                  human_weap_dot_gunOffsetSpring, human_weap_dot_gunOffsetDamping,
                  massInertia, info.dt)

    recoil_update(human_weap_dot_gunRotation, human_weap_dot_gunOmega,
                  human_weap_dot_gunRotationSpring * gun_dot_rotationSpringMult, human_weap_dot_gunRotationDamping,
                  rotInertia, info.dt)

    set_var(phys_vars, human_anim.weaponRollVarId, human_weap_dot_gunRotation.x)
    set_var(phys_vars, human_anim.weaponYawVarId, human_weap_dot_gunRotation.y)
    set_var(phys_vars, human_anim.weaponPitchVarId, human_weap_dot_gunRotation.z)

    constraint_movement(human_weap_dot_gunOffset, human_weap_dot_gunVelocity, human_weap_dot_gunOffsetLimit)
    constraint_movement(human_weap_dot_gunRotation, human_weap_dot_gunOmega, human_weap_dot_gunRotationLimit)

    set_var(phys_vars, human_anim.weaponOffsFwdVarId, human_weap_dot_gunOffset.x)
    set_var(phys_vars, human_anim.weaponOffsUpVarId, human_weap_dot_gunOffset.y)
    set_var(phys_vars, human_anim.weaponOffsLeftVarId, human_weap_dot_gunOffset.z)

