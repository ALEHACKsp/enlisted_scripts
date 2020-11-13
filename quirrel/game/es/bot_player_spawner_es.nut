local {get_setting_by_blk_path} = require("settings")
local { TEAM_UNASSIGNED } = require("team")
local {floor} = require("math")
local {INVALID_CONNECTION_ID, get_sync_time} = require("net")
local Rand = require("std/rand.nut")
local generatedNames = require("gamedata/names/generated_names.nut").names
local pickword = require("std/random_pick.nut")
local system = require("system")
local {INVALID_USER_ID} = require("matching.errors")
local {find_safest_respawn_base_for_team} = require("game/utils/respawn_base.nut")
local {CmdSpawnSquad} = require("respawnevents")
local {EventTeamMemberJoined} = require("teamevents")
local defaultArmies = require_optional("enlisted/game/data/default_client_profile.nut") ?? {}
local assign_team = require("game/utils/team.nut")
local { apply_customization } = require("customization")
local {get_team_eid} = require("globals/common_queries.nut")

local gameBotTemplate = get_setting_by_blk_path("botPlayerTemplateName") ?? "bot_player"

local function onInit(evt, spawn_eid, comp) {
  ::ecs.clear_timer({eid=spawn_eid, id="bot_player_spawner"})
  ::ecs.set_timer({eid=spawn_eid, id="bot_player_spawner", interval=comp.spawnPeriod, repeat=true})
}

local function clearTimer(spawn_eid) {
  ::ecs.clear_timer({eid=spawn_eid, id="bot_player_spawner"})
}

local usedNames = {}

local function genName(seed) {
  local allow_cache = true
  local name
  do {
    name = pickword(generatedNames, seed++, allow_cache)
  } while (name in usedNames)
  usedNames[name] <- true
  return name
}

local availableTeamsQuery = ::ecs.SqQuery("availableTeamsQuery", {comps_ro=[["team.id", ::ecs.TYPE_INT]]})
local onTimerTeamQuery = ::ecs.SqQuery("onTimerTeamQuery", {comps_ro=[["team", ::ecs.TYPE_INT]],comps_rq=["countAsAlive"]})
local playerQuery = ::ecs.SqQuery("playerQuery", {
  comps_ro=[
    ["team", ::ecs.TYPE_INT],
    ["disconnected", ::ecs.TYPE_BOOL],
    ["disconnectedAtTime", ::ecs.TYPE_FLOAT],
    ["possessed", ::ecs.TYPE_EID]
  ],
  comps_rq=["countAsAlive", "player"]
})

local havePlayersQuery = ::ecs.SqQuery("havePlayersQuery", {
  comps_ro=[["possessed", ::ecs.TYPE_EID]],
  comps_rq=["countAsAlive", "player"]
})
local botPlayerQuery = ::ecs.SqQuery("botPlayerQuery", {comps_ro=[["team", ::ecs.TYPE_INT]], comps_rq=["countAsAlive", "player", "playerIsBot"]})

local function setTeam(eid, team) {
  if (::ecs.get_comp_val(eid, "team", null) != null)
    ::ecs.set_comp_val(eid, "team", team)
}

