local {TEAM_UNASSIGNED} = require("team")
local activateGroup = require("game/utils/activate_group.nut")
local selectRandom = require("game/utils/random_list_selection.nut")
local checkZonesGroup = require("zone_cap_group.nut").capZonesGroupMustChanged
local {EventZoneCaptured, EventZoneDeactivated, EventZoneIsAboutToBeCaptured} = require("zoneevents")

local function onZoneCaptured(evt, eid, comp) {
  local zoneEid = evt[0]
  local teamId = evt[1]
  if (zoneEid != eid || !checkZonesGroup(comp["capzone.checkAllZonesInGroup"], eid,
       teamId, comp["capzone.mustBeCapturedByTeam"], comp["groupName"]))
    return
  local defGroupName = comp["capzone.activateAfterCap"]
  local paramName = $"capzone.activateAfterTeam{teamId}Cap"
  local groupName = ::ecs.get_comp_val(eid, paramName, defGroupName)
  ::print($"searching for {groupName} to activate from param {paramName}")
  activateGroup(groupName)
}

local findCapzoneQuery = ::ecs.SqQuery("findCapzoneQuery", {comps_ro = [["groupName", ::ecs.TYPE_STRING]] comps_rq=["capzone"]})
local findBattleAreaQuery = ::ecs.SqQuery("findCapzoneQuery", {comps_ro = [["groupName", ::ecs.TYPE_STRING]] comps_rq=["battle_area"]})

local function onZoneIsAboutToBeCaptured(evt, eid, comp) {
  local zoneEid = evt[0]
  local teamId = evt[1]
  if (zoneEid != eid || !checkZonesGroup(comp["capzone.checkAllZonesInGroup"], eid,
       teamId, comp["capzone.mustBeCapturedByTeam"], comp["groupName"]))
    return
  local defGroupName = comp["capzone.activateAfterCap"]
  local paramName = $"capzone.activateAfterTeam{teamId}Cap"
  local groupName = ::ecs.get_comp_val(eid, paramName, defGroupName)

  ::print($"searching capzone for {groupName} to activate from param {paramName}")

  local function activate(eid, comp) {
    if (comp.groupName == groupName)
      ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventEntityActivate({activate=true}))
  }
  findCapzoneQuery(activate)
  findBattleAreaQuery(activate)
}

::ecs.register_es("capzone_on_activate_es", {
  [EventZoneCaptured] = onZoneCaptured,
  [EventZoneIsAboutToBeCaptured] = onZoneIsAboutToBeCaptured,
  [EventZoneDeactivated] = onZoneCaptured,
}, {comps_ro = [["capzone.activateAfterCap", ::ecs.TYPE_STRING],
                ["groupName", ::ecs.TYPE_STRING], ["capzone.checkAllZonesInGroup", ::ecs.TYPE_BOOL, false],
                ["capzone.mustBeCapturedByTeam", ::ecs.TYPE_INT, TEAM_UNASSIGNED]]}, {tags="server"})

local function onZoneCapturedMultiple(evt, eid, comp) {
  local zoneEid = evt[0]
  local teamId = evt[1]
  if (zoneEid != eid || !checkZonesGroup(comp["capzone.checkAllZonesInGroup"], eid,
       teamId, comp["capzone.mustBeCapturedByTeam"], comp["groupName"]))
    return
  local choice = comp["capzone.activateChoiceAfterCap"]
  local teams = choice["team"]
  local nextGroup = selectRandom(teams[teamId.tostring()].getAll())
  if (nextGroup != null)
    activateGroup(nextGroup)
}

::ecs.register_es("capzone_on_activate_multiple_es",
  {
    [EventZoneCaptured] = onZoneCapturedMultiple,
    [EventZoneDeactivated] = onZoneCapturedMultiple,
  },
  {
    comps_ro = [ ["capzone.activateChoiceAfterCap", ::ecs.TYPE_OBJECT],["capzone.activateAfterCap", ::ecs.TYPE_STRING],
                 ["capzone.checkAllZonesInGroup", ::ecs.TYPE_BOOL, false], ["groupName", ::ecs.TYPE_STRING],
                 ["capzone.mustBeCapturedByTeam", ::ecs.TYPE_INT, TEAM_UNASSIGNED]]
  },
  {tags="server"}
)


 