require("game/es/team.nut")

local { TEAM_UNASSIGNED } = require("team")
local debug = require("std/log.nut")().with_prefix("[SPAWN]")
local {logerr} = require("dagor.debug")
local {FLT_MAX} = require("math")
local {Point3, Point4, TMatrix, cvt} = require("dagor.math")
local dagorRandom = require("dagor.random")
local {traceray_normalized, rayhit_normalized} = require("dacoll.trace")
local {traceray_navmesh, project_to_nearest_navmesh_point} = require("pathfinder")
local {CmdPossessEntity} = require("respawnevents")
local {EventPlayerRebalanced} = require("gameevents")
local {EventTeamMemberLeave, EventTeamMemberJoined} = require("teamevents")
local {get_team_eid} = require("globals/common_queries.nut")
local {find_human_respawn_base, find_vehicle_respawn_base} = require("game/utils/respawn_base.nut")
local {get_sync_time} = require("net")
local { apply_customization } = require("customization")

local teamMembersQuery = ::ecs.SqQuery("teamMembersQuery", {comps_ro=[["team.memberCount", ::ecs.TYPE_FLOAT], ["team.id", ::ecs.TYPE_INT]]})

local function rebalance(teamId, playerEid) {
  local teamEid = get_team_eid(teamId) ?? INVALID_ENTITY_ID
  if (!::ecs.get_comp_val(teamEid, "team.allowRebalance", true))
    return teamId

  local minTeam = TEAM_UNASSIGNED
  local myTeamPlayers = ::ecs.get_comp_val(teamEid, "team.memberCount", 0.0)
  local minTeamPlayers = FLT_MAX

  teamMembersQuery.perform(function(eid, comp) {
    if (comp["team.id"] != teamId && comp["team.memberCount"] < minTeamPlayers) {
      minTeamPlayers = comp["team.memberCount"]
      minTeam = comp["team.id"]
    }
  })

  debug($"myTeamPlayers {myTeamPlayers} > minTeamPlayers {minTeamPlayers}")

  if (myTeamPlayers > minTeamPlayers + 1.0) {
    debug($"switching to {minTeam} team")
    local prevTeam = teamId;
    teamId = minTeam;
    ::ecs.g_entity_mgr.broadcastEvent(EventTeamMemberLeave(playerEid, prevTeam))
    ::ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined(playerEid, teamId))
    ::ecs.set_comp_val(playerEid, "team", teamId)
    ::ecs.g_entity_mgr.sendEvent(playerEid, EventPlayerRebalanced(prevTeam, teamId))
  }

  return teamId
}

local function calcNewbieArmor(battlesPlayed) {
  local minBattlesToArmor = 2
  local maxBattlesToArmor = 5
  local maxArmor = 0.12

  return battlesPlayed >= 0 ? cvt(battlesPlayed, minBattlesToArmor, maxBattlesToArmor, maxArmor, 0.0) : 0.0
}

local function traceBinarySearch(pos, max_ht, err_term) {
  local hitT = traceray_normalized(Point3(pos.x, (max_ht + pos.y) * 0.5, pos.z), Point3(0.0, -1.0, 0.0), max_ht - pos.y)
  if (hitT >= 0.0) {
    local resHt = (max_ht + pos.y) * 0.5 - hitT
    if (resHt - pos.y < err_term)
      return Point3(pos.x, resHt, pos.z)
    return traceBinarySearch(pos, resHt, err_term)
  }
  return Point3(pos.x, max_ht, pos.z)
}

local function traceSearch(pos, top_offs) {
  local t = top_offs
  if (!rayhit_normalized(pos, Point3(0.0, -1.0, 0.0), t)) {
    local hitT = traceray_normalized(pos + Point3(0.0, top_offs, 0.0), Point3(0.0, -1.0, 0.0), top_offs)
    if (hitT >= 0.0) {
      local maxHt = pos.y + top_offs - hitT
      return traceBinarySearch(pos, maxHt, 0.4)
    }
  }
  return pos
}

