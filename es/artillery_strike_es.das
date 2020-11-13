require ecs
require app
require math
require DagorMath
require DagorRandom
require Dacoll
require game.es.events


def gun_ctor(gun_templ; gun_offender; owner_player; gun_pos; target_pos)
  return @ <| (dispersion: float; shootAtTime: float)
    let gunTarget = target_pos + dispersion * float3(gsrnd(), 0.0, gsrnd())
    let gunDir = normalize(gunTarget - gun_pos)

    createEntity("{gun_templ}+auto_shoot") <| $(var init:ComponentsInitializer)
      set(init, "gun.offender", gun_offender)
      set(init, "auto_shoot.gunPos", gun_pos)
      set(init, "auto_shoot.gunDir", gunDir)
      set(init, "auto_shoot.targetPos", gunTarget)
      set(init, "auto_shoot.firstShotTime", shootAtTime)
      set(init, "auto_shoot.shotCount", 1)
      set(init, "artillery.callerEid", owner_player)

[es (tag=server, REQUIRE=autoShoot, no_order)]
def artillery_strike_update_es(info: UpdateStageInfoAct; auto_shoot_dot_firstShotTime: float; var auto_shoot_dot_shouldShoot: bool&)
  auto_shoot_dot_shouldShoot = info.curTime > auto_shoot_dot_firstShotTime


[es (tag=server, REQUIRE=autoShoot, REQUIRE=auto_shoot_dot_canShoot, track=auto_shoot_dot_canShoot, on_event=(EventEntityCreated, EventComponentsAppear))]
def artillery_strike_on_shoot_es(evt: Event;
                                 eid: EntityId;
                                 gun_dot_ammo: int;
                                 gun_dot_maxAmmo: int;
                                 auto_shoot_dot_shotCount: int)
  if gun_dot_maxAmmo - gun_dot_ammo >= auto_shoot_dot_shotCount
    destroyEntity(eid)

[es (tag=server, no_order)]
def artillery_strike_cleanup_es(info: UpdateStageInfoAct; eid : EntityId; artillery_dot_endTime : float)
  if info.curTime > artillery_dot_endTime
    destroyEntity(eid)

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def artillery_strike_es(evt: Event;
                        artillery_dot_gunTempl: string;
                        artillery_dot_callerEid: EntityId;
                        artillery_dot_offender: EntityId;
                        artillery_dot_timeToFirstShot: float;
                        artillery_dot_dispersion: float;
                        artillery_dot_shotsCount: int;
                        artillery_dot_adjustmentsShotsCount: int;
                        artillery_dot_timeBetweenShots: float;
                        artillery_dot_timeBetweenAdjustmentsShots: float;
                        artillery_dot_adjustmentDispersion: float;
                        var artillery_dot_endTime: float&;
                        var artillery_dot_firstShotTime: float&;
                        artillery_dot_sourcePos: float3;
                        artillery_dot_targetPos: float3)
  let atTime = get_sync_time()

  var canStart = true
  ecs::query(artillery_dot_callerEid) <| $[es](artillery_dot_interval: float; var artillery_dot_availableAtTime : float&)
    if atTime > artillery_dot_availableAtTime
      artillery_dot_availableAtTime = atTime + artillery_dot_interval
    else
      canStart = false

  if !canStart
    return

  let gunCtor <- gun_ctor(artillery_dot_gunTempl, artillery_dot_offender, artillery_dot_callerEid, artillery_dot_sourcePos, artillery_dot_targetPos)

  var shootAtTime = atTime + artillery_dot_timeToFirstShot
  artillery_dot_firstShotTime = shootAtTime
  for i in range(0, artillery_dot_adjustmentsShotsCount)
    let gunDispersion = cvt(float(i), 0.0, float(artillery_dot_adjustmentsShotsCount - 1), artillery_dot_adjustmentDispersion, artillery_dot_dispersion)
    invoke(gunCtor, gunDispersion, shootAtTime)
    shootAtTime += artillery_dot_timeBetweenAdjustmentsShots

  for i in range(0, artillery_dot_shotsCount - artillery_dot_adjustmentsShotsCount)
    invoke(gunCtor, artillery_dot_dispersion, shootAtTime)
    shootAtTime += artillery_dot_timeBetweenShots

  artillery_dot_endTime = shootAtTime

  createEntity("map_artillery_strike_marker") <| $(var init: ComponentsInitializer)
    var tm : float3x4
    identity(tm)
    tm[3] = artillery_dot_targetPos
    set(init, "transform", tm)
    set(init, "artillery.callerEid", artillery_dot_callerEid)
    set(init, "artillery.endTime", artillery_dot_endTime)
    set(init, "artillery_zone.radius", artillery_dot_adjustmentDispersion)
