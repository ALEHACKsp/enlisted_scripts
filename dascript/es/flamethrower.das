require ecs
require app
require dm
require math
require math.base
require game.es.events
require DaWeaponProps
require DaWeapons
require EnlistedPhys
require Gun
require DagorSystem
require Dacoll
require GridCollision
require AnimV20
require DagorMath
require DagorMathUtils
require game.es.node_attach
require CollRes
require game.utils.team
require DagorRandom

struct DropletSpread
  yaw : float
  pitchMin : float
  pitchMax : float
  maxLength : float
  normalOffset : float

struct FlameDamage
  offender : EntityId
  offenderTeam : int
  streamDamage : float
  cloudDamage : float
  friendlyDamage : float
  shouldSetFriendlyOnFire : bool

def deal_fire_damage(eid : EntityId; damage : FlameDamage; isStream : bool = true) : bool
  var found = false
  query(eid) <| $[es] (var burning_dot_isBurning : bool&;
                       var burning_dot_offender : EntityId&;
                       var burning_dot_force : float&;
                       burning_dot_maxForce : float;
                       transform : float3x4;
                       team : int = TEAM_UNASSIGNED)
    let friendlyFire = is_teams_friendly(damage.offenderTeam, team)
    if !friendlyFire || damage.shouldSetFriendlyOnFire
      burning_dot_isBurning = true
      burning_dot_force = burning_dot_maxForce
      burning_dot_offender = damage.offender
    let dmg = friendlyFire ? damage.friendlyDamage : isStream ? damage.streamDamage : damage.cloudDamage
    if dmg > 0.0
      let damageDesc = DamageDesc(DamageType DM_FIRE, dmg, transform[3])
      damage_entity(eid, damage.offender, damageDesc)
    found = true
  return found

def reigniteOldFireIfExists(bind_to_eid : EntityId; pos : float3; min_distance_between_sq : float)
  let fireNearby = find_query() <| $ [es (REQUIRE=fire_source)] (transform: float3x4;
                                                                 node_attached_dot_entity : EntityId;
                                                                 var fire_source_dot_startTime : float&;
                                                                 fire_source_dot_spreadTime : float = 0.0)
    if node_attached_dot_entity != bind_to_eid || distance_sq(pos, transform[3]) > min_distance_between_sq
      return false
    fire_source_dot_startTime = get_sync_time() - fire_source_dot_spreadTime
    return true
  return fireNearby

def attach_fire(pos : float3;
                bind_to_eid : ecs::EntityId;
                coll_node_id : int;
                fire_template : string;
                offender : EntityId;
                min_distance_between_sq: float)
  if reigniteOldFireIfExists(bind_to_eid, pos, min_distance_between_sq)
    return true

  var localPos = pos
  var nodeId = 0
  query(bind_to_eid) <| $ [es] (animchar : AnimcharBaseComponent; collres: CollisionResource)
    nodeId = max(0, collres_get_geom_node(collres, animchar, coll_node_id))
  if !get_node_local_pos(bind_to_eid, nodeId, localPos)
    return false

  var posTm : float3x4
  identity(posTm)
  posTm[3] = pos

  let new_eid = createEntity(fire_template) <| $ (var init:ComponentsInitializer)
    set(init, "transform", posTm)
    set(init, "dmgzone.burningOffender", offender)
  attach_to_node_pos(new_eid, bind_to_eid, nodeId, localPos)
  return true

def deal_damage_or_attach_fire(pos : float3;
                               eid : ecs::EntityId;
                               node_id : int;
                               fire_template : string;
                               damage : FlameDamage;
                               min_distance_between_sq: float)
  return deal_fire_damage(eid, damage) || attach_fire(pos, eid, node_id, fire_template, damage.offender, min_distance_between_sq)

