require ecs
require app
require dm
require DagorMath
require EnlistedHuman
require game.es.events
require game.es.concussion_common
require game.utils.hero

[es (tag=server, no_order)]
def concussion_timer(info : UpdateStageInfoAct;
                     eid : EntityId;
                     concussion_dot_startedAtTime : float;
                     concussion_dot_duration : float)
  if info.curTime > concussion_dot_startedAtTime + concussion_dot_duration
    destroyEntity(eid)

[es (no_order, REQUIRE=concussionHandsShake)]
def concussion_hands_shake_fade(info : UpdateStageInfoAct;
                                game_effect_dot_attachedTo : EntityId;
                                concussion_dot_startedAtTime : float;
                                concussion_dot_duration : float;
                                concussion_dot_handsShakeFadeTime : float;
                                concussion_dot_handsShakeMagnitude : float)
  let endAt = concussion_dot_startedAtTime + concussion_dot_duration
  let fadeMult = cvt(info.curTime, endAt - concussion_dot_handsShakeFadeTime, endAt, 1.0, 0.0)
  query(game_effect_dot_attachedTo) <| $ [es] (var human_net_phys : HumanActor)
    human_net_phys.phys.currentState.handsShakeMagnitude = concussion_dot_handsShakeMagnitude * fadeMult;

[es (tag=server, REQUIRE=human)]
def on_explosion_apply_concussion(evt: EventOnEntityHit; eid : EntityId; isAlive : bool; concussion_dot_template : string)
  if evt.victim != eid || evt.damageDesc.damageType != DamageType DM_EXPLOSION || !isAlive
    return
  enable_concussion_affect(eid, concussion_dot_template)

[es (tag=server, track=isAlive)]
def on_death_disable_concussion(evt : Event; eid : EntityId; isAlive : bool)
  if !isAlive
    disable_concussion_affect(eid)

[es (REQUIRE=concussionHandsShake, on_event=(EventEntityCreated, EventComponentsAppear))]
def concussion_hands_shake_create(evt : Event;
                                  game_effect_dot_attachedTo : EntityId;
                                  concussion_dot_handsShakeMagnitude : float;
                                  concussion_dot_handsShakeSpeedMult : float)
  query(game_effect_dot_attachedTo) <| $ [es] (var human_net_phys : HumanActor)
    human_net_phys.phys.currentState.handsShakeMagnitude = concussion_dot_handsShakeMagnitude;
    human_net_phys.phys.currentState.handsShakeSpeedMult = concussion_dot_handsShakeSpeedMult;

[es (REQUIRE=concussionHandsShake, on_event=EventEntityDestroyed)]
def concussion_hands_shake_remove(evt : Event; game_effect_dot_attachedTo : EntityId; concussion_dot_replaced : bool)
  if concussion_dot_replaced
    return
  query(game_effect_dot_attachedTo) <| $ [es] (var human_net_phys : HumanActor)
    human_net_phys.phys.currentState.handsShakeMagnitude = 0.0;
    human_net_phys.phys.currentState.handsShakeSpeedMult = 1.0;

[es (tag=gameClient, REQUIRE=concussionScreenEffect, on_event=(EventEntityCreated, EventComponentsAppear))]
def concussion_screen_effect_create(evt : Event; game_effect_dot_attachedTo : EntityId)
  setOptional(game_effect_dot_attachedTo, "hasConcussedVision", true)

[es (tag=gameClient, REQUIRE=concussionScreenEffect, on_event=EventEntityDestroyed)]
def concussion_screen_effect_remove(evt : Event; game_effect_dot_attachedTo : EntityId)
  setOptional(game_effect_dot_attachedTo, "hasConcussedVision", false)