local function validatePosition(tm, orig_pos, horz_extents = 0.75) {
  local wishPos = tm.getcol(3)
  local rayPos = traceray_navmesh(orig_pos, wishPos, 0.25)
  wishPos = traceSearch(rayPos, 1000.0)
  local resPos = project_to_nearest_navmesh_point(wishPos, horz_extents)
  local resTm = TMatrix(tm)
  resTm.orthonormalize()
  resTm.setcol(3, resPos)
  return resTm;
}

local validateTm = @(tm, horz_extents = 0.75) validatePosition(tm, tm.getcol(3), horz_extents)

local function selectRandomTemplate(templates) {
  local totalWt = 0.0
  local templateList = []
  foreach (key, wt in templates) {
    totalWt += wt
    templateList.append({ key = key, wt = totalWt })
  }
  if (templateList.len()) {
    local curWt = dagorRandom.gfrnd() * totalWt;
    foreach (templ in templateList)
      if (curWt <= templ.wt)
        return templ.key;
  }
  return null
}

local function getTeamWeaponPresetTemplateName(team) {
  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  local templates = ::ecs.get_comp_val(teamEid, "team.weaponTemplates")
  local templ = templates ? selectRandomTemplate(templates) : null
  if (templ)
    return templ
  return ::ecs.get_comp_val(teamEid, "team.weaponTemplate")
}

local function getTeamUnitTemplateName(team, playerEid) {
  local playerPossessedTemplate = ::ecs.get_comp_val(playerEid, "possessedTemplate", "")
  if (playerPossessedTemplate.len() > 0)
    return playerPossessedTemplate
  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  local templates = ::ecs.get_comp_val(teamEid, "team.unitTemplates")
  local templ = templates ? selectRandomTemplate(templates) : null
  if (templ)
    return templ
  return ::ecs.get_comp_val(teamEid, "team.unitTemplate")
}

local function createInventory(inventory) {
  local itemContainer = ::ecs.CompEidList()
  foreach (item in inventory)
    itemContainer.append(::ecs.EntityId(::ecs.g_entity_mgr.createEntity(item.gametemplate, {})))
  return [ itemContainer, ::ecs.TYPE_EID_LIST ]
}

local makePoint4 = @(v) Point4(v?[0] ?? 0, v?[1] ?? 0, v?[2] ?? 0, v?[3] ?? 1.0)

local function createEquipment(attrs, equipment) {
  local initialEquip = {}
  local initialEquipComponents = {}

  if (equipment != null)
    foreach (slot, equip in equipment) {
      initialEquip[equip.gametemplate] <- slot
      initialEquipComponents[equip.gametemplate] <- {
        paintColor = makePoint4(equip?.paintColor ?? [1.0, 1.0, 1.0])
      }
    }

  attrs["human_equipment.initialEquip"] <- [ initialEquip, ::ecs.TYPE_OBJECT ]
  attrs["human_equipment.initialEquipComponents"] <- [ initialEquipComponents, ::ecs.TYPE_OBJECT ]
}

local function initItemContainer(eid) {
  local itemContainer = ::ecs.get_comp_val(eid, "itemContainer")?.getAll() ?? []
  foreach (itemEid in itemContainer)
    if (::ecs.g_entity_mgr.doesEntityExist(itemEid))
      ::ecs.set_comp_val(itemEid, "item.lastOwner", ::ecs.EntityId(eid))
}

local playersByTeamQuery = ::ecs.SqQuery("teamPlayersQuery", {comps_ro = [["possessed", ::ecs.TYPE_EID], ["team", ::ecs.TYPE_INT]], comps_rq = ["player"]})

