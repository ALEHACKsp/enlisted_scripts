require("game/es/team.nut")

local {ESO_FOLLOW_ME} = require("ai")
local debug = require("std/log.nut")().with_prefix("[SPAWN]")
local logerr = require("dagor.debug").logerr
local {Point3, Point4, TMatrix} = require("dagor.math")
local weapon_slots = require("globals/weapon_slots.nut")
local math = require("math")
local {calcNewbieArmor, createInventory, gatherParamsFromEntity, mkSpawnParamsByTeam, mkVehicleSpawnParamsByTeam, validatePosition, validateTm} = require("game/utils/spawn.nut")

const spawnZoneExtents = 3.0

local function calcBotCountInVehicleSquad(vehicle, squadLen) {
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  local vehicleTempl = db.getTemplateByName(vehicle)
  if (vehicleTempl == null) {
    debug($"Vehicle '{vehicle}' not found in templates DB")
    return 0
  }
  local seats = vehicleTempl.getCompValNullable("vehicle_seats.seats")
  if (seats == null) {
    debug($"Vehicle '{vehicle}' has no seats")
    return 0
  }
  return ::min(seats.len(), squadLen) - 1
}

local vehicleTransformQuery = ::ecs.SqQuery("vehicleTransformQuery", { comps_ro = [["transform", ::ecs.TYPE_MATRIX]] comps_rq = ["vehicle"] })

local function validateVehiclePosition(tm) {
  local wishPos = tm.getcol(3)

  local vehiclesPos = []
  vehicleTransformQuery.perform(function(eid, comp) { vehiclesPos.append(comp["transform"].getcol(3)) })

  local isWorking = true
  for (local iter = 0; iter < 5 && isWorking; ++iter) {
    isWorking = false
    foreach (pos in vehiclesPos) {
      local dist = wishPos - pos
      dist.y = 0.0
      local len = dist.length()
      if (len == 0.0) {
        len = 1.0
        dist = Point3(1.0, 0.0, 0.0)
      }
      if (len < 5.0) {
        dist = dist * (1.0 / len)
        wishPos = wishPos + dist * 5.0
        isWorking = true
      }
    }
  }
  local resTm = TMatrix(tm)
  resTm.setcol(3, wishPos)
  return validatePosition(resTm, tm.getcol(3), spawnZoneExtents)
}

local makePoint4 = @(v) Point4(v?[0] ?? 0, v?[1] ?? 0, v?[2] ?? 0, v?[3] ?? 1.0)

local excludeCompsFilter = {inventory=1, equipment=1, bodyScale=1}
local excludeVehicleCompsFilter = {disableDMParts=1}

local function wrapComps(inComps, exclude=null) {
  local comps = {}
  foreach (key, value in inComps) {
    if (exclude?[key] != null)
      continue
    if (typeof value == "array")
      comps[key] <- [value, ::ecs.TYPE_ARRAY]
    else if (typeof value == "table")
      comps[key] <- [value, ::ecs.TYPE_OBJECT]
    else
      comps[key] <- value
  }
  return comps
}

local function mkBaseComps(soldier) {
  local comps = {}

  foreach (key, value in soldier)
    if (excludeCompsFilter?[key] == null)
      comps[key] <- value

  local initialEquip = {}
  local initialEquipComponents = {}

  local equipment = soldier?.equipment
  if (equipment != null)
    foreach (slot, equip in equipment) {
      initialEquip[equip.gametemplate] <- slot
      initialEquipComponents[equip.gametemplate] <- { paintColor = makePoint4(equip?.paintColor ?? [1.0, 1.0, 1.0]) }
    }

  comps["human_equipment.initialEquip"] <- initialEquip
  comps["human_equipment.initialEquipComponents"] <- initialEquipComponents

  local bodyHeight = soldier?.bodyScale?.height ?? 1.0
  local bodyWidth = soldier?.bodyScale?.width ?? 1.0

  comps["animchar.scale"]          <- bodyHeight
  comps["animchar.depScale"]       <- Point3(bodyWidth, bodyHeight, bodyWidth)
  comps["animchar.transformScale"] <- Point3(bodyWidth, 1.0, bodyWidth)

  comps["soldier.id"] <- soldier.id

  return comps
}

