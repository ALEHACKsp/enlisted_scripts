local { TEAM_UNASSIGNED } = require("team")
local {EventZoneLeave, EventZoneEnter} = require("zoneevents")
local {get_sync_time} = require("net")
local dm = require_optional("dm")
if (dm == null)
  return
local {damage_entity, DamageDesc, DM_ZONE, DM_FIRE} = dm

local function onZoneEnter(event, eid, comp) {
  local visitor = event[0]
  local index = comp["dmgzone.eidsInZone"].indexof(visitor, ::ecs.TYPE_EID)
  if (index == null)
    comp["dmgzone.eidsInZone"].append(visitor, ::ecs.TYPE_EID)
}

local function onZoneLeave(event, eid, comp) {
  local leaver = event[0]
  local index = comp["dmgzone.eidsInZone"].indexof(leaver, ::ecs.TYPE_EID)
  if (index != null)
    comp["dmgzone.eidsInZone"].remove(index)
}

local burningZoneQuery = ::ecs.SqQuery("burningZoneQuery", {
  comps_ro=[
    ["entity_mods.fireDamageMult", ::ecs.TYPE_FLOAT, 1.0],
    ["burning.friendlyDamagePerSecond", ::ecs.TYPE_FLOAT, 0.0],
    ["burning.friendlyDamageProtectionTime", ::ecs.TYPE_FLOAT, 3.0],
    ["team", ::ecs.TYPE_INT, TEAM_UNASSIGNED]
  ]
  comps_rw=[
    ["burning.isBurning", ::ecs.TYPE_BOOL],
    ["burning.offender", ::ecs.TYPE_EID],
    ["burning.tickIncrement" ::ecs.TYPE_FLOAT]
  ]
})

local function friendlyBurnDamage(dt, victimId, offender, pos, comp, fireStartTime) {
  if (offender == INVALID_ENTITY_ID || victimId == offender)
    return false

  local offenderTeam = ::ecs.get_comp_val(offender, "team", TEAM_UNASSIGNED)
  if (offenderTeam != comp["team"])
    return false

  local protectTime = comp["burning.friendlyDamageProtectionTime"]
  if (fireStartTime < 0 || get_sync_time() > fireStartTime + protectTime)
    return false

  local friendlyDamage = comp["burning.friendlyDamagePerSecond"]
  local fireDamageMult = comp["entity_mods.fireDamageMult"]
  damage_entity(victimId, offender, DamageDesc(DM_FIRE, dt * friendlyDamage * fireDamageMult, pos))
  return true
}

local function burn(dt, offender, comp, fireAffectPerTick) {
  local fireDamageMult = comp["entity_mods.fireDamageMult"]
  local dmg = (fireAffectPerTick*fireDamageMult)*dt
  if (dmg <= 0.0)
    return
  comp["burning.isBurning"] = true
  comp["burning.offender"] = offender
  local maxIncrement = comp["burning.tickIncrement"]
  comp["burning.tickIncrement"] = max(maxIncrement, dmg)
}

local function burnDamage(dt, victimId, comp){
  local fireAffectPerTick = comp["dmgzone.fireAffect"]
  if (fireAffectPerTick <= 0)
    return

  local pos = comp["transform"].getcol(3)
  local offender = comp["dmgzone.burningOffender"]
  local fireStartTime = comp["fire_source.startTime"]
  burningZoneQuery.perform(victimId, function(eid, burnComp) {
    if (!friendlyBurnDamage(dt, victimId, offender, pos, burnComp, fireStartTime))
      burn(dt, offender, burnComp, fireAffectPerTick)
  })
}

local function onUpdate(dt, eid, comp){
  local teamToDamage = comp["dmgzone.teamToDamage"]
  foreach (victimId in comp["dmgzone.eidsInZone"]) {
    if (::ecs.get_comp_val(victimId, "in_spawn"))
      continue
    if (!comp["dmgzone.damageInVehicle"] && ::ecs.get_comp_val(victimId, "isInVehicleHidden"))
      continue

    local team = ::ecs.get_comp_val(victimId, "team")
    if (team == TEAM_UNASSIGNED || (team != teamToDamage && teamToDamage != TEAM_UNASSIGNED))
      continue

    local damagePerTick = comp["dmgzone.damage"]
    if (damagePerTick > 0.0) {
      local pos = comp["transform"].getcol(3)
      local zoneDamageMult = ::ecs.get_comp_val(victimId, "entity_mods.zoneDamageMult", 1.0)
      damage_entity(victimId, eid, DamageDesc(comp["dm.damageTypeId"], dt*damagePerTick * zoneDamageMult, pos))
    }
    burnDamage(dt, victimId, comp)
  }
}

::ecs.register_es("dmgzone_es", {
    onUpdate = onUpdate,
    [EventZoneEnter] = onZoneEnter,
    [EventZoneLeave] = onZoneLeave,
  },
  {
    comps_rw = [
      ["dmgzone.eidsInZone", ::ecs.TYPE_EID_LIST],
    ]
    comps_ro = [
      ["dmgzone.damage", ::ecs.TYPE_FLOAT],
      ["dm.damageTypeId", ::ecs.TYPE_INT, DM_ZONE],
      ["transform", ::ecs.TYPE_MATRIX],
      ["dmgzone.teamToDamage",  ::ecs.TYPE_INT],
      ["dmgzone.damageInVehicle", ::ecs.TYPE_BOOL, true],
      ["dmgzone.burningOffender", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["dmgzone.fireAffect", ::ecs.TYPE_FLOAT, -1.0],
      ["fire_source.startTime", ::ecs.TYPE_FLOAT, -1.0]
    ]
  },
  {updateInterval = 1.0, tags="server", after="capzone_es"}
)

 