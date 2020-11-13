local {TEAM_UNASSIGNED} = require("team")
local {ceil} = require("math")
local {logerr} = require("dagor.debug")
local {find_player_by_connid, find_local_player, get_team_eid} = require("globals/common_queries.nut")
local {weaponSlotsKeys} = require("globals/weapon_slots.nut")
local {INVALID_CONNECTION_ID, has_network, get_sync_time} = require("net")
local {CmdSpawnSquad} = require("respawnevents")
local debug = require("std/log.nut")().with_prefix("[CLIENT PROFILE]")
local defaultArmies = require("enlisted/game/data/default_client_profile.nut")
local kick_player = require_optional("dedicated")?.kick_player ?? @(...) null
local {INVALID_USER_ID} = require("matching.errors")
local {profilePublicKey} = require("enlisted/game/data/profile_pubkey.nut")
local decode_jwt = require("jwt").decode

local function validateArmies(armies, teamArmy) {
  if (!armies) {
    debug("validateArmies: armies is absent")
    return false
  }

  if (armies.len() == 0) {
    debug("validateArmies: armies is empty")
    return false
  }

  if (teamArmy == null) {
    debug("validateArmies: team.army is absent")
    return false
  }

  local army = armies?[teamArmy] ?? {}
  if (army.len() == 0) {
    local availableArmies = ", ".join(armies.keys())
    debug($"validateArmies: army is absent in army {teamArmy}. Available armies: {availableArmies}")
    return false
  }

  local squads = army?.squads ?? []
  if (squads.len() == 0) {
    debug($"validateArmies: squads is absent in army {teamArmy}")
    return false
  }

  foreach (idx, squad in squads) {
    if (squad?.squad == null) {
      debug($"validateArmies: squad is absent in {idx}")
      return false
    }
  }

  return true
}

local mkCalcAdd = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) + value
local mkCalcAddInt = @(key)
  @(comp, value, template) comp[key] <- ((comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) + value).tointeger()
local mkCalcMult = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) * value
local mkCalcSubstract = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) - value
local mkCalcSet = @(key)
  @(comp, value, template) comp[key] <- value
local mkCalcInsert = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key)?.getAll() ?? [])).append(value)
local mkCalcSetTrue = @(key)
  @(comp, value, template) comp[key] <- true

local perksFactory = {
  run_speed                                   = mkCalcAdd("entity_mods.speedMult")
  sprint_speed                                = mkCalcAdd("entity_mods.sprintSpeedMult")
  jump_height                                 = mkCalcAdd("entity_mods.jumpMult")
  faster_reload                               = mkCalcSubstract("entity_mods.reloadMult")
  faster_bolt_action                          = mkCalcSubstract("entity_mods.boltActionMult")
  stamina_boost                               = mkCalcAdd("entity_mods.staminaBoostMult")
  stamina_regeneration                        = mkCalcAdd("entity_mods.restoreStaminaMult")
  heal_effectivity                            = mkCalcAdd("entity_mods.healAmountMult")
  faster_change_weapon                        = mkCalcAdd("entity_mods.fasterChangeWeaponMult")
  less_fall_dmg                               = mkCalcSubstract("entity_mods.lessFallDmgMult")
  less_aim_moving                             = mkCalcSubstract("entity_mods.breathAimMult")
  less_maximum_shot_spread_after_turn         = mkCalcSubstract("entity_mods.shotDeviationMult")
  weight_run                                  = mkCalcSubstract("entity_mods.weightRunSpeedMult")
  climb_speed                                 = mkCalcAdd("entity_mods.climbingSpeedMult")
  less_recoil                                 = mkCalcSubstract("entity_mods.verticalRecoilOffsMult")
  more_predictable_recoil                     = mkCalcSubstract("entity_mods.horizontalRecoilOffsMult")
  longer_hold_breath_cd                       = mkCalcAdd("entity_mods.longerHoldBreathMult")
  less_hold_breath_cd                         = mkCalcAdd("entity_mods.oftenHoldBreathMult")
  faster_change_pose_speed                    = mkCalcAdd("entity_mods.fasterChangePoseMult")
  crawl_crouch_speed                          = mkCalcAdd("entity_mods.crawlCrouchSpeedMult")
  faster_decreasing_of_maximum_shot_spread    = mkCalcSubstract("entity_mods.rotationShotSpreadDecrMult")
  hp_boost                                    = mkCalcAdd("entity_mods.maxHpMult")
  base_hp_mult                                = mkCalcMult("baseMaxHpMult")
  hp_regeneration                             = mkCalcAdd("entity_mods.hpToRegen")
  more_stability_when_hit                     = mkCalcAdd("entity_mods.moreStabilityWhenHitMult")
  less_stopping_power                         = mkCalcAdd("entity_mods.lessStoppingPower")
  faster_aiming_point_return_after_fire       = mkCalcSubstract("entity_mods.aimingAfterFireMult")
  weapon_turning_speed                        = mkCalcAdd("entity_mods.weaponTurningSpeedMult")
  seat_change_speed                           = mkCalcSubstract("entity_mods.vehicleChangeSeatTimeMult")
  extinguish_time                             = mkCalcSubstract("entity_mods.vehicleExtinguishTimeMult")
  repair_speed                                = mkCalcSubstract("entity_mods.vehicleRepairTimeMult")
  repair_quality                              = mkCalcAdd("entity_mods.vehicleRepairRecoveryRatioAdd")
  repairkit_economy_usage                     = mkCalcAddInt("entity_mods.vehicleRepairUsagesPerKit")
  faster_reload_tankgun                       = mkCalcSubstract("entity_mods.vehicleReloadMult")
  reload_reaction                             = mkCalcSetTrue("entity_mods.canChangeShellDuringVehicleGunReload")
  melee_damage                                = mkCalcAdd("entity_mods.meleeDamageMult")
  more_ammo                                   = null,       // direct apply to squadData
  large_inventory                             = null, // direct apply to squadData
}

