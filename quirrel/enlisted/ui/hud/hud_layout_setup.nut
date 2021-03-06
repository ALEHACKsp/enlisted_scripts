local hudLayoutState = require("ui/hud/state/hud_layout_state.nut")
local maintenanceProgress = require("huds/maintenance_progress_hint.nut")
local ammoRequestCooldown = require("huds/ammo_request_cooldown_hint.nut")
local vehicleSeats = require("huds/vehicle_seats.nut")
local vehicleChangeSeats = require("huds/vehicle_change_seats.nut")
local fortificationAction = require("enlisted/ui/hud/huds/fortification_builder_action.nut")
local { enterVehicleIndicator, exitVehicleIndicator } = require("enlisted/ui/hud/huds/enter_exit_vehicle.nut")
local putOutFire = require("ui/hud/huds/put_out_fire_indicator.nut")
local squadMembersUi = require("huds/squad_members.ui.nut")
local {chatRoot} = require("ui/hud/chat.nut")
local vehicleRepair = require("huds/vehicle_repair.nut")
local playerEventsRoot = require("ui/hud/huds/player_events.nut")
local throw_grenade_tip = require("ui/hud/huds/tips/throw_grenade_tip.nut")
local artillery_ratio_tip = require("huds/tips/artillery_radio_tip.nut")
local minimap = require("enlisted/ui/hud/menus/enlisted_maps.nut").minimap()
local hitcamera = require("enlisted/ui/hud/huds/hitcamera.ui.nut")
local dmPanel = require("enlisted/ui/hud/huds/dm_panel.ui.nut")

local vehicleWarnings = require("ui/hud/huds/vehicle_warnings.nut")
local vehicleControlHint = require("huds/vehicle_control_hint.nut")
local vehicleSteerTip = require("ui/hud/huds/vehicle_steer_tip.nut")
local planeSteerTip = require("ui/hud/huds/plane_steer_tip.nut")
local vehicleResupplyTip = require("ui/hud/huds/tips/vehicle_resupply.nut")
local {planeHud} = require("ui/hud/huds/plane_hud.nut")

local context_command_hint = require("huds/context_command_hint.ui.nut")
local cancel_context_command_hint = require("huds/cancel_context_command_hint.ui.nut")
local spectatorKeys_tip = require("ui/hud/huds/tips/spectatorKeys_tip.nut")
local { mkActionsRoot, mainAction, localTeamEnemyHint } = require("ui/hud/huds/actions.nut")
local vehicleActions = require("enlisted/ui/hud/huds/vehicleActions.nut")
local buildingActions = require("huds/tips/building_tool_tip.nut")
local wallposterActions = require("huds/tips/wallposter_tool_tip.nut")
local actionsRoot = mkActionsRoot(([mainAction, localTeamEnemyHint].extend(vehicleActions)).extend(buildingActions).extend(wallposterActions))
local vehicleHud = require("huds/vehicle_hud.nut")
local { activeCapZonesEids } = require("enlisted/ui/hud/state/capZones.nut")
local compassZones = require("enlisted/ui/hud/huds/compass_zones.nut")
local compassStrip = require("ui/hud/huds/compass/mk_compass_strip.nut")({
  size = [hdpx(220), hdpx(40)],
  compassObjects = [{watch = activeCapZonesEids, childrenCtor = compassZones}] //!!FIX ME: why subscription here?
  globalScale = 0.8
})
local gameModeBlock = require("huds/game_mode.ui.nut")
local awards = require("huds/player_awards.nut")
local warnings = require("ui/hud/huds/warnings.nut")
local spectatorMode_tip = require("ui/hud/huds/tips/spectatorMode_tip.nut")
local hints = require("ui/hud/huds/hints.nut")
local killLog = require("ui/hud/huds/killLog.nut")
local playerDynamic = require("huds/player_weapons.ui.nut")
local mortarTips = require("common_shooter/ui/hud/huds/tips/mortar_tips.nut")
local {isMortarMode} = require("common_shooter/ui/hud/state/mortar.nut")
local {inPlane} = require("ui/hud/state/vehicle_state.nut")
local {showBigMap} = require("enlisted/ui/hud/menus/big_map.nut")
local {showArtilleryMap} = require("menus/artillery_radio_map.nut")

local showMinimap = Computed(@() !(showArtilleryMap.value || showBigMap.value))
local compassAndMap = @(){
  watch = showMinimap
  flow = FLOW_VERTICAL
  children = [dmPanel, showMinimap.value ? minimap : null, compassStrip]
  gap = hdpx(10)
  size = SIZE_TO_CONTENT
  halign = ALIGN_CENTER
}

local compassOnly = {
  flow = FLOW_VERTICAL
  children = [dmPanel, compassStrip]
  gap = hdpx(10)
  size = SIZE_TO_CONTENT
  halign = ALIGN_CENTER
}

local function minimap_mod() {
  local mc
  if (inPlane.value)
    mc = [compassOnly, vehicleSteerTip, planeSteerTip]
  else if (isMortarMode.value)
    mc = [compassAndMap, mortarTips]
  else
    mc = [compassAndMap, vehicleSteerTip, planeSteerTip]
  return {
    children = mc
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    gap = hdpx(5)
    watch = [isMortarMode, inPlane]
  }
}

hudLayoutState.leftPanelTop.update([planeHud, vehicleHud])
hudLayoutState.leftPanelMiddle.update([chatRoot, squadMembersUi])
hudLayoutState.leftPanelBottom.update([vehicleSeats, minimap_mod])

hudLayoutState.centerPanelTopStyle({gap=hdpx(2), size = flex(4)})
hudLayoutState.centerPanelTop.update([gameModeBlock, hints, warnings, spectatorMode_tip, vehicleChangeSeats, enterVehicleIndicator, exitVehicleIndicator])
hudLayoutState.centerPanelMiddleStyle({gap=hdpx(2), size = flex(4)})
hudLayoutState.centerPanelMiddle.update([playerEventsRoot, vehicleRepair, maintenanceProgress, ammoRequestCooldown, putOutFire, fortificationAction, awards])
hudLayoutState.centerPanelBottom.update([vehicleWarnings, actionsRoot, throw_grenade_tip, artillery_ratio_tip, vehicleResupplyTip,
                                         vehicleControlHint, spectatorKeys_tip, context_command_hint, cancel_context_command_hint])

hudLayoutState.rightPanelTop.update([hitcamera])
hudLayoutState.rightPanelMiddle.update([killLog])
hudLayoutState.rightPanelBottom.update([playerDynamic])
 