local function mkHPComps(soldier) {
  local comps = {}

  local db = ::ecs.g_entity_mgr.getTemplateDB()
  local templ = db.getTemplateByName(soldier.gametemplate)
  local maxHpTemplValue = templ.getCompValNullable("hitpoints.maxHp")
  local hpThresholdTemplValue = templ.getCompValNullable("hitpoints.hpThreshold")
  if (maxHpTemplValue != null && hpThresholdTemplValue != null) {
    local baseMaxHpMult = soldier?.baseMaxHpMult ?? 1.0
    local templateModMaxHpMult = templ.getCompValNullable("entity_mods.maxHpMult")
    local modMaxHpMult = soldier?["entity_mods.maxHpMult"] ?? templateModMaxHpMult ?? 1.0
    local maxHp = maxHpTemplValue * baseMaxHpMult * modMaxHpMult
    local hpRegenMult = templ.getCompValNullable("entity_mods.hpToRegen")
    local hpThreshold = hpThresholdTemplValue * (soldier?["entity_mods.hpToRegen"] ?? hpRegenMult ?? 1.0)

    comps["hitpoints.hp"] <- maxHp
    comps["hitpoints.maxHp"] <- maxHp
    comps["hitpoints.hpThreshold"] <- hpThreshold
  }
  else
    logerr($"hitpoints.maxHp or hitpoints.hpThreshold not contained in template {soldier.gametemplate}")

  return comps
}

local isShell = @(weap) weap["reserveAmmoType"].indexof("/shells/") != null

local function mkAmmoMapComps(soldier) {
  local weapInfo = soldier?["human_weap.weapInfo"]
  if (weapInfo == null)
    return {}

  local ammoMap = {}
  foreach (slotId, weap in weapInfo) {
    local ammoTemplate = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(weap["reserveAmmoTemplate"]);
    local allowRequestAmmo = ammoTemplate?.getCompValNullable("allowRequestAmmo") ?? false

    if (slotId != weapon_slots.EWS_GRENADE &&
      slotId != weapon_slots.EWS_MELEE &&
      weap["reserveAmmoType"] &&
      weap["reserveAmmoType"] != "" &&
      (allowRequestAmmo || !isShell(weap))) {
        ammoMap[weap["reserveAmmoType"]] <- { template = weap["reserveAmmoTemplate"] }
    }
  }

  return {ammoProtoToTemplateMap = ammoMap}
}

local mkItemContainer = @(soldier) {itemContainer = createInventory(soldier?.inventory ?? [])[0]}

