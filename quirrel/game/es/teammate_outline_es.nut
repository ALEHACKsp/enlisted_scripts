local { TEAM_UNASSIGNED, FIRST_GAME_TEAM } = require("team")
local localPlayer = persist("localPlayer", @() { eid = INVALID_ENTITY_ID, team = TEAM_UNASSIGNED })


local teammate_outline_comps = {
  comps_ro = [
    ["teammate_outline.color", ::ecs.TYPE_COLOR],
    ["team", ::ecs.TYPE_INT]
  ]
  comps_rw = [
    ["outline.enabled", ::ecs.TYPE_BOOL],
    ["outline.color", ::ecs.TYPE_COLOR]
  ]
}


local heroToPlayerMap = {}

local function update_outline(eid, comp) {
  if (comp.team >= FIRST_GAME_TEAM && comp.team==localPlayer.team
        && (eid in heroToPlayerMap) && heroToPlayerMap[eid]!=localPlayer.eid) {
    comp["outline.enabled"] = true
    comp["outline.color"] = comp["teammate_outline.color"]
  }
  else {
    comp["outline.enabled"] = false
  }
}

local updateTeammatesQuery = ::ecs.SqQuery("updateTeammatesQuery", teammate_outline_comps)
local function updateTeammates(){
  updateTeammatesQuery.perform(update_outline)
}

local function player_onInit(evt, eid, comp) {
  if (comp["possessed"] != INVALID_ENTITY_ID)
    heroToPlayerMap[comp["possessed"]] <- eid

  if (comp.is_local) {
    localPlayer.eid = eid
    localPlayer.team = comp.team
    updateTeammates()
  }
}


local function player_trackComponents(evt, eid, comp) {
  local isLocal = comp.is_local
  local heroEid = comp["possessed"]
  if (eid == localPlayer.eid && !isLocal) {
    localPlayer.eid = INVALID_ENTITY_ID
    localPlayer.team = TEAM_UNASSIGNED
  }
  else if (isLocal) {
    localPlayer.eid = eid
    localPlayer.team = comp.team
  }
  if (heroEid in heroToPlayerMap)
    delete heroToPlayerMap[heroEid]
  if (heroEid != INVALID_ENTITY_ID)
    heroToPlayerMap[heroEid] <- eid
  updateTeammates()
}

local function player_onDestroy(evt, eid, comp) {
  if (eid == localPlayer.eid) {
    localPlayer.eid = INVALID_ENTITY_ID
    localPlayer.team = TEAM_UNASSIGNED
  }
  local heroEid = comp["possessed"]
  if (heroEid in heroToPlayerMap)
    delete heroToPlayerMap[heroEid]
  updateTeammates()
}


::ecs.register_es("teammate_outline_players_es", {
    onInit = player_onInit
    onDestroy = player_onDestroy
    onChange = player_trackComponents
  },
  {
    comps_track = [
      ["team", ::ecs.TYPE_INT],
      ["is_local", ::ecs.TYPE_BOOL],
      ["possessed", ::ecs.TYPE_EID],
    ],
    comps_rq = ["player"]
  }
)


::ecs.register_es("teammate_outline_outline_es", {
  [["onInit","onChange"]] = @(evt,eid,comp) update_outline(eid, comp)
}, teammate_outline_comps, {tags = "render", track="teammate_outline.color,team"})
 