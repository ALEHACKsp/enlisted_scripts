local {CmdRequestHumanSpeech} = require("speechevents")
local {gensound_make_hash} = require("gensound")
local is_teams_friendly = require("globals/is_teams_friendly.nut")
local { is_point_in_zone } = require("ecs.utils")

local function onZoneStartCapture(evt, eid, comp) {
  if (evt.data.team == comp["team"] && is_point_in_zone(comp["transform"].getcol(3), evt.data.eid, 1.))
    ::ecs.g_entity_mgr.sendEvent(eid, CmdRequestHumanSpeech(gensound_make_hash("startCapture"), 1.))
}

local function onZoneStartDecapture(evt, eid, comp) {
  local zoneEid = evt.data.eid
  local zoneTeam = evt.data.team
  if (is_teams_friendly(zoneTeam, comp["team"]))
    return
  local humanTm = comp["transform"]
  if (!is_point_in_zone(humanTm.getcol(3), evt.data.eid, 1.)) {
    local zoneTm = ::ecs.get_comp_val(zoneEid, "transform")
    if (!zoneTm || ((zoneTm.getcol(3) - humanTm.getcol(3)) * humanTm.getcol(0) < 0.) ||
        !is_point_in_zone(humanTm.getcol(3), evt.data.eid, comp["human_net_speech.decaptureZoneScale"]))
      return
  }
  ::ecs.g_entity_mgr.sendEvent(eid, CmdRequestHumanSpeech(gensound_make_hash("enemyStartCapture"), 1.))
}

::ecs.register_es("zone_capture_human_net_speech_es",
  {
    [::ecs.sqEvents.EventZoneStartCapture] = onZoneStartCapture,
    [::ecs.sqEvents.EventZoneStartDecapture] = onZoneStartDecapture,
  },
  {
    comps_ro = [
      ["transform", ::ecs.TYPE_MATRIX],
      ["team", ::ecs.TYPE_INT],
      ["human_net_speech.decaptureZoneScale", ::ecs.TYPE_FLOAT],
    ]
  }, {tags = "server"}
)
 