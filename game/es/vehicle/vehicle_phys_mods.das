require ecs
require vehicle

[es (on_event=EventEntityCreated)]
def apply_vehicle_phys_mods(evt : Event;
                            var vehicle_net_phys : VehiclePhysActor;
                            vehicle_mods_dot_extraMass : float;
                            vehicle_mods_dot_maxMomentMult : float;
                            vehicle_mods_dot_maxBrakeForceMult : float;
                            vehicle_mods_dot_trackFricSideLinMult : float;
                            vehicle_mods_dot_trackFrontalStaticFrictionMult : float;
                            vehicle_mods_dot_trackFrontalSlidingFrictionMult : float;
                            vehicle_mods_dot_trackSideRotMinSpdMult : float;
                            vehicle_mods_dot_trackSideRotMaxSpdMult : float;
                            vehicle_mods_dot_trackSideRotMinFricMult : float;
                            vehicle_mods_dot_trackSideRotMaxFricMult : float;
                            vehicle_mods_dot_suspensionDampeningMult : float;
                            vehicle_mods_dot_suspensionRestingMult : float;
                            vehicle_mods_dot_suspensionMinLimitMult : float;
                            vehicle_mods_dot_suspensionMaxLimitMult : float)
  var phys& = vehicle_net_phys.phys

  vehicle_phys_add_extra_mass(phys, vehicle_mods_dot_extraMass)

  phys.maxMoment *= vehicle_mods_dot_maxMomentMult

  phys.maxBrakeForce *= vehicle_mods_dot_maxBrakeForceMult

  phys.trackFricSideLin   *= vehicle_mods_dot_trackFricSideLinMult
  phys.trackFricFrontal.x *= vehicle_mods_dot_trackFrontalStaticFrictionMult
  phys.trackFricFrontal.y *= vehicle_mods_dot_trackFrontalSlidingFrictionMult

  phys.trackFricSideRot.x *= vehicle_mods_dot_trackSideRotMinSpdMult
  phys.trackFricSideRot.y *= vehicle_mods_dot_trackSideRotMaxSpdMult
  phys.trackFricSideRot.z *= vehicle_mods_dot_trackSideRotMinFricMult
  phys.trackFricSideRot.w *= vehicle_mods_dot_trackSideRotMaxFricMult

  vehicle_phys_apply_dampening_mult(phys, vehicle_mods_dot_suspensionDampeningMult)
  vehicle_phys_apply_suspension_resting_mult(phys, vehicle_mods_dot_suspensionRestingMult)
  vehicle_phys_apply_suspension_min_limit_mult(phys, vehicle_mods_dot_suspensionMinLimitMult)
  vehicle_phys_apply_suspension_max_limit_mult(phys, vehicle_mods_dot_suspensionMaxLimitMult)
