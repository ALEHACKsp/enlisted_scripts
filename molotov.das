require ecs
require app
require math
require math.base
require game.es.events
require Dacoll
require GridCollision
require game.es.node_attach
require AnimV20
require CollRes

def create_fire(pos : float3; tmplt : string; offender : EntityId; min_distance_between_sq: float; var fires : array<float3>)
  var found = false
  for otherFirePos in fires
    if length_sq(pos - otherFirePos) < min_distance_between_sq
      found = true
      break
  if found
    return
  push(fires, pos)

  query() <| $ [es (REQUIRE=fire_source, REQUIRE_NOT=node_attached_dot_entity)] (eid : EntityId; transform : float3x4)
    if length_sq(pos - transform[3]) < min_distance_between_sq
      destroyEntity(eid)

  createEntity(tmplt) <| $ (var init:ComponentsInitializer)
    var tm : float3x4
    identity(tm)
    tm[3] = pos
    set(init, "transform", tm)
    set(init, "dmgzone.burningOffender", offender)

def attach_fire(pos : float3;
                bindToEid : ecs::EntityId;
                collNodeId : int;
                tmplt : string;
                offender : EntityId;
                min_distance_between_sq: float;
                var attached_fires : array<tuple<EntityId; float3> >)
  var found = false
  for otherFire in attached_fires
    let otherFireEid=otherFire._0
    let otherFirePos=otherFire._1
    if otherFireEid == bindToEid && length_sq(pos - otherFirePos) < min_distance_between_sq
      found = true
      break
  if found
    return
  push(attached_fires, [[auto bindToEid, pos]])

  var localPos = pos
  var nodeId = 0
  query(bindToEid) <| $ [es] (animchar : AnimcharBaseComponent; collres: CollisionResource)
    nodeId = max(0, collres_get_geom_node(collres, animchar, collNodeId))
  if !get_node_local_pos(bindToEid, nodeId, localPos)
    return

  query() <| $ [es (REQUIRE=fire_source)] (eid : EntityId; transform: float3x4; node_attached_dot_entity : EntityId)
    if node_attached_dot_entity == bindToEid && length_sq(pos - transform[3]) < min_distance_between_sq
      destroyEntity(eid)

  var posTm : float3x4
  identity(posTm)
  posTm[3] = pos

  let new_eid = createEntity(tmplt) <| $ (var init:ComponentsInitializer)
    set(init, "transform", posTm)
    set(init, "dmgzone.burningOffender", offender)
  attach_to_node_pos(new_eid, bindToEid, nodeId, localPos)

