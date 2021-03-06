local { heroActiveResupplyZonesEids } = require("enlisted/ui/hud/state/resupplyZones.nut")
local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local style = require("ui/hud/style.nut")

local tip = tipCmp({text = loc("resupply/tip"), font = Fonts.medium_text, textColor = style.HUD_TIPS_FAIL_TEXT_COLOR})

local isResupplyTipShown = Watched(false)

local function resupplyTipTimer(){
  isResupplyTipShown(false)
}

const RESUPPLY_TIP_SHOW_TIME = 5

local function showResupplyTip() {
  if (isResupplyTipShown.value)
    ::gui_scene.clearTimer(resupplyTipTimer)
  isResupplyTipShown(true)
  ::gui_scene.setTimeout(RESUPPLY_TIP_SHOW_TIME, resupplyTipTimer)
}

local function isShootingDry(comp) {
  local gunEids = comp["turret_control.gunEids"].getAll()
  local shootFlags = comp["turret_input.shootFlag"].getAll()
  local isAnyTurretShooting = false
  for (local turretNo = 0; turretNo < gunEids.len(); ++turretNo) {
    local isShooting = shootFlags?[turretNo] ?? false
    isAnyTurretShooting = isAnyTurretShooting || isShooting

    local gunEid = gunEids[turretNo]
    local gunAmmo = ::ecs.get_comp_val(gunEid, "gun.ammo", 0)
    if (isShooting && gunAmmo > 0)
      return false
  }
  return isAnyTurretShooting
}

local function trackComps(comp) {
  if (heroActiveResupplyZonesEids.value.len() <= 0)
    return
  if (isShootingDry(comp))
    showResupplyTip()
}

::ecs.register_es("turret_dry_shoot",
  { [["onInit", "onChange"]] = @(evt, eid, comp) trackComps(comp),
    [::ecs.sqEvents.EventTurretAmmoDepleted] = @(evt, eid, comp) trackComps(comp)
  },
  {
    comps_track = [["turret_input.shootFlag", ::ecs.TYPE_BOOL_LIST]]
    comps_ro = [["turret_control.gunEids", ::ecs.TYPE_EID_LIST]]
    comps_rq = ["heroVehicle"]
  }
)

return @() {
  flow = FLOW_HORIZONTAL
  watch = [isResupplyTipShown]
  children = isResupplyTipShown.value ? tip : null
}
 