local random = require("dagor.random")

local awardsLog = require("eventlog.nut").awards
local {localPlayerEid} = require("local_player.nut")

local lastShownId = persist("lastShownId", @() Watched(0))


local function trackComponents(evt, eid, comp) {
  if (eid!=localPlayerEid.value)
    return

  local awards = comp.awards
  local len = awards.len()
  local firstNewIdx = null

  for (local i=len-1; i>=0; --i) {
    local a = awards[i].getAll()
    if (a.id <= lastShownId.value)
      break
    firstNewIdx = i
  }

  if (firstNewIdx != null) {
    for (local i=firstNewIdx; i<len; ++i) {
      local a = awards[i].getAll()
      if (loc($"hud/awards/{a.type}", "") != "") {
        awardsLog.pushEvent({
          ttl = 5.0
          awardData = a
        }, ["awardData","type"])
      }
      lastShownId(::max(lastShownId.value, a.id))
    }
  }
}


::ecs.register_es("award_ui_es", {
    onInit = trackComponents,
    onChange = trackComponents,
  }, {comps_track = [["awards", ::ecs.TYPE_ARRAY]]})


local function addTestPlayerAward(awardType) {
  awardsLog.pushEvent({
    ttl = 5.0
    awardData = { type=awardType, id=lastShownId.value+1 }
  }, ["awardData","type"])
}

local test_awards_types = ["Headshot", "Grenade kill", "s", "long long long award", "Melee kill", "kill"]
::console.register_command(function() {
  local rand_seed = random.get_rnd_seed()
  local awardType = test_awards_types?[rand_seed%(test_awards_types.len()-1)] ?? "test"
  addTestPlayerAward(awardType)
  }, "ui.add_test_award")
 