require ecs
require walkerai
require EnlistedWalkerai
require DagorDataBlock
require game.es.events

[private]
def set_walker_agent_shoot_time(var walker_agent : EntityAgent; combatShootTime, combatCooldownTime : float2)
  walker_agent.blackBoard |> datablock_setPoint2("shootTime", combatShootTime)
  walker_agent.blackBoard |> datablock_setPoint2("cooldownTime", combatCooldownTime)

[es(tag=server, on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventComponentsAppear, track=human_weap_dot_currentGunEid)]
def track_walker_shoot_time(evt : Event; isAlive : bool; human_weap_dot_currentGunEid : EntityId; var walker_agent : EntityAgent)
  if !isAlive
    return
  var found = false
  query(human_weap_dot_currentGunEid) <| $[es](combatShootTime, combatCooldownTime : float2)
    set_walker_agent_shoot_time(walker_agent, combatShootTime, combatCooldownTime)
    found = true
  if !found
    set_walker_agent_shoot_time(walker_agent, float2(-1), float2(-1))

[es(tag=server)]
def created_weapon_set_walker_shoot_time(evt : EventEntityCreated; gun_dot_owner : EntityId; combatShootTime, combatCooldownTime : float2)
  query(gun_dot_owner) <| $[es](var walker_agent : EntityAgent)
    set_walker_agent_shoot_time(walker_agent, combatShootTime, combatCooldownTime)

[es(tag=server, no_order)]
def track_walker_human_velocity(act:UpdateStageInfoAct; human_net_phys_dot_velocity : float3; human_anim_dot_vehicleSelected : EntityId; var walker_agent : EntityAgent)
  walker_agent |> set_walker_agent_velocity(get_Point3(human_anim_dot_vehicleSelected, "net_phys.currentStateVelocity") ?? human_net_phys_dot_velocity)