local function getPlayerPositionsByTeam(team) {
  local positions = [[],[]]
  playersByTeamQuery.perform(function(eid, comp) {
    if (!::ecs.g_entity_mgr.doesEntityExist(comp.possessed))
      return
    local tm = ::ecs.get_comp_val(comp.possessed, "transform")
    local isAlive = ::ecs.get_comp_val(comp.possessed, "isAlive", false)
    positions[isAlive ? 0 : 1].append(tm.getcol(3))
  }, $"eq(team,{team})")
  return positions
}

local function calcBestSpawnTmForTeam(team, offset, wishTm) {
  local positions = getPlayerPositionsByTeam(team)
  foreach (p in positions)
    if (p.len() > 0) {
      local bestTm = TMatrix(wishTm)
      bestTm.setcol(3, p[dagorRandom.grnd() % p.len()] + offset)
      return bestTm
    }
  return wishTm
}

local gatherSpawnParamsMap = {
  ["transform"]                 = ["transform", ::ecs.TYPE_MATRIX],
  ["start_vel"]                 = ["respbase.start_vel", ::ecs.TYPE_POINT3, null],
  ["human_spawn_sound.inSpawn"] = ["respbase.start_sound", ::ecs.TYPE_BOOL, false],
  ["noSpawnImmunity"]           = ["respbase.noSpawnImmunity", ::ecs.TYPE_BOOL, false],
  ["shouldValidateTm"]          = ["respbase.shouldValidateTm", ::ecs.TYPE_BOOL, true],
  ["startVelDir"]               = ["respbase.startVelDir", ::ecs.TYPE_POINT3, null],
  ["startRelativeSpeed"]        = ["respbase.startRelativeSpeed", ::ecs.TYPE_FLOAT, null],
  ["addTemplatesOnSpawn"]       = ["respbase.addTemplatesOnSpawn", ::ecs.TYPE_STRING_LIST, null],
  ["isValidated"]               = ["respbase.validated", ::ecs.TYPE_BOOL, false],
}

local gatherHelperParamsMap = {
  ["isTeamSpawn"]               = ["respbase.team_spawn", ::ecs.TYPE_BOOL, false],
  ["isCorpseSpawn"]             = ["respbase.corpse_spawn", ::ecs.TYPE_BOOL, false],
  ["teamOffset"]                = ["respbase.team_offset", ::ecs.TYPE_POINT3, Point3(0.0, 0.0, 0.0)],
}

local gatherSpawnParamsQuery = ::ecs.SqQuery("gatherSpawnParamsQuery", {comps_ro = gatherSpawnParamsMap.values()})
local gatherHelperParamsQuery = ::ecs.SqQuery("gatherHelperParamsQuery", {comps_ro = gatherHelperParamsMap.values()})

local function gatherParamsFromEntity(eid, query, map) {
  local params = {}
  query.perform(eid, function(eid, comp) {
    foreach (paramName, compName in map) {
      local compValue = comp[compName[0]]
      if (compValue != null)
        params[paramName] <- compValue?.getAll != null ? compValue.getAll() : compValue
    }
  })
  return params
}

local gatherSpawnParams = @(eid) gatherParamsFromEntity(eid, gatherSpawnParamsQuery, gatherSpawnParamsMap)
local gatherHelperParams = @(eid) gatherParamsFromEntity(eid, gatherHelperParamsQuery, gatherHelperParamsMap)

local function mkSpawnParamsByTeamImpl(team, possesed, findBaseCb) {
  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  local searchForSafest = ::ecs.get_comp_val(teamEid, "team.findSafestSpawn", false)

  local baseEid = findBaseCb(team, searchForSafest)
  if (baseEid == INVALID_ENTITY_ID)
    return null

  local params = {
    baseEid = baseEid
    team = team
  }

  params.__update(::ecs.get_comp_val(teamEid, "team.overrideUnitParam").getAll() ?? {})
  params.__update(gatherSpawnParams(baseEid))

  local helperParams = gatherHelperParams(baseEid)

  if (helperParams.isTeamSpawn)
    params.transform = calcBestSpawnTmForTeam(team, helperParams.teamOffset, params.transform)

  if (helperParams.isCorpseSpawn && ::ecs.g_entity_mgr.doesEntityExist(possesed)) {
    params.transform = ::ecs.get_comp_val(possesed, "transform", params.transform)
    params["hidden"] <- true
    params["in_spawn"] <- true
    params["human.visible"] <- false
    params["gridcoll.enabled"] <- false
    params["actions.enabled"] <- false
  }

  if (!params.isValidated)
    params.transform = validateTm(params.transform)

  return params
}