local vehicleModFactory = {
  turret_hor_speed                            = mkCalcSet("vehicle_mods.maxHorDriveMult")
  turret_ver_speed                            = mkCalcSet("vehicle_mods.maxVerDriveMult")
  extra_mass                                  = mkCalcSet("vehicle_mods.extraMass")
  engine_power                                = mkCalcSet("vehicle_mods.maxMomentMult")
  braking_force                               = mkCalcSet("vehicle_mods.maxBrakeForceMult")
  suspension_dampening                        = mkCalcSet("vehicle_mods.suspensionDampeningMult")
  suspension_resting                          = mkCalcSet("vehicle_mods.suspensionRestingMult")
  suspension_min_limit                        = mkCalcSet("vehicle_mods.suspensionMinLimitMult")
  suspension_max_limit                        = mkCalcSet("vehicle_mods.suspensionMaxLimitMult")
  track_friction_frontal_static               = mkCalcSet("vehicle_mods.trackFrontalStaticFrictionMult")
  track_friction_frontal_sliding              = mkCalcSet("vehicle_mods.trackFrontalSlidingFrictionMult")
  track_friction_side_linear                  = mkCalcSet("vehicle_mods.trackFricSideLinMult")
  track_friction_side_rot_min_speed           = mkCalcSet("vehicle_mods.trackSideRotMinSpdMult")
  track_friction_side_rot_max_speed           = mkCalcSet("vehicle_mods.trackSideRotMaxSpdMult")
  track_friction_side_rot_min_friction        = mkCalcSet("vehicle_mods.trackSideRotMinFricMult")
  track_friction_side_rot_max_friction        = mkCalcSet("vehicle_mods.trackSideRotMaxFricMult")
  disable_dm_part                             = mkCalcInsert("disableDMParts")
}

local function applyPerks(armies) {
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  foreach (army in armies) {
    foreach (squad in army?.squads ?? []) {
      foreach (soldier in squad?.squad ?? []) {
        local templ = db.getTemplateByName(soldier.gametemplate)
        local soldierPerks = soldier?.perks ?? []
        foreach (perk in soldierPerks) {
          if (perk.statKey in perksFactory) {
            if (perksFactory[perk.statKey] != null)
              perksFactory[perk.statKey](soldier, perk.statValue, templ)
          }
          else
            log("Unknown perk stat:" perk.statKey)
        }

        if (soldier?.perks != null)
          delete soldier.perks
      }
    }
  }
}