local function onTimer(evt, eid, comp) {
  if (comp.numBotsSpawned < 1) { // if we haven't spawned bots yet
    local havePlayers = havePlayersQuery.perform( function(eid, comp) { if (comp.possessed) return true })
    if (!havePlayers) // check if we have any players, otherwise - do not try to spawn bots
      return
    usedNames = {}
  }

  local currentPopulation = 0
  local teamTable = {}
  local shouldCountTeams = comp.countTeams
  local playersByTeam = {}
  if (shouldCountTeams) {
    onTimerTeamQuery.perform(
        function(eid, comp) {
          if (!(comp.team in teamTable)) {
            teamTable[comp.team] <- 1
            currentPopulation++
          }
        })
  }
  else if (comp.shouldBalanceTeams) {
    availableTeamsQuery.perform(function(eid, comp) {
      playersByTeam[comp["team.id"]] <- { eid = eid, botsCount = 0, totalCount = 0 }
    })
    botPlayerQuery.perform(function(eid, comp) {
      if (playersByTeam?[comp.team] != null)
        playersByTeam[comp.team].botsCount++
    })
    playerQuery.perform(function(eid, comp) {
      if (playersByTeam?[comp.team] != null && (!comp.disconnected || comp.disconnectedAtTime <= 0 || get_sync_time() - comp.disconnectedAtTime <= 60.0))
        playersByTeam[comp.team].totalCount++
    })
  }
  else {
    playerQuery.perform(
        function(eid, comp) {
          currentPopulation++
        })
  }
  if (!comp.createPlayer)
    currentPopulation += comp.numBotsSpawned

  local addPlayerToTeam = TEAM_UNASSIGNED
  if (comp.shouldBalanceTeams) {
    local maxPlayersCountPerTeam = floor(comp.targetPopulation / 2).tointeger()
    local minTeamPlayersCount = -1
    foreach (teamId, team in playersByTeam) {
      if (minTeamPlayersCount < 0 || team.totalCount < minTeamPlayersCount) {
        minTeamPlayersCount = team.totalCount
        addPlayerToTeam = teamId
      }

      local shouldReduceBotsCount = team.totalCount > maxPlayersCountPerTeam && team.botsCount > 0
      ::ecs.set_comp_val(team.eid, "team.shouldReduceBotsCount", shouldReduceBotsCount)
    }

    if (minTeamPlayersCount >= maxPlayersCountPerTeam || addPlayerToTeam == TEAM_UNASSIGNED)
      return;
  }
  else {
    if (currentPopulation >= comp.targetPopulation && comp.numBotsSpawned >= comp.minBotsToSpawn) {
      clearTimer(eid)
      return
    }
  }

  local team = addPlayerToTeam
  if ((comp.searchTeam || comp.assignTeam) && !comp.shouldBalanceTeams)
    team = assign_team()[0]
  local respBase = find_safest_respawn_base_for_team(team)
  if (respBase == INVALID_ENTITY_ID){
    // skip a bit, we probably will have new bases appearing soon
    return
  }
  local transform = ::ecs.get_comp_val(respBase, "transform")
  local comps = {
    "transform" : [transform, ::ecs.TYPE_MATRIX]
  }
  if (comp.assignTeam) {
    comps["team"] <- [team, ::ecs.TYPE_INT]
    setTeam(respBase, team)
  }
  else
    setTeam(respBase, comp.forceTeamForRespBase)
  local itemslist = []
  local time = system.date()
  local rand = Rand(time.min * 60 + time.sec)

  foreach (slot in comp.applyMeta) {
    if (rand.rfloat() < comp.metaChance)
      itemslist.append(slot[rand.rint(0, slot.len() - 1)])
  }
  local modComps = comps
  if (itemslist.len() > 0)
    modComps = apply_customization(comp.templateToSpawn, itemslist, comps)
  local createPlayer = comp.createPlayer
  local assignTeam = comp.assignTeam
  if (comp.createSquad && createPlayer) {
    local teamEid = get_team_eid(team)
    local teamArmy = ::ecs.get_comp_val(teamEid, "team.army")
    local army = defaultArmies[teamArmy]
    local squadsCount = army.squads.len()

    // create player
    local playerComps = {
      "connid" : [INVALID_CONNECTION_ID, ::ecs.TYPE_INT],
      "canBeLocal" : [false, ::ecs.TYPE_BOOL],
      "scoring_player.killRating" : [rand.rfloat(900.0, 1900.0), ::ecs.TYPE_FLOAT],
      "scoring_player.winRating" : [rand.rfloat(900.0, 1900.0), ::ecs.TYPE_FLOAT],
      "userid" : [INVALID_USER_ID, ::ecs.TYPE_INT64],
      "isFirstSpawn" : [false, ::ecs.TYPE_BOOL],
      "player.metaItems" : [itemslist, ::ecs.TYPE_ARRAY],
      "armies" : defaultArmies,
      "armiesReceivedTime" : get_sync_time(),
      "squads.revivePointsList" : [array(squadsCount, 100), ::ecs.TYPE_ARRAY],
      "shouldValidateSpawnRules" : [false, ::ecs.TYPE_BOOL],
      "vehicleRespawnsBySquad" : [array(squadsCount).map(@(_, i) {
        lastSpawnOnVehicleAtTime = 0.0
        nextSpawnOnVehicleInTime = 0.0
      }), ::ecs.TYPE_ARRAY]
    }
    if (assignTeam) {
      playerComps["team"] <- [team, ::ecs.TYPE_INT]
      playerComps["armiesReceivedTeam"] <- [team, ::ecs.TYPE_INT]
    }
    local template = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(gameBotTemplate)
    ::ecs.g_entity_mgr.createEntity(template ? gameBotTemplate : "bot_player", playerComps,
        function(plr_eid) {
          ::ecs.set_comp_val(plr_eid, "name", genName(plr_eid + time.sec + time.min * 60))
          ::ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined(plr_eid, team));
          ::ecs.g_entity_mgr.sendEvent(plr_eid, CmdSpawnSquad(team, INVALID_ENTITY_ID, 0, 0, -1))
        })
  }
  else {
    ::ecs.g_entity_mgr.createEntity(comp.templateToSpawn, modComps,
        function(ent_eid) {
          if (!createPlayer)
            return
          local playerComps = {
            "possessed" : [ent_eid, ::ecs.TYPE_EID],
            "connid" : [INVALID_CONNECTION_ID, ::ecs.TYPE_INT],
            "name" : [genName(ent_eid + time.sec + time.min * 60), ::ecs.TYPE_STRING],
            "canBeLocal" : [false, ::ecs.TYPE_BOOL],
            "scoring_player.killRating" : [rand.rfloat(900.0, 1900.0), ::ecs.TYPE_FLOAT],
            "scoring_player.winRating" : [rand.rfloat(900.0, 1900.0), ::ecs.TYPE_FLOAT],
            "userid" : [INVALID_USER_ID, ::ecs.TYPE_INT64],
            "player.metaItems" : [itemslist, ::ecs.TYPE_ARRAY]
          }
          if (assignTeam)
            playerComps["team"] <- [team, ::ecs.TYPE_INT]
          ::ecs.g_entity_mgr.createEntity(gameBotTemplate, playerComps,
            function(plr_eid) {
              ::ecs.set_comp_val(ent_eid, "possessedByPlr", plr_eid)
            })
        })
  }
  comp.numBotsSpawned++
}

::ecs.register_es(
  "bot_player_spawner_es",
  {
    onInit = onInit,
    Timer = onTimer
  },
  {
    comps_rw = [["numBotsSpawned", ::ecs.TYPE_INT]],
    comps_ro = [
      ["targetPopulation", ::ecs.TYPE_INT],
      ["minBotsToSpawn", ::ecs.TYPE_INT],
      ["templateToSpawn", ::ecs.TYPE_STRING],
      ["spawnPeriod", ::ecs.TYPE_FLOAT],
      ["forceTeamForRespBase", ::ecs.TYPE_INT],
      ["assignTeam", ::ecs.TYPE_BOOL],
      ["createPlayer", ::ecs.TYPE_BOOL],
      ["applyMeta", ::ecs.TYPE_ARRAY],
      ["metaChance", ::ecs.TYPE_FLOAT],
      ["createSquad", ::ecs.TYPE_BOOL, false],
      ["searchTeam", ::ecs.TYPE_BOOL, false],
      ["countTeams", ::ecs.TYPE_BOOL, true],
      ["shouldBalanceTeams", ::ecs.TYPE_BOOL, false],
    ]
  },
  {tags="server"}
)
 