local mkSpawnParamsByTeam = @(team, possesed)
  mkSpawnParamsByTeamImpl(team, possesed, find_human_respawn_base)

local function markRespawnBase(team, baseEid) {
  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  if (!::ecs.get_comp_val(teamEid, "team.markRespawnBase", false) || baseEid == INVALID_ENTITY_ID)
    return
  ::ecs.set_comp_val(baseEid, "team", team)
  ::ecs.set_comp_val(baseEid, "lastSpawnOnTime", get_sync_time())
}

local playerQuery = ::ecs.SqQuery("playerQuery", {comps_ro = [["scoring_player.battlesPlayed", ::ecs.TYPE_INT, -1], ["player.metaItems", ::ecs.TYPE_ARRAY]]})

local function spawnSoldier(team, playerEid, possessed = INVALID_ENTITY_ID, spawnParams = null) {
  debug("spawnSoldier")

  local params = spawnParams ?? mkSpawnParamsByTeam(team, possessed)
  if (!params) {
    logerr($"spawnSoldier: no respawn base for team {team} with possessed {possessed}")
    return
  }

  local baseEid = params?.baseEid ?? INVALID_ENTITY_ID

  local templateName = getTeamUnitTemplateName(team, playerEid)
  local weaponTempl = getTeamWeaponPresetTemplateName(team)
  if (weaponTempl)
    templateName = $"{templateName}+{weaponTempl}"

  markRespawnBase(team, baseEid)

  local metaItems = []
  local battlesPlayed = 0
  playerQuery.perform(playerEid, function(eid, comp) {
    metaItems = comp["player.metaItems"].getAll()
    battlesPlayed = comp["scoring_player.battlesPlayed"]
  })

  debug($"spawnSoldier: create single soldier squad for team {team}")

  local initialParams = {
    ["squad_member.memberIdx"] = 0,
    ["entity_mods.defArmor"] = calcNewbieArmor(battlesPlayed),
    ["human_net_phys.isSimplifiedPhys"] = ::ecs.get_comp_val(playerEid, "playerIsBot", null) != null
  }

  local finalParams = apply_customization(templateName, metaItems, initialParams.__merge(params), playerEid)
  ::ecs.g_entity_mgr.createEntity(templateName, finalParams, function (soldierEid) {
    ::ecs.g_entity_mgr.sendEvent(playerEid, CmdPossessEntity(soldierEid))
    initItemContainer(soldierEid)
  })
}

return {
  spawnSoldier = ::kwarg(spawnSoldier)
  validatePosition = validatePosition
  validateTm = validateTm
  mkSpawnParamsByTeam = mkSpawnParamsByTeam
  mkVehicleSpawnParamsByTeam = @(team, possesed) mkSpawnParamsByTeamImpl(team, possesed, find_vehicle_respawn_base)
  mkSpawnParamsByTeamEx = mkSpawnParamsByTeamImpl
  getTeamWeaponPresetTemplateName = getTeamWeaponPresetTemplateName
  getTeamUnitTemplateName = getTeamUnitTemplateName
  createInventory = createInventory
  createEquipment = createEquipment
  initItemContainer = initItemContainer
  rebalance = rebalance
  calcNewbieArmor = calcNewbieArmor
  gatherParamsFromEntity = gatherParamsFromEntity
}
 