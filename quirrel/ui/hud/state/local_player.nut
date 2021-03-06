local { TEAM_UNASSIGNED } = require("team")
local {get_user_id} = require("net")
const INVALID_USER_ID = 0

local localPlayerUserId = persist("localPlayerUserId" @() Watched(INVALID_USER_ID))
local localPlayerEid = persist("eid", @() ::Watched(INVALID_ENTITY_ID))
local specTarget = persist("specTarget", @() ::Watched(INVALID_ENTITY_ID))
const UNDEFINEDNAME = "?????"
local localPlayerName = persist("localPlayerName", @() ::Watched(UNDEFINEDNAME))
local localPlayerTeam = persist("localPlayerTeam", @() ::Watched(TEAM_UNASSIGNED))

local state = {
  localPlayerName = localPlayerName
  localPlayerEid = localPlayerEid
  localPlayerTeam = localPlayerTeam
  localPlayerUserId = localPlayerUserId
  localPlayerSpecTarget = specTarget
}

local function resetData() {
  localPlayerEid.update(INVALID_ENTITY_ID)
  localPlayerTeam.update(TEAM_UNASSIGNED)
  localPlayerUserId(get_user_id())
  specTarget(INVALID_ENTITY_ID)
}

local function trackComponents(evt, eid, comp) {
  if (comp.is_local) {
    localPlayerEid.update(eid)
    localPlayerTeam.update(comp.team)
    localPlayerName(comp.name)
    localPlayerUserId(get_user_id())
    specTarget(comp.specTarget)
  } else if (localPlayerEid.value == eid) {
    resetData()
  }
}

local function onDestroy(evt, eid, comp) {
  if (localPlayerEid.value == eid)
    resetData()
}

::ecs.register_es("local_player_es", {
    onChange = trackComponents
    onInit = trackComponents
    onDestroy = onDestroy
  },
  {
    comps_track = [
      ["is_local", ::ecs.TYPE_BOOL],
      ["team", ::ecs.TYPE_INT],
      ["name", ::ecs.TYPE_STRING],
      ["specTarget", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
    ]
    comps_rq = ["player"]
  }
)

return state 