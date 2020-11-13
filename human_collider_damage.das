require ecs
require game.es.events
require DagorMath
require EnlistedHuman

[es (tag=server)]
def human_collider_damage(evt : CmdPostPhysUpdate;
                          eid : EntityId;
                          human_net_phys : HumanActor;
                          transform : float3x4;
                          isAlive : bool;
                          human_coll_damage_dot_minDmgSpd : float;
                          human_coll_damage_dot_dmgPow : float;
                          human_coll_damage_dot_hpCoeff : float;
                          human_coll_damage_dot_minFallDmgVal : float;
                          entity_mods_dot_lessFallDmgMult : float = 1.f)
  if !evt.isForReal
    return

  let minDmgSpdSquare = human_coll_damage_dot_minDmgSpd * human_coll_damage_dot_minDmgSpd
  if isAlive && length_sq(human_net_phys.phys.currentState.spdSummaryDiff) > minDmgSpdSquare
    let dmgSpd = length(human_net_phys.phys.currentState.spdSummaryDiff)

    var damage = human_coll_damage_dot_minFallDmgVal
    damage += pow(dmgSpd - human_coll_damage_dot_minDmgSpd, human_coll_damage_dot_dmgPow) * human_coll_damage_dot_hpCoeff

    if human_net_phys.phys.currentState.spdSummaryDiff.y > 0.f
      damage *= entity_mods_dot_lessFallDmgMult

    if damage > 0.f
      sendEvent(eid, [[CmdCollisionDamage damage=damage, pos=transform[3], offender=eid]])