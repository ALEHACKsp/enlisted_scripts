local {find_connected_player_that_possess} = require("globals/common_queries.nut")
local {CmdPossessEntity} = require("respawnevents")
local {CmdSwitchSquadLeader} = require("gameevents")

local squadQuery = ::ecs.SqQuery("squadQuery", {
  comps_ro = [
    ["squad_member.memberIdx", ::ecs.TYPE_INT],
    ["squad_member.squad", ::ecs.TYPE_EID],
    ["squad_member.canBeLeader", ::ecs.TYPE_BOOL],
    ["isAlive", ::ecs.TYPE_BOOL],
  ]
})

local setAiSquadQuery = ::ecs.SqQuery("setAiSquadQuery", {
  comps_rw = [["beh_tree.enabled", ::ecs.TYPE_BOOL],["human_weap.infiniteAmmoHolders", ::ecs.TYPE_BOOL]],
  comps_ro = [["squad_member.squad", ::ecs.TYPE_EID]]
})

local function findNextMember(squadEid, curLeaderEid, curMemberIdx) {
  local foundEid = INVALID_ENTITY_ID
  local foundPriority = 0

  squadQuery.perform(function(eid, comp) {
      if (eid == curLeaderEid)
        return
      local priority = (comp["squad_member.memberIdx"] - curMemberIdx + 10000) % 10000
      if (foundEid == INVALID_ENTITY_ID || priority < foundPriority) {
        foundEid = eid
        foundPriority = priority
      }
    },
    "and(and(eq(squad_member.squad,{0}:eid),eq(isAlive,true)),eq(squad_member.canBeLeader,true))".subst(squadEid))

  return foundEid
}

local function switchSquadLeader(evt, squadEid, comp) {
  local switchToMemberEid = evt[0]
  local curLeaderEid = comp["squad.leader"]

  if (switchToMemberEid == INVALID_ENTITY_ID) {
    local curMemberIdx = ::ecs.get_comp_val(curLeaderEid, "squad_member.memberIdx") ?? -1
    switchToMemberEid = findNextMember(squadEid, curLeaderEid, curMemberIdx)
  }

  if (switchToMemberEid == INVALID_ENTITY_ID)
    return

  comp["squad.leader"] = switchToMemberEid

  setAiSquadQuery.perform(
    function(eid, comp) {
      comp["beh_tree.enabled"] = eid != switchToMemberEid
      comp["human_weap.infiniteAmmoHolders"] = comp["beh_tree.enabled"]
    },
    "eq(squad_member.squad,{0}:eid)".subst(squadEid))

  local playerEid = find_connected_player_that_possess(curLeaderEid)
  ::ecs.g_entity_mgr.sendEvent(playerEid, CmdPossessEntity(switchToMemberEid))
}

::ecs.register_es("switch_squad_leader_es", {
  [CmdSwitchSquadLeader] = switchSquadLeader
}, {
  comps_rw = [["squad.leader", ::ecs.TYPE_EID]]
},
{ tags = "server" }) 