def create_fire_on_object_ray(pos : float3; dir : float3; max_distance : float; tmplt : string; offender : EntityId; min_distance_between_sq: float;
                              var attached_fires : array<tuple<EntityId; float3> >) : bool
  var created = false
  GridCollision::trace_grid_objects(pos, dir, max_distance, GridType GT_DEFAULT) <| $(intersections:array<IntersectedEntity>#)
    for it in intersections
      if it.depth > 0 || has(it.eid, "human_net_phys")
        continue

      attach_fire(it.pos, it.eid, it.collNodeId, tmplt, offender, min_distance_between_sq, attached_fires)
      created = true
      break
  return created

def create_fire_on_ground_ray(pos : float3; dir: float3; max_distance : float; tmplt : string; offender: EntityId; min_distance_between_sq: float; var fires : array<float3>)
  var t = max_distance
  var norm : float3
  if traceray_normalized(pos, dir, t, norm, ETF_ALL)
    create_fire(pos + dir * t, tmplt, offender, min_distance_between_sq, fires)
    return true
  return false

def create_fire_on_trace(pos : float3; dir : float3; max_distance : float; tmplt : string; offender : EntityId; min_distance_between_sq: float;
                         var fires : array<float3>; var attached_fires : array<tuple<EntityId; float3> >)
  if create_fire_on_object_ray(pos, dir, max_distance, tmplt, offender, min_distance_between_sq, attached_fires)
    return true
  return create_fire_on_ground_ray(pos, dir, max_distance, tmplt, offender, min_distance_between_sq, fires)

def get_spread_dirs(tm : float3x4; molotov_spread : ecs::Point3List)
  var spread_dirs : array<float3>
  let DEG_TO_RADS = PI / 180.0
  for i in iter_range(molotov_spread)
    let spread : float3 const& = molotov_spread[i]
    let azimuth = spread.x * DEG_TO_RADS
    let elevation = spread.y * DEG_TO_RADS
    var sinElevation, cosElevation, sinAzimuth, cosAzimuth: float
    sincos(elevation, sinElevation, cosElevation)
    sincos(azimuth, sinAzimuth, cosAzimuth)
    let rayLocal = float3(cosElevation * cosAzimuth, sinElevation, cosElevation * sinAzimuth)
    push(spread_dirs, tm * rayLocal)
  return <- spread_dirs

def get_global_spread_dirs(dir : float3; molotov_spread : ecs::Point3List)
  let yaxis = float3(0.0, 1.0, 0.0)
  let zaxis = normalize(cross(normalize(dir), yaxis))
  let xaxis = cross(yaxis, zaxis)

  var tm : float3x4
  tm[0] = xaxis
  tm[1] = yaxis
  tm[2] = zaxis

  return <- get_spread_dirs(tm, molotov_spread)

def get_local_spread_dirs(dir : float3; molotov_spread : ecs::Point3List)
  let up = float3(0.0, 1.0, 0.0)
  let xaxis = normalize(dir)
  let zaxis = normalize(cross(xaxis, up))
  let yaxis = cross(zaxis, xaxis)

  var tm : float3x4
  tm[0] = xaxis
  tm[1] = yaxis
  tm[2] = zaxis

  return <- get_spread_dirs(tm, molotov_spread)

def create_fire_on_dirs(pos : float3; dirs : array<float3>; spread_data : ecs::Point3List; tmplt : string; offender : EntityId;
                        min_distance_between_sq: float; var fires : array<float3>; var attached_fires : array<tuple<EntityId; float3> >)
  for dir, spread in dirs, spread_data
    create_fire_on_trace(pos, dir, spread.z, tmplt, offender, min_distance_between_sq, fires, attached_fires)

def explode_molotov(var pos : float3;
                    speed_dir : float3;
                    tmplt : string;
                    offender : EntityId;
                    minHeight : float;
                    spread_local : ecs::Point3List;
                    spread_global : ecs::Point3List;
                    max_fire_drop_height : float;
                    min_distance_between_sq : float)
  var fires : array<float3>
  var attached_fires : array<tuple<EntityId; float3> >
  var height = max_fire_drop_height
  tracedown_normalized(pos, height, ETF_DEFAULT)
  if height < minHeight
    pos.y += (minHeight - height)
    height = minHeight

  create_fire_on_dirs(pos, get_local_spread_dirs(speed_dir, spread_local), spread_local, tmplt, offender, min_distance_between_sq, fires, attached_fires)
  create_fire_on_dirs(pos, get_global_spread_dirs(speed_dir, spread_global), spread_global, tmplt, offender, min_distance_between_sq, fires, attached_fires)

  if !create_fire_on_trace(pos, float3(0.0, -1.0, 0.0), height, tmplt, offender, min_distance_between_sq, fires, attached_fires)
    create_fire(pos - float3(0.0, height, 0.0), tmplt, offender, min_distance_between_sq, fires)

[es (tag=server)]
def molotov_exploded(evt: CmdShellExplode;
                     shell_dot_owner : EntityId;
                     on_exploded_dot_create : string;
                     molotov_spread_dot_globalRays : ecs::Point3List;
                     molotov_spread_dot_localRays : ecs::Point3List;
                     molotov_spread_dot_minHeight : float = 0.2;
                     molotov_fire_dot_minDistanceBetween : float = 0.5;
                     molotov_spread_dot_dropMaxHeight : float = 20.0;
                     molotov_spread_dot_stepBack : float = 0.2)
  let dir = normalize(evt.vel)
  let start = evt.position - dir * molotov_spread_dot_stepBack
  explode_molotov(start, dir, on_exploded_dot_create, shell_dot_owner, molotov_spread_dot_minHeight, molotov_spread_dot_localRays, molotov_spread_dot_globalRays,
                  molotov_spread_dot_dropMaxHeight, square(molotov_fire_dot_minDistanceBetween))