local gatherPlayerParamsMap = {
  ["battlesPlayed"]        = ["scoring_player.battlesPlayed", ::ecs.TYPE_INT, -1],
  ["revivePointsList"]     = ["squads.revivePointsList", ::ecs.TYPE_ARRAY, []],
  ["squadOrderType"]       = ["persistentSquadOrder.orderType", ::ecs.TYPE_INT, ESO_FOLLOW_ME],
  ["squadOrderPosition"]   = ["persistentSquadOrder.orderPosition", ::ecs.TYPE_POINT3, Point3(0, 0, 0)],
  ["squadOrderEntity"]     = ["persistentSquadOrder.orderUseEntity", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
}

local gatherPlayerParamsQuery = ::ecs.SqQuery("gatherPlayerParamsQuery", {comps_ro = gatherPlayerParamsMap.values()})
local gatherPlayerParams = @(eid) gatherParamsFromEntity(eid, gatherPlayerParamsQuery, gatherPlayerParamsMap)

local spawnSoldier = ::kwarg(function(soldier, comps, squadParams, shouldBePossessed = false, soldierIndexInSquad = 0, useVehicleEid = INVALID_ENTITY_ID) {
  local templateName = soldier?.gametemplate ?? "usa_base_soldier"

  comps.
    __update(mkBaseComps(soldier)).
    __update(mkAmmoMapComps(soldier)).
    __update(mkHPComps(soldier)).
    __update(mkItemContainer(soldier))

  // Use special spawner because we want to create all equipment before soldier createion
  // The helps to reduce inital replication trafic
  ::ecs.g_entity_mgr.createEntity("soldier_spawner_with_equimpent", {
    soldierTemplate     = [templateName, ::ecs.TYPE_STRING]
    soldierComponents   = [comps, ::ecs.TYPE_OBJECT]
    shouldBePossessed   = shouldBePossessed
    playerEid           = ::ecs.EntityId(squadParams.playerEid)
    squadEid            = ::ecs.EntityId(squadParams.squadEid)
    useVechicle         = ::ecs.EntityId(useVehicleEid)
    soldierIndexInSquad = soldierIndexInSquad
  })
})

local function spawnSolidersInSquad(squad, spawnParams, squadParams, vehicleEid = INVALID_ENTITY_ID) {
  local leaderId             = squadParams.leaderId
  local squadEid             = squadParams.squadEid
  local battlesPlayed        = squadParams.battlesPlayed
  local isBot                = squadParams.isBot

  local transform       = spawnParams.transform
  local noSpawnImmunity = spawnParams.noSpawnImmunity

  local spawnTmIsValidated = spawnParams?.isValidated ?? false
  local tm = spawnTmIsValidated ? transform : validateTm(transform, spawnZoneExtents)
  local botCount = squad.len() - 1

  local commonParams = {
    ["squad_member.squad"] = ::ecs.EntityId(squadEid),
    ["entity_mods.defArmor"] = calcNewbieArmor(battlesPlayed),
    ["lastRespawnBaseEid"] = ::ecs.EntityId(spawnParams.baseEid)
  }

  if (noSpawnImmunity)
    commonParams["spawn_immunity.timer"] <- 0.0

  local leaderNo = squad.findindex(@(s) s?.id == leaderId) ?? leaderId

  local leaderParams =
    commonParams.
    __merge(spawnParams).
    __merge({
      ["transform"] = tm,
      ["squad_member.memberIdx"] = leaderNo,
      ["human_net_phys.isSimplifiedPhys"] = isBot,
    })

  spawnSoldier({
    soldier             = squad[leaderNo]
    comps               = leaderParams
    squadParams         = squadParams
    useVehicleEid       = vehicleEid
    shouldBePossessed   = true
    soldierIndexInSquad = 0
  })

  local numRows = math.ceil(math.sqrt(botCount + 1)).tointeger()
  local spawnDist = 1.0
  for (local i = 0; i < botCount; ++i) {
    local memberIdx = i < leaderNo ? i : (i + 1)

    local aiTm = TMatrix(tm)
    local row = ((i + 1) / numRows) * spawnDist
    local col = math.ceil(((i + 1) % numRows) * 0.5) * spawnDist * ((i % 2) * 2 - 1) // alternating -1 +1
    aiTm.setcol(3, aiTm * Point3(-row, 0.0, col));

    local botParams =
      commonParams.
      __merge(spawnParams).
      __merge({
        ["transform"] = validatePosition(aiTm, tm.getcol(3), spawnZoneExtents),
        ["squad_member.memberIdx"] = memberIdx,
        ["beh_tree.enabled"] = true,
        ["human_weap.infiniteAmmoHolders"] = true,
        ["human_net_phys.isSimplifiedPhys"] = true,
      })

    spawnSoldier({
      soldier             = squad[memberIdx]
      comps               = botParams
      squadParams         = squadParams
      useVehicleEid       = vehicleEid
      soldierIndexInSquad = i + 1 /* 0 - is the leader */
    })
  }
}

local function spawnSquadEntity(squad, squadParams, mkSpawnParamsCb, cb) {
  local squadId   = squadParams.squadId
  local memberId  = squadParams.memberId
  local team      = squadParams.team
  local possessed = squadParams.possessed
  local playerEid = squadParams.playerEid

  local spawnParams = mkSpawnParamsCb(team, possessed)

  if (!spawnParams) {
    debug($"No respawn base for player {playerEid}")
    return false
  }

  squadParams.
    __update(gatherPlayerParams(playerEid)).
    __update({
      isBot             = ::ecs.get_comp_val(playerEid, "playerIsBot", null) != null,
      leaderId          = memberId,
      playerEid         = playerEid,
    })

  ::ecs.g_entity_mgr.createEntity("squad", {
    ["squad.id"]             = [squadId, ::ecs.TYPE_INT],
    ["squad.ownerPlayer"]    = [playerEid, ::ecs.TYPE_EID],
    ["squad.orderType"]      = [squadParams.squadOrderType, ::ecs.TYPE_INT],
    ["squad.orderPosition"]  = [squadParams.squadOrderPosition, ::ecs.TYPE_POINT3],
    ["squad.orderUseEntity"] = [squadParams.squadOrderEntity, ::ecs.TYPE_EID],
    ["squad.respawnBaseEid"] = [spawnParams.baseEid, ::ecs.TYPE_EID]
  },
  @(squadEid) cb(squad, spawnParams, squadParams.__update({ squadEid = squadEid })))

  return true
}

local function spawnSquad(squad, team, playerEid, squadId = 0, memberId = 0, possessed = INVALID_ENTITY_ID, mkSpawnParamsCb = mkSpawnParamsByTeam) {
  local squadParams = {team = team, playerEid = playerEid, squadId = squadId, memberId = memberId, possessed = possessed}
  return spawnSquadEntity(squad, squadParams, mkSpawnParamsCb, spawnSolidersInSquad)
}

local function mkVehicleComps(vehicle) {
  local comps = {}
  if (vehicle?.disableDMParts != null) {
    local disabledParts = ::ecs.CompStringList()
    vehicle.disableDMParts.each(@(v) disabledParts.append(v))
    comps["disableDMParts"] <- [disabledParts, ::ecs.TYPE_STRING_LIST]
  }
  return comps
}

local function spawnVehicle(squad, spawnParams, squadParams) {
  local team      = squadParams.team
  local vehicle   = squadParams.vehicle
  local vehicleCompsRaw = squadParams.vehicleComps

  local transform           = spawnParams.transform
  local shouldValidateTm    = spawnParams.shouldValidateTm
  local startVelDir         = spawnParams?.startVelDir
  local startRelativeSpeed  = spawnParams?.startRelativeSpeed
  local addTemplatesOnSpawn = spawnParams?.addTemplatesOnSpawn
  local squadEid            = squadParams.squadEid

  local vehicleComps = wrapComps(vehicleCompsRaw, excludeVehicleCompsFilter).
    __update(mkVehicleComps(vehicleCompsRaw)).
    __update({
      team                                       = team,
      ownedBySquad                               = ::ecs.EntityId(squadEid),
      ["vehicle_seats.restrictToTeam"]           = team,
      ["vehicle_seats.autoDetectRestrictToTeam"] = false,
      transform                                  = shouldValidateTm ? validateVehiclePosition(transform) : transform,
    })

  if (startVelDir != null && startRelativeSpeed != null)
    vehicleComps.__update({
      ["startVelDir"]        = [startVelDir, ::ecs.TYPE_POINT3],
      ["startRelativeSpeed"] = [startRelativeSpeed, ::ecs.TYPE_FLOAT],
    })

  local vehicleTemplate = vehicle
  if (addTemplatesOnSpawn != null) {
    delete spawnParams.addTemplatesOnSpawn
    vehicleTemplate = "{0}+{1}".subst(vehicle, "+".join(addTemplatesOnSpawn))
  }
  ::ecs.g_entity_mgr.createEntity(vehicleTemplate, vehicleComps, @(vehicleEid) spawnSolidersInSquad(squad, spawnParams, squadParams, vehicleEid))
}

local function spawnVehicleSquad(squad, team, playerEid, vehicle, vehicleComps = {}, squadId = 0, memberId = 0, possessed = INVALID_ENTITY_ID, mkSpawnParamsCb = mkVehicleSpawnParamsByTeam) {
  local squadParams = {team = team, playerEid = playerEid, vehicle = vehicle, vehicleComps = vehicleComps, squadId = squadId, memberId = memberId, possessed = possessed}
  return spawnSquadEntity(squad, squadParams, mkSpawnParamsCb, spawnVehicle)
}

return {
  spawnSquad = ::kwarg(spawnSquad)
  spawnVehicleSquad = ::kwarg(spawnVehicleSquad)

  calcBotCountInVehicleSquad = calcBotCountInVehicleSquad

  mkComps = @(soldier) wrapComps(mkBaseComps(soldier), excludeCompsFilter).__update(mkItemContainer(soldier))
}
 