local function convertGunMods(armies) {
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  foreach (army in armies) {
    foreach (squad in army?.squads ?? []) {
      foreach (soldier in squad?.squad ?? []) {
        foreach (weapon in soldier["human_weap.weapInfo"]){
          local gunSlots = weapon?.gunSlots
          if (gunSlots == null)
            continue

          weapon.gunMods <- {}
          foreach (slotid, slotTemplateId in gunSlots) {
            local slotTemplate = db.getTemplateByName(slotTemplateId)
            if (!slotTemplate)
              continue
            weapon.gunMods[slotid] <- slotTemplate.getCompVal("gunAttachable.slotTag")
          }

          delete weapon.gunSlots
        }
      }
    }
  }
}

local function applyUpgradesToComponents(gunTemplate, upgrades) {
  if (gunTemplate == null || gunTemplate == "")
    return {}
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  local templ = db.getTemplateByName(gunTemplate)
  if (templ == null) {
    logerr($"Cannot apply upgrades to a gun. Gun's template '{gunTemplate}' not found.")
    return {}
  }
  local result = {}
  foreach (compName, compMod in upgrades) {
    local baseValue = templ.getCompVal(compName)?.tofloat() ?? 0.0
    result[compName] <- baseValue * (1.0 + compMod * 0.01)
  }
  return result
}

local function applyGunUpgrades(armies) {
  foreach (army in armies) {
    foreach (squad in army?.squads ?? []) {
      foreach (soldier in squad?.squad ?? []) {
        local weapTemplates = soldier["human_weap.weapTemplates"]
        foreach (slotNo, upgrades in (soldier?["human_weap.weapInitialComponents"] ?? [])) {
          local gunComps = applyUpgradesToComponents(weapTemplates?[weaponSlotsKeys?[slotNo]], upgrades)
          soldier["human_weap.weapInitialComponents"][slotNo].__update(gunComps)
        }
      }
    }
  }
}

local function applyModsToVehicleComponents(comps, vehicleTemplate, vehicleMods) {
  foreach (mod in vehicleMods) {
    if (mod.statKey in vehicleModFactory) {
      if (vehicleModFactory[mod.statKey] != null)
        vehicleModFactory[mod.statKey](comps, mod.statValue, vehicleTemplate)
    }
    else
      log("Unknown vehicle mod stat:" mod.statKey)
  }
}

local function applyTurretModsToVehicleComponents(comps, vehicleTemplateName, vehicleTemplate, vehicleTurretMods) {
  local turretInfo = vehicleTemplate?.getCompValNullable("turret_control.turretInfo") ?? []
  local defaultInitComps = vehicleTemplate?.getCompValNullable("turretsInitialComponents")?.getAll() ?? []
  local turretsInitialComponents = array(turretInfo.len()).map(@(_,i) comps?.turretsInitialComponents?[i] ?? defaultInitComps?[i] ?? {})

  local turretNameIndexMap = {}
  foreach (turretInd, turret in turretInfo) {
    local turretName = turret?.turretName ?? ""
    if (turretName != "")
      turretNameIndexMap[turretName] <- turretInd
  }

  foreach (name, turretMods in vehicleTurretMods) {
    local turretInd = turretNameIndexMap?[name] ?? -1
    if (turretInd < 0){
      logerr($"Cannot apply upgrades to a turret. Turret with name '{name}' not found in vehicle '{vehicleTemplateName}'.")
      continue
    }
    local turretTemplate = turretInfo[turretInd]?.gun?.split("+")?[0]
    local turretComps = applyUpgradesToComponents(turretTemplate, turretMods)
    turretsInitialComponents[turretInd].__update(turretComps)
  }
  comps["turretsInitialComponents"] <- turretsInitialComponents
}

