local log = require("std/log.nut")().with_prefix("[HERO_RESPAWN]")

local function onRequestRespawn(evt, eid, comp) {
  local respRequestedSquadId  = evt.data?.squadId ?? 0
  local respRequestedMemberId = evt.data?.memberId ?? 0
  local respawnGroupId        = evt.data?.spawnGroup ?? -1
  log($"onRequestRespawn: {eid}; isAlive: {comp.isAlive}; squadId: {respRequestedSquadId}; memberId: {respRequestedMemberId}; groupId: {respawnGroupId};")
  if (!comp.isAlive) {
    comp["respawner.respRequested"] = true
    comp["respawner.respRequestedSquadId"]  = respRequestedSquadId
    comp["respawner.respRequestedMemberId"] = respRequestedMemberId
    comp["respawner.respawnGroupId"]        = respawnGroupId
  }
}

local function onCancelRequestRespawn(evt, eid, comp) {
  local respRequestedSquadId  = evt.data?.squadId ?? 0
  local respRequestedMemberId = evt.data?.memberId ?? 0
  local respawnGroupId        = evt.data?.spawnGroup ?? -1
  log($"onCancelRequestRespawn: {eid}; isAlive: {comp.isAlive}; squadId: {respRequestedSquadId}; memberId: {respRequestedMemberId}; groupId: {respawnGroupId};")
  if (!comp.isAlive) {
    comp["respawner.respRequested"] = false
    comp["respawner.respRequestedSquadId"]  = respRequestedSquadId
    comp["respawner.respRequestedMemberId"] = respRequestedMemberId
    comp["respawner.respawnGroupId"]        = respawnGroupId
  }
}

::ecs.register_es("respawn_req_es",
  {
    [::ecs.sqEvents.CmdRequestRespawn] = onRequestRespawn,
    [::ecs.sqEvents.CmdCancelRequestRespawn] = onCancelRequestRespawn
  },
  {
    comps_ro = [["isAlive", ::ecs.TYPE_BOOL]]
    comps_rw = [
      ["respawner.respawnGroupId", ::ecs.TYPE_INT],
      ["respawner.respRequested", ::ecs.TYPE_BOOL],
      ["respawner.respRequestedSquadId", ::ecs.TYPE_INT],
      ["respawner.respRequestedMemberId", ::ecs.TYPE_INT],
    ]
  },
  {tags="server"}
)

::ecs.register_es("respawn_clear_es",
  {
    onChange = function(evt, eid, comp) {
      if (!comp["respawner.enabled"])
        ::ecs.g_entity_mgr.destroyEntity(eid)
    }
  },
  {
    comps_rq = ["respawner"]
    comps_track = [["respawner.enabled", ::ecs.TYPE_BOOL]]
  },
  {tags="server"})
 