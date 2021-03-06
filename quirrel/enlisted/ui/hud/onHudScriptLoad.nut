require("ui/hud/state/on_disconnect_server_es.nut")
require("ui/hud/state/assists_es.nut")
require("ui/hud/state/rumble_es.nut")
require("ui/hud/state/equipment_es.nut")
require("ui/hud/spectator_console.nut")
require("ui/hud/state/aiming_smooth.nut")
require("ui/hud/state/cmd_hero_log_event.nut")
require("globals/notifications/disconnectedControllerMsg.nut")
require("globals/notifications/actionInProgressMsg.nut")
require("state/battle_area_warnings.nut")
require("state/team_score_warnings.nut")

require("state/autoShowBriefing.nut")
require("enlisted/enlist/styleUpdate.nut")

require("state/respawnPrioritySelector.nut")
require("state/armyData.nut")
require("state/hints.nut")
require("state/goal.nut")
require("state/kill_log_es.nut")
require("ui/hud/state/gun_blocked_es.nut")

require("hud_layout_setup.nut")
require("huds/vehicle_on_fire.nut")
require("state/afk_warnings.nut")
require("state/rebalanceInform.nut")
require("init_tips.nut")
require("ui/hud/state/vehicle_hp.nut")
require("menus/init_game_menu_items.nut")
require("minimap_setup.nut")
require("commands_menu_setup.nut")
require("building_tool_menu_setup.nut")
require("wallposter_menu_setup.nut")

local enlisted_loading = require("loading/enlisted_loading.nut")
local {loadingComp} = require("ui/loading/loading.nut")
loadingComp(enlisted_loading)

local hud_under = require("hud_under.nut")
local vehicleSight = require("ui/hud/huds/vehicle_sight.nut")
local {crosshairOverheat, crosshairHitmarks, crosshairForbidden, crosshairOverlayTransparency, crosshair} = require("ui/hud/huds/crosshair.nut")
local turretCrosshair = require("ui/hud/huds/turret_crosshair.nut")
local vehicleCrosshair = require("ui/hud/huds/vehicle_crosshair.nut")
local forestall = require("ui/hud/huds/forestall.ui.nut")
local killMarks = require("ui/hud/huds/kill_marks.nut")
local {posHitMarks} = require("ui/hud/huds/hit_marks.nut")
local zonePointers = require("huds/zone_pointers.nut")
local resupplyPointers = require("huds/resupply_pointers.nut")

local {gameHud}  = require("ui/hud/state/gameHuds.nut")
local all_tips = require("ui/hud/huds/tips/all_tips.nut")
local hudLayout = require("ui/hud/hud_layout.nut")
local {isAlive} = require("ui/hud/state/hero_state_es.nut")
local {debriefingShow} = require("state/debriefingStateInBattle.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")

local showHuds = ::Computed(function(){
  return !(!isAlive.value || debriefingShow.value)
})
showHuds.subscribe(@(v) showPlayerHuds(v))
showPlayerHuds(showHuds.value)

local network_error = require("ui/hud/huds/tips/network_error.nut")
local perfStats = require("ui/hud/huds/perf_stats.nut")
local menusUi = require("hud_menus.nut")

local {showCrosshair = false} = require("enlisted/globals/wipFeatures.nut")
local {waterMarks} = require("water_marks.nut")

local function hud(){
  local showPlayerHudsV = showHuds.value
  local children = [
    vehicleSight, //FIXME: should not be in HUD!!!!
    zonePointers,
    resupplyPointers,
    hud_under,
    showPlayerHudsV ? all_tips : null,
    hudLayout,
    showPlayerHudsV ? forestall : null,
    showPlayerHudsV ? killMarks : null,
    showPlayerHudsV ? posHitMarks : null,
    showPlayerHudsV ? turretCrosshair : null,
    showPlayerHudsV ? vehicleCrosshair : null,
  ]
  if (showPlayerHudsV){
    if (showCrosshair) {
      children.append(crosshair)
    } else {
      children.append(crosshairForbidden, crosshairOverheat, crosshairHitmarks, crosshairOverlayTransparency)
    }
  }
  children.append(network_error, perfStats, waterMarks)
  return {
    size = flex(), children = children, watch = showHuds
  }
}
gameHud([hud, menusUi])

local hitMarksState = require("ui/hud/state/hit_marks_es.nut")
hitMarksState.worldKillMarkColor(Color(220,220,220,150))
hitMarksState.hitSize([sh(2), sh(2)])
hitMarksState.killSize([sh(2), sh(2)])
hitMarksState.worldDownedMarkColor(0)
hitMarksState.worldKillTtl(2.5)


 