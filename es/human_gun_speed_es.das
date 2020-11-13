require ecs
require game.es.events
require EnlistedHuman
require HumanPhys

[es]
def human_gun_sprint_lerp(evt: CmdWeapAttach; weap_dot_sprintLerpFactor: float = 1.f)
  if evt.isAttached && evt.slotId != int(HUWeaponSlots EWS_GRENADE)
    query(evt.toEid) <| $[es](var human_net_phys: HumanActor)
      human_net_phys.phys.currentState.sprintLerpSpeedMult = weap_dot_sprintLerpFactor

[es (track=human_unarmed_dot_active)]
def human_unarmed_sprint(evt: Event; human_unarmed_dot_active: bool; var human_net_phys: HumanActor)
  if human_unarmed_dot_active
    human_net_phys.phys.currentState.sprintLerpSpeedMult = 5.f