def create_fire(pos : float3; fire_template : string; offender : EntityId; min_distance_between_sq: float)
  let tooClose = find_query() <| $ [es (REQUIRE=fire_source, REQUIRE_NOT=node_attached_dot_entity)] (transform : float3x4;
                                                                                                            var fire_source_dot_startTime : float&;
                                                                                                            fire_source_dot_spreadTime : float = 0.0)
    if distance_sq(pos, transform[3]) > min_distance_between_sq
      return false
    fire_source_dot_startTime = get_sync_time() - fire_source_dot_spreadTime
    return true
  if tooClose
    return

  createEntity(fire_template) <| $ (var init:ComponentsInitializer)
    var tm : float3x4
    identity(tm)
    tm[3] = pos
    set(init, "transform", tm)
    set(init, "dmgzone.burningOffender", offender)

def capsule_capsule_intersection(a,b,c,d: float3; dist_sq : float)
  var mua, mub : float
  line_line_intersect(b, a, c, d, mua, mub)
  let line1 = a - b
  let line2 = d - c
  let pOnFirst = b + line1 * saturate(mua)
  let pOnSecond = c + line2 * saturate(mub)
  return distance_sq(pOnFirst, pOnSecond) < dist_sq

def is_human_hit(eid : EntityId; trace_start : float3; trace_end : float3; max_dist_sq : float)
  var hit = false
  query(eid) <| $ [es (REQUIRE=human)] (animchar : AnimcharBaseComponent;
                                        transform : float3x4;
                                        human_use_object_dot_nodeId : int)
    let headPos = animchar_get_node_wpos(animchar, human_use_object_dot_nodeId)
    let lowestPos = transform[3]
    hit = capsule_capsule_intersection(lowestPos, headPos, trace_start, trace_end, max_dist_sq)
  return hit

