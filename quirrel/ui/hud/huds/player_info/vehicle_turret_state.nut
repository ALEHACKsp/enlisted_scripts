local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {get_gun_template_by_props_id} = require("dm")

local vehicleTurrets = persist("vehicleTurrets", @() Watched({turrets = []}))
local turretHotkeys = persist("turretHotkeys", @() Watched([]))

local function resetState() {
  vehicleTurrets.update({turrets = []})
}

local function trackComponents(evt, eid, comp) {
  local hero = watchedHeroEid.value
  if (eid != ::ecs.get_comp_val(hero, "human_anim.vehicleSelected")) {
    resetState()
    return
  }

  local turretsByGroup = {}

  foreach (gunEid in comp["turret_control.gunEids"]) {
    local gunPropsId = ::ecs.get_comp_val(gunEid, "gun.propsId", -1)
    local gunTplName = get_gun_template_by_props_id(gunPropsId)
    local gunTpl = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(gunTplName ?? "")

    local turret = {
      isMain = false
      gunEid = gunEid
      gunPropsId = gunPropsId
      name = gunTpl?.getCompValNullable("item.name")
      bulletTypes = gunTpl?.getCompValNullable("gun.bulletTypes").getAll() ?? []
      curAmmo = ::ecs.get_comp_val(gunEid, "gun.ammo") ?? 0
      ammoByBullet = ::ecs.get_comp_val(gunEid, "gun.ammo_by_shell")?.getAll() ?? []
      icon = gunTpl?.getCompValNullable("gun.icon")
    }

    local groupName = ::ecs.get_comp_val(gunEid, "turret.groupName", "")
    if (turretsByGroup?[groupName] == null)
      turretsByGroup[groupName] <- []
    turretsByGroup[groupName].append(turret)
  }

  if (turretsByGroup?[""][0].isMain != null)
    turretsByGroup[""][0].isMain = true

  local turrets = []
  foreach (group, turretsInGroup in turretsByGroup)
    if (group != "")
      turrets.append(turretsInGroup[0])
    else
      turrets.extend(turretsInGroup)

  vehicleTurrets.update({
    turrets = turrets
  })
}

::ecs.register_es("turret_control_ui_es",
  { [["onInit", "onChange"]] = trackComponents, onDestroy = @(...) resetState(), [::ecs.sqEvents.CmdTrackVehicleWithWatched] = trackComponents },
  {
    comps_track = [
      ["turret_control.gunEids", ::ecs.TYPE_EID_LIST],
      ["vehicle_seats_owners", null]
    ]
    comps_rq = ["vehicleWithWatched"]
  }
)

local function get_trigger_mappings(hotkeys) {
  local mappings = {}
  foreach(mapping in hotkeys) {
    local name = mapping?.name
    local hotkey = mapping?.hotkey
    if (name != null && hotkey != null)
      mappings[name] <- hotkey
  }
  return mappings
}

local function trackHotkeys(evt, eid, comp) {
  local groupHotkeys = {}
  local triggerMappingComp = comp["turret_control.triggerMapping"]?.getAll() ?? []
  if (triggerMappingComp.len() < 1){
    turretHotkeys([])
    return
  }

  local triggerMappings = get_trigger_mappings(triggerMappingComp)
  local turretInfo = comp["turret_control.turretInfo"].getAll() ?? []

  foreach (i, gunEid in comp["turret_control.gunEids"]) {
    local groupName = ::ecs.get_comp_val(gunEid, "turret.groupName", "")
    local trigger = turretInfo?[i]?.trigger ?? ""
    local hotkey = triggerMappings?[trigger] ?? ""
    if (groupHotkeys?[groupName] == null)
      groupHotkeys[groupName] <- [hotkey]
    else if (groupName == "")
      groupHotkeys[groupName].append(hotkey)
  }

  local resultHotkeys = []
  foreach (keys in groupHotkeys)
    resultHotkeys.extend(keys)

  turretHotkeys(resultHotkeys)
}

::ecs.register_es("turret_hotkeys_changed_ui_es",
  { [["onInit"]] = trackHotkeys },
  { comps_ro = [
      ["turret_control.triggerMapping", ::ecs.TYPE_SHARED_ARRAY, null],
      ["turret_control.turretInfo", ::ecs.TYPE_SHARED_ARRAY],
      ["turret_control.gunEids", ::ecs.TYPE_EID_LIST]
    ]
    comps_rq = ["heroVehicle"]
  }
)

local turretsControlsQuery = ::ecs.SqQuery("turretsControlsQuery", {comps_ro=["turret_control.gunEids", "vehicle_seats_owners"], comps_rq = ["vehicleWithWatched"]})

local function trackAmmoComponent(evt, eid, comp) {
  turretsControlsQuery.perform(comp["turret.owner"], function(turretEid, turretComp) {
    trackComponents(evt,turretEid,turretComp)
    if (comp["gun.ammo"] == 0)
      ecs.g_entity_mgr.sendEvent(turretEid, ::ecs.event.EventTurretAmmoDepleted())
  })
}

::ecs.register_es("turret_ammo_ui_es",
  { [["onInit", "onChange", "onDestroy"]] = trackAmmoComponent},
  {
    comps_track = [["gun.ammo_by_shell", ::ecs.TYPE_INT_LIST]]
    comps_ro = [["turret.owner", ::ecs.TYPE_EID], ["gun.ammo", ::ecs.TYPE_INT, -1]]
    comps_rq = ["isTurret"]
  }
)

local showVehicleWeapons = ::Computed(@() (vehicleTurrets.value?.turrets?.len() ?? 0) > 0)

local turrets       = ::Computed(@() vehicleTurrets.value?.turrets ?? [])
local mainTurretEid = ::Computed(@() (turrets.value.findvalue(@(v) v?.isMain ?? false) ?? turrets.value?[0])?.gunEid ?? INVALID_ENTITY_ID)

return {
  vehicleTurrets = vehicleTurrets
  showVehicleWeapons = showVehicleWeapons
  mainTurretEid = mainTurretEid
  turretHotkeys = turretHotkeys
}
 