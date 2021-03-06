local {EventTeamMemberJoined, EventTeamMemberLeave} = require("teamevents")

local onMemberCountChangedQuery = ::ecs.SqQuery("onMemberCountChangedQuery", {comps_ro = [
      ["team.balancedRespawnTime", ::ecs.TYPE_FLOAT], ["team.disbalancedRespawnIncrease", ::ecs.TYPE_FLOAT], ["team.id", ::ecs.TYPE_INT], ["team.memberCount", ::ecs.TYPE_FLOAT]]})
local captureSpeedMulQuery = ::ecs.SqQuery("captureSpeedMulQuery", {comps_rw = [["team.captureSpeedMult", ::ecs.TYPE_FLOAT]],
      comps_ro = [["team.disbalanceCapSpeedMult", ::ecs.TYPE_FLOAT], ["team.memberCount", ::ecs.TYPE_FLOAT], ["team.id", ::ecs.TYPE_INT]]})

local teamsMebmberCountQuery = ::ecs.SqQuery("teamsMebmberCountQuery", {comps_ro = [["team.memberCount", ::ecs.TYPE_FLOAT]]})
local function onMemberCountChanged() {
  local minTeamMembers = 1 << 30
  teamsMebmberCountQuery(
    function(eid, comp) {
      minTeamMembers = ::min(minTeamMembers, comp["team.memberCount"])
    })

  if (minTeamMembers == 0)
    return
  onMemberCountChangedQuery(
      function(eid, comp) {
        local mult = minTeamMembers > 0 ? max(0.0, comp["team.memberCount"] / minTeamMembers - 1.0) : 0.0
        local overrideParams = ::ecs.get_comp_val(eid, "team.overrideUnitParam").getAll()
        if ("respawner.respTime" in overrideParams && "respawner.respTimeout" in overrideParams) {
          local resTime = comp["team.balancedRespawnTime"] + comp["team.disbalancedRespawnIncrease"] * mult
          overrideParams["respawner.respTime"] = resTime
          overrideParams["respawner.respTimeout"] = resTime
          ::ecs.set_comp_val(eid, "team.overrideUnitParam", overrideParams)
        }
      })
  captureSpeedMulQuery(
    function(eid, comp){
      local mult = ::max(0.5, 1.0 + (1.0 - comp["team.memberCount"] / minTeamMembers) * comp["team.disbalanceCapSpeedMult"])
      comp["team.captureSpeedMult"] = mult
    })
}

local function onTeamMemberJoined(evt, eid, comp) {
  local tid = evt[1]
  if (tid != comp["team.id"])
    return
  local eidMember = evt[0]
  if (comp["team.members"].getAll().indexof(eidMember) == null) {
    comp["team.members"].append(eidMember)
    comp["team.memberCount"] = comp["team.countAdd"] + comp["team.members"].len()
    onMemberCountChanged()
    if (comp["team.capacity"] >= 0 && comp["team.memberCount"] >= comp["team.capacity"])
      comp["team.locked"] = true
  }
}


local function onTeamMemberLeft(evt, eid, comp) {
  local tid = evt[1]
  if (tid != comp["team.id"])
    return
  local idx = comp["team.members"].getAll().indexof(evt[0])
  if (idx != null) {
    comp["team.members"].remove(idx)
    comp["team.memberCount"] = comp["team.countAdd"] + comp["team.members"].len()
    // after removing we should check if other team is disbalanced now so they have an advantage and rebalance them
    // by either adding them respawn time or by adding them capture time
    onMemberCountChanged()
  }
}


local comps = {
  comps_rw = [
    ["team.id", ::ecs.TYPE_INT],
    ["team.memberCount", ::ecs.TYPE_FLOAT],
    ["team.locked", ::ecs.TYPE_BOOL],
    ["team.score", ::ecs.TYPE_FLOAT],
    ["team.members", ::ecs.TYPE_ARRAY],
  ]
  comps_ro = [
    ["team.scoreCap", ::ecs.TYPE_FLOAT],
    ["team.countAdd", ::ecs.TYPE_FLOAT, 0.0],
    ["team.capacity", ::ecs.TYPE_INT, -1],
    ["team.should_lock", ::ecs.TYPE_BOOL, false],
  ]
}

::ecs.register_es("team_es", {
  [EventTeamMemberJoined] = onTeamMemberJoined,
  [EventTeamMemberLeave] = onTeamMemberLeft,
}, comps, {tags = "server"})
 