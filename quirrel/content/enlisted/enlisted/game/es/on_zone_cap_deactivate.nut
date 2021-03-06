local {TEAM_UNASSIGNED} = require("team")
local {EventZoneDeactivated, EventZoneCaptured} = require("zoneevents")
local checkZonesGroup = require("zone_cap_group.nut").capZonesGroupMustChanged

local onZoneCapturedQuery = ::ecs.SqQuery("onZoneCapturedQuery", {
  comps_ro = [
    ["groupName", ::ecs.TYPE_STRING],
    ["deactivatable", ::ecs.TYPE_BOOL, true],
    ["deactivationDelay", ::ecs.TYPE_FLOAT, -1.0]
  ]
})

local onZoneCapturedRespBasesQuery = ::ecs.SqQuery("onZoneCapturedRespBasesQuery", {
  comps_ro = [["groupName", ::ecs.TYPE_STRING]]
  comps_rq = ["respbase"]
})

local function onZoneCaptured(evt, eid, comp) {
  local zoneEid = evt[0]
  local teamId = evt[1]
  if (zoneEid != eid)
    return
  if (comp["capzone.deactivateAfterCap"]) {
    if (!checkZonesGroup(comp["capzone.checkAllZonesInGroup"], eid, teamId, comp["capzone.mustBeCapturedByTeam"], comp["groupName"]))
      return
    local groupName = comp.groupName
    local function sendEventOnCap(eid, comps) {
      if (comps.groupName == groupName && comps.deactivatable) {
        local deactive = @() ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventEntityActivate({activate=false}))
        if (comps.deactivationDelay > 0.0) {
          ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventEntityAboutToDeactivate())
          ::ecs.set_callback_timer(deactive, comps.deactivationDelay, false)
        }
        else
          deactive()
      }
    }
    onZoneCapturedQuery.perform(sendEventOnCap)
    if (comp["capzone.deactivateAfterTimeout"] > 0.0) {
      local function sendEventOnCapToResp(eid, respBaseComp) {
        if (respBaseComp.groupName == groupName)
          ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventEntityActivate({activate=false}))
      }
      onZoneCapturedRespBasesQuery.perform(sendEventOnCapToResp)
    }
  }
}

::ecs.register_es("capzone_on_deactivate_es", {
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneDeactivated] = onZoneCaptured
  },
  {
    comps_ro = [
      ["groupName", ::ecs.TYPE_STRING],
      ["capzone.deactivateAfterCap", ::ecs.TYPE_BOOL],
      ["capzone.deactivateAfterTimeout", ::ecs.TYPE_FLOAT, -1.0],
      ["capzone.checkAllZonesInGroup",::ecs.TYPE_BOOL, false],
      ["capzone.capTeam", ::ecs.TYPE_INT],
      ["capzone.mustBeCapturedByTeam", ::ecs.TYPE_INT, TEAM_UNASSIGNED]
    ]
  }, {tags = "server"}
)

local function onZoneCapturedDeactGroups(evt, eid, comp) {
  local zoneEid = evt[0]
  if (zoneEid != eid)
    return
  local deactGroups = comp["capzone.deactivateGroupsAfterCap"]
  if (deactGroups.len()) {
    local function sendEventOnCap(eid, comps) {
      if (deactGroups.indexof(comps.groupName, ::ecs.TYPE_STRING) && comps.deactivatable)
        ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventEntityActivate({activate=false}))
    }
    onZoneCapturedQuery.perform(sendEventOnCap)
  }
}

::ecs.register_es("capzone_on_deactivate_groups_es", {
    [EventZoneCaptured] = onZoneCapturedDeactGroups,
    [EventZoneDeactivated] = onZoneCapturedDeactGroups,
  },
  {
    comps_ro = [
      ["groupName", ::ecs.TYPE_STRING],
      ["capzone.deactivateGroupsAfterCap", ::ecs.TYPE_ARRAY],
    ]
  }, {tags = "server"}
)
 