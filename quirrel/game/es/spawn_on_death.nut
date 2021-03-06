local {EventEntityDied} = require("deathevents")
local {traceray_normalized} = require("dacoll.trace")
local {Point3} = require("dagor.math")
local { project_to_nearest_navmesh_point } = require("pathfinder")
local searchHumansQuery = ::ecs.SqQuery("searchHumansQuery", {
  comps_ro = [
    ["isAlive", ::ecs.TYPE_BOOL], ["spawnRestrictZone", ::ecs.TYPE_FLOAT], ["transform", ::ecs.TYPE_MATRIX]
  ],
  comps_rq=["human_net_phys"]
})

local function drop_on_collision(pos) {
  local dist = 1.0
  local hitT = traceray_normalized(pos + Point3(0.0, dist * 0.5, 0.0), Point3(0.0, -1.0, 0.0), dist)
  if (hitT >= 0.0)
    pos.y -= hitT - dist * 0.5
  return pos
}

local function spawn_entity_safe(template, comps, offset, timeout) {
  local transform = comps["transform"]
  local pos = transform * offset
  project_to_nearest_navmesh_point(pos, 1.0)
  pos = drop_on_collision(pos)
  transform.setcol(3, pos)
  ::ecs.set_callback_timer(function() {
    local offsetRadius = 0.5
    local collideAliveEntity = false
    local collideNormal = pos - transform.getcol(3)
    collideNormal.normalize()
    searchHumansQuery.perform(function(eid, comp) {
      local epos = comp.transform.getcol(3)
      local dir = pos - epos
      local distanceSq = dir.lengthSq()
      if (!comp.isAlive && offsetRadius < comp.spawnRestrictZone && distanceSq < 4.0) // 2 meters
        offsetRadius = comp.spawnRestrictZone
      if (distanceSq <= offsetRadius * offsetRadius) {
        dir.normalize()
        collideNormal = collideNormal + dir
        collideAliveEntity = true
      }
    })
    if (collideAliveEntity) {
      collideNormal.normalize()
      pos += collideNormal * offsetRadius
      project_to_nearest_navmesh_point(pos, 1.0)
      pos = drop_on_collision(pos)
      transform.setcol(3, pos)
    }
    comps["transform"] = [transform, ::ecs.TYPE_MATRIX]
    ::ecs.g_entity_mgr.createEntity(template, comps)
  }, timeout, false)
}

local function onEntityDied(evt, eid, comp) {
  local comps = {transform = comp["transform"]}
  foreach (ent in comp["on_death.spawnEntity"])
    spawn_entity_safe(ent.template, comps, ent.offset, ent.timeout)
}


::ecs.register_es("spawn_on_death_es", {
    [EventEntityDied] = onEntityDied,
  },
  {
    comps_ro = [
      ["on_death.spawnEntity", ::ecs.TYPE_ARRAY],
      ["transform", ::ecs.TYPE_MATRIX],
    ]
  },
  {tags="server"}
)

return {
  spawn_entity_safe = spawn_entity_safe
}
 