local function applyVehicleMods(armies) {
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  foreach (army in armies) {
    foreach (squad in army?.squads ?? []) {
      local vehicle = squad?.curVehicle
      if (vehicle == null)
        continue
      if (vehicle?.comps == null)
        vehicle.comps <- {}
      local vehicleTemplate = db.getTemplateByName(vehicle.gametemplate)
      if (vehicle?.mods != null) {
        applyModsToVehicleComponents(vehicle.comps, vehicleTemplate, vehicle.mods)
        delete vehicle.mods
      }
      if (vehicle?.turretMods != null) {
        applyTurretModsToVehicleComponents(vehicle.comps, vehicle.gametemplate, vehicleTemplate, vehicle.turretMods)
        delete vehicle.turretMods
      }
    }
  }
}

local getRespawnsToFullRestore = @(respawnsToFullRestoreByCount, count)
  respawnsToFullRestoreByCount?[count.tostring()] ?? respawnsToFullRestoreByCount?["default"] ?? 1

local getRevivePointsAfterDeath = @(respawnsToFullRestore) respawnsToFullRestore == 0 ? 100 : 0

local function getRevivePointsHeal(respawnsToFullRestore) {
  local respawnsF = respawnsToFullRestore.tofloat()
  return respawnsF > 0 ? ceil(100.0 / respawnsF).tointeger() : 100
}

local function getSoldierReviveData(army, respawnsToFullRestoreByCount) {
  local squadsCount = army?.squads.len() ?? 0

  local revivePoints = array(squadsCount)
  local healPerSquadmate = array(squadsCount)
  local afterDeath = array(squadsCount)

  for (local i = 0; i < squadsCount; ++i) {
    local squad = army?.squads?[i]
    local vehicleSquad = squad?.curVehicle != null
    local soldiersInSquad = squad?.squad?.len() ?? 0
    revivePoints[i] = array(soldiersInSquad, 100)
    local respawnsToRestoreSoldier = getRespawnsToFullRestore(respawnsToFullRestoreByCount, soldiersInSquad)
    healPerSquadmate[i] = getRevivePointsHeal(respawnsToRestoreSoldier)
    afterDeath[i] = vehicleSquad ? 100 : getRevivePointsAfterDeath(respawnsToRestoreSoldier)
  }

  return {
    ["soldier_revive_points.points"] = revivePoints,
    ["soldier_revive_points.healPerSquadmate"] = healPerSquadmate,
    ["soldier_revive_points.afterDeath"] = afterDeath,
  }
}

local function onRevivePointsInit(evt, eid, comp) {
  local teamEid = comp.team != TEAM_UNASSIGNED ? get_team_eid(comp.team) : INVALID_ENTITY_ID
  local teamArmy = ::ecs.get_comp_val(teamEid, "team.army")
  local army = comp?.armies?[teamArmy] ?? {}
  comp.__update(getSoldierReviveData(army, comp["soldier_revive_points.respawnsToRestoreByCount"]))
}

local soldierReviveComps = {
  comps_rw = [
    ["soldier_revive_points.points", ::ecs.TYPE_ARRAY],
    ["soldier_revive_points.healPerSquadmate", ::ecs.TYPE_ARRAY],
    ["soldier_revive_points.afterDeath", ::ecs.TYPE_ARRAY],
  ]
  comps_ro =[
    ["team", ::ecs.TYPE_INT],
    ["armies", ::ecs.TYPE_OBJECT],
    ["soldier_revive_points.respawnsToRestoreByCount", ::ecs.TYPE_OBJECT]
  ]
}

local soldierRespawnPointsQuery = ::ecs.SqQuery("setItemsContainerQuery", soldierReviveComps)

local initSoldierRevivePints = @(eid, army)
  soldierRespawnPointsQuery.perform(eid, @(_, comp)
    comp.__update(getSoldierReviveData(army, comp["soldier_revive_points.respawnsToRestoreByCount"])))

local function applyGameModeSoldierModifier(soldier, soldier_modifier) {
  soldier_modifier.each(function(v,k) {
    if (k not in soldier)
      soldier[k] <- v
    else if (typeof(soldier[k]) == "table")
      soldier[k].__update(v)
    else if (typeof(soldier[k]) == "array")
      soldier[k].extend(v)
    else
      soldier[k] <- v
  })
}

local gameModeModifiersQuery = ::ecs.SqQuery("gameModeModifiersQuery", { comps_ro = [["game_mode.soldierModifier", ::ecs.TYPE_OBJECT]] })

