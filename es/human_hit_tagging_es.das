require ecs
require game.es.events
require app
require EnlistedHuman
require HumanPhys
require DagorMath
require dm

[es]
def human_hit_tagging_applier_es(info: ecs::UpdateStageInfoAct;
                                  var human_net_phys: HumanActor;
                                  human_hit_tagging_dot_tagStart: float;
                                  human_hit_tagging_dot_tagEnd: float;
                                  human_hit_tagging_dot_currentTagPower: float)
  if info.curTime < human_hit_tagging_dot_tagStart || info.curTime > human_hit_tagging_dot_tagEnd
    return

  human_net_phys.phys.currentState.moveSpeedMult = cvt(info.curTime, human_hit_tagging_dot_tagStart,
                                                        human_hit_tagging_dot_tagEnd,
                                                        human_hit_tagging_dot_currentTagPower,
                                                        1.f)

[es (REQUIRE=human_hit_tagging_dot_tagEnd)]
def human_hit_tagging(evt: EventOnEntityHit; eid: EntityId)
  let damageType = evt.damageDesc.damageType
  if eid != evt.victim || damageType == (DamageType DM_ZONE)
    return

  sendEventImmediate(eid, [[CmdHumanHitTagging powerMult=1.f]])

[es (tag=server)]
def cmd_hit_tagging(evt: CmdHumanHitTagging;
                    var human_hit_tagging_dot_tagStart : float &;
                    var human_hit_tagging_dot_tagEnd : float &;
                    var human_hit_tagging_dot_currentTagPower : float &;
                    human_hit_tagging_dot_tagPower : float  = 0.4f;
                    human_hit_tagging_dot_tagTime : float  = 1.f;
                    human_hit_tagging_dot_maxTime : float  = 1.5f;
                    human_hit_tagging_dot_timeOffset : float  = 0.1f;
                    human_hit_tagging_dot_mult : float  = 1.f)
  let powerMult = evt.powerMult
  let curTime = get_sync_time()
  let alreadyTagged = human_hit_tagging_dot_tagEnd > curTime
  if !alreadyTagged
    human_hit_tagging_dot_tagStart = curTime + human_hit_tagging_dot_timeOffset
  human_hit_tagging_dot_tagEnd := (alreadyTagged ? min(curTime + human_hit_tagging_dot_maxTime, human_hit_tagging_dot_tagEnd)
                                                : curTime) + human_hit_tagging_dot_tagTime
  human_hit_tagging_dot_currentTagPower = max(0.f, 1.f - ((1.f - human_hit_tagging_dot_tagPower * powerMult) * human_hit_tagging_dot_mult))