def apply_fire_cloud_damage(trace_start, trace_end : float3; radius : float; damage : FlameDamage)
  let radiusSq = square(radius)
  for_each_object_in_grid(GridType GT_DEFAULT, BBox3(min(trace_start, trace_end), max(trace_start, trace_end))) <| $ (obj : TraceableGridCollision#)
    if is_human_hit(obj.eid, trace_start, trace_end, radiusSq)
      deal_fire_damage(obj.eid, damage, false)

def burn_grid_objects(start : float3;
                      hit_dir : float3;
                      hit_dist : float;
                      fire_template : string;
                      damage : FlameDamage;
                      min_between_fire_dist_sq : float;
                      additional_check_length : float = 0.0)
  var res = INVALID_ENTITY_ID
  trace_grid_objects(start, hit_dir, hit_dist + additional_check_length, GridType GT_DEFAULT) <| $(intersections:array<IntersectedEntity>#)
    for it in intersections
      if it.depth <= 0
        deal_damage_or_attach_fire(it.pos, it.eid, it.collNodeId, fire_template, damage, min_between_fire_dist_sq)
        res = it.eid
        break
  return res

def burn_static_objects(start : float3;
                        hit_dir : float3;
                        hit_dist : float;
                        fire_template : string;
                        owner : EntityId;
                        min_between_fire_dist_sq : float;
                        additional_check_length : float = 0.0)
  var norm : float3
  var dist = hit_dist + additional_check_length
  let isRayHit = traceray_normalized(start, hit_dir, dist, norm, ETF_ALL)
  if isRayHit
    let hitPos = start + hit_dir * dist
    create_fire(hitPos, fire_template, owner, min_between_fire_dist_sq)
  return isRayHit

def get_droplet_spread_dir(stream_dir, hit_norm: float3; spread : DropletSpread)
  var dir = reflect(stream_dir, hit_norm)
  dir.y = max(0.0, dir.y) + rnd_float(spread.pitchMin, spread.pitchMax)
  dir.x += rnd_float(-spread.yaw, spread.yaw)
  dir.z += rnd_float(-spread.yaw, spread.yaw)
  return normalize(dir)

def cast_droplets(hit_pos : float3;
                  hit_norm : float3;
                  stream_dir: float3;
                  fire_template : string;
                  damage: FlameDamage;
                  min_between_fire_dist_sq : float;
                  spread : DropletSpread)
  let dir = get_droplet_spread_dir(stream_dir, hit_norm, spread)
  let start = hit_pos + hit_norm * spread.normalOffset

  if !burn_grid_objects(start, dir, spread.maxLength, fire_template, damage, min_between_fire_dist_sq)
    burn_static_objects(start, dir, spread.maxLength, fire_template, damage.offender, min_between_fire_dist_sq)

def shoot_fire(dt : float;
               gloc : GunLocation;
               fire_template : string;
               radius : float;
               cloud_radius : float;
               min_between_fire_dist : float;
               additional_check_length : float;
               damage : FlameDamage;
               flamethrower_dot_flameStartOffset : float;
               flamethrower_dot_cloudStartOffset : float;
               flamethrower_dot_maxFlameLength : float;
               flamethrower_dot_flameSpeed : float;
               droplets_spread : DropletSpread;
               var flamethrower_dot_flameCurrentLength : float&)
  flamethrower_dot_flameCurrentLength = clamp(flamethrower_dot_flameCurrentLength + flamethrower_dot_flameSpeed * dt, 0.0, flamethrower_dot_maxFlameLength)

  if gloc.gunPos == null
    return

  let gunPos : float3& = *(gloc.gunPos)
  let minBetweenFireDistSq = min_between_fire_dist * min_between_fire_dist
  let gunDir = gloc.gunDir
  let start = gunPos + gunDir * flamethrower_dot_flameStartOffset
  let end = start + gunDir * flamethrower_dot_flameCurrentLength

  if (flamethrower_dot_flameCurrentLength > flamethrower_dot_cloudStartOffset)
    let fireCloudStart = start + gunDir * flamethrower_dot_cloudStartOffset
    let fireCloudEnd = start + gunDir * max(flamethrower_dot_cloudStartOffset, flamethrower_dot_flameCurrentLength - cloud_radius)
    apply_fire_cloud_damage(fireCloudStart, fireCloudEnd, cloud_radius, damage)

  var out : ShapeQueryOutput
  if !sphere_cast_ex(start, end, radius, out, -1, [[CollisionObject]], null, int(PhysLayer EPL_ALL))
    return

  flamethrower_dot_flameCurrentLength *= out.t

  let hitPos = out.res
  let hitDist = length(hitPos - start)
  let hitDir = (hitPos - start) * safeinv(hitDist)

  if out.t >= 1.0 // no hit, all stream fuel has burned out
    return
  let burnedEid = burn_grid_objects(start, hitDir, hitDist, fire_template, damage, minBetweenFireDistSq, additional_check_length)
  if !burnedEid && !burn_static_objects(start, hitDir, hitDist, fire_template, damage.offender, minBetweenFireDistSq, additional_check_length)
    return
  if !has(burnedEid, "burning.absorbsFlameStream")
    cast_droplets(hitPos, out.norm, gunDir, fire_template, damage, minBetweenFireDistSq, droplets_spread)

def update_gun(var gun : IGunHolder; evt : CmdWeapPhysUpdate; gun_dot_curShellId : ShellPropIds; var gun_dot_ammo : int&)
  var gunInput : GunInput
  gunInput.atTime = evt.atTime;
  gunInput.isForReal = evt.isForReal;
  gunInput.rndSeed = phys_time_to_seed(evt.atTime);
  gunInput.curShellId = gun_dot_curShellId;

  gun_update(gun, gunInput, gun_dot_ammo, evt.gctrl, evt.gloc)


[es (tag=server)]
def flamethrower_phys(evt : CmdWeapPhysUpdate;
                      var gun_dot_ammo : int&;
                      var gun : IGunHolder;
                      var flamethrower_dot_flameCurrentLength: float&;
                      var flamethrower_dot_active : bool&;
                      gun_dot_curShellId : ShellPropIds;
                      gun_dot_owner : EntityId;
                      flamethrower_dot_fireTemplate: string;
                      flamethrower_dot_flameStreamRadius : float;
                      flamethrower_dot_flameCloudRadius : float;
                      flamethrower_dot_flameSpeed: float;
                      flamethrower_dot_maxFlameLength : float;
                      flamethrower_dot_streamDamagePerSecond: float;
                      flamethrower_dot_cloudDamagePerSecond: float;
                      flamethrower_dot_friendlyDamagePerSecond: float;
                      flamethrower_dot_shouldSetFriendlyOnFire : bool;
                      flamethrower_dot_minBetweenFireDist : float;
                      flamethrower_dot_flameStartOffset : float;
                      flamethrower_dot_dropletLength : float;
                      flamethrower_dot_dropletSpreadYaw : float;
                      flamethrower_dot_dropletSpreadPitchMin : float;
                      flamethrower_dot_dropletSpreadPitchMax : float;
                      flamethrower_dot_dropletNormalOffset : float;
                      flamethrower_dot_cloudStartOffset : float;
                      flamethrower_dot_additionalCheckDistance : float = 0.25)
  if !evt.isForReal
    return

  if !evt.gctrl.shoot
    flamethrower_dot_flameCurrentLength = 0.0
  elif gun_dot_ammo != 0
    let flameDamage = [[FlameDamage offender                = gun_dot_owner,
                                    offenderTeam            = get_int(gun_dot_owner, "team") ?? TEAM_UNASSIGNED,
                                    streamDamage            = evt.dt * flamethrower_dot_streamDamagePerSecond,
                                    cloudDamage             = evt.dt * flamethrower_dot_cloudDamagePerSecond,
                                    friendlyDamage          = evt.dt * flamethrower_dot_friendlyDamagePerSecond,
                                    shouldSetFriendlyOnFire = flamethrower_dot_shouldSetFriendlyOnFire]]
    let dropletsSpread = [[DropletSpread yaw          = flamethrower_dot_dropletSpreadYaw,
                                         pitchMin     = flamethrower_dot_dropletSpreadPitchMin,
                                         pitchMax     = flamethrower_dot_dropletSpreadPitchMax,
                                         maxLength    = flamethrower_dot_dropletLength,
                                         normalOffset = flamethrower_dot_dropletNormalOffset]]
    shoot_fire(evt.dt, evt.gloc, flamethrower_dot_fireTemplate,
               flamethrower_dot_flameStreamRadius, flamethrower_dot_flameCloudRadius,
               flamethrower_dot_minBetweenFireDist, flamethrower_dot_additionalCheckDistance,
               flameDamage, flamethrower_dot_flameStartOffset, flamethrower_dot_cloudStartOffset,
               flamethrower_dot_maxFlameLength, flamethrower_dot_flameSpeed,
               dropletsSpread,
               flamethrower_dot_flameCurrentLength)

  flamethrower_dot_active = evt.gctrl.shoot && gun_dot_ammo > 0
  update_gun(gun, evt, gun_dot_curShellId, gun_dot_ammo)

[es (tag=gameClient, REQUIRE=flamethrower_dot_fireTemplate)]
def flamethrower_phys_client(evt : CmdWeapPhysUpdate;
                             var gun : IGunHolder;
                             var gun_dot_ammo : int&;
                             gun_dot_curShellId : ShellPropIds)
  if evt.isForReal
    update_gun(gun, evt, gun_dot_curShellId, gun_dot_ammo)

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def flamethrower_init(evt : Event;
                      flamethrower_dot_maxFlameLength : float;
                      flamethrower_dot_maxFlameLengthTime : float;
                      var flamethrower_dot_flameSpeed : float&)
  flamethrower_dot_flameSpeed = safediv(flamethrower_dot_maxFlameLength, flamethrower_dot_maxFlameLengthTime)