local applyGameMode = @(armies) gameModeModifiersQuery.perform(function (_, game_mod_comp) {
  local gameModeSoldierModifier = game_mod_comp["game_mode.soldierModifier"].getAll()
  foreach (army in armies)
    foreach (squad in army?.squads ?? [])
      foreach (soldier in squad?.squad ?? [])
        applyGameModeSoldierModifier(soldier, gameModeSoldierModifier)
})


local function updateProfileFromJwt(evt, eid, comp, isNewFormat) {
  local net = has_network()
  local senderEid = net ? find_player_by_connid(evt.data?.fromconnid ?? INVALID_CONNECTION_ID) : find_local_player()
  if (senderEid != eid)
    return

  local teamEid = comp.team != TEAM_UNASSIGNED ? get_team_eid(comp.team) : INVALID_ENTITY_ID
  local teamArmy = ::ecs.get_comp_val(teamEid, "team.army")
  debug($"Received profile: team = {comp.team}; army = {teamArmy}; player = {eid};")

  comp.isDefaultArmies = false

  local jwt = evt.data?.jwt
  local armies = null
  if (typeof jwt == "array") {
    local res = decode_jwt("".join(jwt), profilePublicKey)
    if ("error" in res) {
      local resError = res["error"]
      debug($"Could not decode profile jwt: {resError}. Fallback to default profile")
    } else {
      if (isNewFormat) {
        armies = res?.payload.armies

        local userid = ::ecs.get_comp_val(eid, "userid", INVALID_USER_ID)
        ::log($"User {userid} has permissions: ", res?.payload.permissions)
      }
      else {
        armies = res?.payload
      }
    }
  }
  if (armies == null || armies.len() == 0 || !validateArmies(armies, teamArmy)) {
    debug($"Received empty profile. Fallback to default profile")
    comp.isDefaultArmies = true
    armies = defaultArmies
  }

  if (!validateArmies(armies, teamArmy)) {
    logerr($"Corrupted profile! Cannot spawn any squad!")
    return
  }

  applyGameMode(armies)
  convertGunMods(armies)
  applyPerks(armies)
  applyGunUpgrades(armies)
  applyVehicleMods(armies)

  comp.armies = armies

  debug($"Received squad data when player {eid} army is {teamArmy}")
  comp.armiesReceivedTime = get_sync_time()
  comp.armiesReceivedTeam = comp.team

  local army = comp.armies[teamArmy]
  local squadsCount = army.squads.len()

  initSoldierRevivePints(eid, army)

  comp["squads.revivePointsList"] = array(squadsCount, 100)
  local revivePointsPerSquad = getRevivePointsHeal(getRespawnsToFullRestore(comp["squads.respawnsToFullRestoreSquadBySquadsCount"], squadsCount))
  comp["squads.revivePointsPerSquad"] = revivePointsPerSquad

  debug($"Total squads count is {squadsCount}. Set {revivePointsPerSquad} revive points per squad for player {eid}.")

  comp["vehicleRespawnsBySquad"] = array(squadsCount).map(@(_, i) {
    lastSpawnOnVehicleAtTime = 0.0
    nextSpawnOnVehicleInTime = 0.0
  })

  local delayedSpawnSquad = comp.delayedSpawnSquad.getAll()
  comp.delayedSpawnSquad = []

  local wallPosters = army?.wallPosters ?? []
  local wallPostersCount = army?.wallPostersCount ?? 0
  if (wallPosters.len() == 0)
    wallPostersCount = 0

  comp["wallPosters.maxCount"] = wallPostersCount
  comp["wallPosters"] = array(wallPosters.len()).map(@(_, i) {
    template = wallPosters[i].template
  })

  ::ecs.set_callback_timer(function() {
      foreach (d in delayedSpawnSquad) {
        debug($"Send delayed CmdSpawnSquad for player {eid}")
        ::ecs.g_entity_mgr.sendEvent(eid, CmdSpawnSquad(d.team, d.possessed, d.squadId, d.memberId, -1))
      }
    },
    0.1, false)
}

