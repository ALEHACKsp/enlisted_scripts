require ecs
require enlisted.game.es.enlisted_events
require game.es.events
require EnlistedHuman
require EnlistedWeapon
require HumanPhys
require DagorMath

[es(no_order)]
def human_attached_gun_autodetach_es(info : UpdateStageInfoAct;
                                     eid : ecs::EntityId;
                                     human_attached_gun : HumanAttachedGun;
                                     human_net_phys : HumanActor)
  let humanPos = float3(human_net_phys.phys.currentState.location.P)
  if gun_needs_detach(human_attached_gun.attachedGunEid, humanPos)
    sendEvent(eid, [[CmdDetachAttachedGun]])
    sendEvent(eid, [[CmdHeroLogEvent event="human_attached_gun_lost", text="human_attached_gun_lost"]])