local function onSquadsData(evt, eid, comp){ //deprecated will be delete after update profileServer and client
  updateProfileFromJwt(evt, eid, comp, false)
}

local function onProfileJwtData(evt, eid, comp){
  updateProfileFromJwt(evt, eid, comp, true)
}

local comps = {
  comps_rw = [
    ["team", ::ecs.TYPE_INT],
    ["armiesReceivedTime", ::ecs.TYPE_FLOAT],
    ["armiesReceivedTeam", ::ecs.TYPE_INT],
    ["delayedSpawnSquad", ::ecs.TYPE_ARRAY],
    ["armies", ::ecs.TYPE_OBJECT],
    ["squads.revivePointsList", ::ecs.TYPE_ARRAY],
    ["squads.revivePointsPerSquad", ::ecs.TYPE_INT],
    ["vehicleRespawnsBySquad", ::ecs.TYPE_ARRAY],
    ["isDefaultArmies", ::ecs.TYPE_BOOL],
    ["wallPosters.maxCount", ::ecs.TYPE_INT],
    ["wallPosters", ::ecs.TYPE_ARRAY],
  ]
  comps_ro = [
    ["squads.respawnsToFullRestoreSquadBySquadsCount", ::ecs.TYPE_OBJECT]
  ]
}

::ecs.register_es("client_profile_es", {
  [::ecs.sqEvents.CmdSquadsData] = onSquadsData,
}, comps) //deprecated will be delete after update profileServer and client

::ecs.register_es("client_profile_jwt_es", {
  [::ecs.sqEvents.CmdProfileJwtData] = onProfileJwtData,
}, comps)

::ecs.register_es("soldier_revive_points_init_es", {
  [[::ecs.EventEntityCreated, ::ecs.EventComponentsAppear]] = onRevivePointsInit
}, soldierReviveComps, {tags = "server"})

local function stopTimer(eid, reason, printCb = debug) {
  printCb($"Stop wait profile timer: {reason}")
  ::ecs.recreateEntityWithTemplates({eid=eid, removeTemplates=["wait_profile_timer"]})
}

local function checkProfile(dt, eid, comp) {
  local connectedAtTime = comp.connectedAtTime
  if (connectedAtTime < 0.0) {
    debug($"Player {eid} ({comp.userid}) created but not connected yet. Wait for connection")
    return
  }

  if (comp.disconnected)
    return stopTimer(eid, $"Player {eid} ({comp.userid}) has been disconnected")

  if (comp.armiesReceivedTime >= 0.0)
    return stopTimer(eid, $"The profile is received for player {eid} ({comp.userid})")

  local profileWaitTimeout = comp.profileWaitTimeout
  local curWaitTime = get_sync_time() - connectedAtTime
  debug($"Wait profile for {eid} ({comp.userid}) {curWaitTime}/{profileWaitTimeout}")

  if (curWaitTime > profileWaitTimeout) {
    kick_player(comp.userid, $"The profile is not received during time {curWaitTime}")
    stopTimer(eid, $"The profile is missed for player {eid} ({comp.userid}) by timeout!", logerr)
  }
}

local function attachCheckProfile(evt, eid, comp) {
  if (comp.userid != INVALID_USER_ID && has_network())
    ::ecs.recreateEntityWithTemplates({eid=eid, addTemplates=["wait_profile_timer"]})
}

::ecs.register_es("client_profile_attach_wait_profile_es", {onInit = attachCheckProfile}, {comps_ro=[["userid", ::ecs.TYPE_INT64]], comps_rq=["player"]}, {tags="server"})

::ecs.register_es("client_profile_timeout_es", {
  onInit = @(evt, eid, comp) debug($"Start wait pofile timer fo player {eid} ({comp.userid}).")
  onUpdate = checkProfile,
},
{
  comps_ro=[["userid", ::ecs.TYPE_INT64], ["connectedAtTime", ::ecs.TYPE_FLOAT], ["profileWaitTimeout", ::ecs.TYPE_FLOAT], ["armiesReceivedTime", ::ecs.TYPE_FLOAT], ["disconnected", ::ecs.TYPE_BOOL]]
  comps_rq=["waitProfileTimer"]
},
{ tags="server", updateInterval=2.0, after="*" })
 