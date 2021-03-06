require("state/debriefing_es.nut")//fixme
local { get_setting_by_blk_path } = require("settings")
local { showChatInput } =  require("ui/hud/chat.nut")
local briefing = require("huds/overlays/enlisted_briefing.nut")
local { showBriefing } = require("state/briefingState.nut")

local { menusUi, hudMenus, openMenu } = require("ui/hud/hud_menus.nut")
local { scoresMenuUi, showScores } = require("huds/scores.nut")
local respawn = require("menus/respawn.nut")

local { showBigMap, bigMap } = require("enlisted/ui/hud/menus/big_map.nut")
local { showPieMenu } = require("ui/hud/state/pie_menu_state.nut")
local { inVehicle } = require("ui/hud/state/vehicle_state.nut")
local pieMenu = require("ui/hud/pieMenu.ui.nut")
local { showBuildingToolMenu } = require("ui/hud/state/building_tool_menu_state.nut")
local buildingToolMenu = require("enlisted/ui/hud/huds/building_tool_menu.ui.nut")
local { isBuildingToolMenuAvailable } = require("ui/hud/state/building_tool_state.nut")
local { showWallposterMenu } = require("enlisted/ui/hud/state/wallposter_menu.nut")
local wallposterMenu = require("enlisted/ui/hud/huds/wallposter_menu.ui.nut")

local function openBuildingToolMenu() {
  if (isBuildingToolMenuAvailable.value)
    showBuildingToolMenu(true)
}

local { artilleryMap, showArtilleryMap } = require("enlisted/ui/hud/menus/artillery_radio_map.nut")

local { debriefingShow, debriefingDataExt } = require("enlisted/ui/hud/state/debriefingStateInBattle.nut")
local debriefing = require("menus/mk_debriefing.nut")(debriefingDataExt)

local function openCommandsMenu(){
  showPieMenu(!inVehicle.value)
}

inVehicle.subscribe(@(v) v ? showPieMenu(false) : null)

local showSpawnMenu = persist("showSpawnMenu", @() Watched(false))
local groups = {
  debriefing = 1
  respawn   = 2
  gameHud   = 3
  chatInput = 4
  pieMenu   = 5
}

local disableMenu = get_setting_by_blk_path("disableMenu") ?? false
hudMenus([
    { show = showBuildingToolMenu,
      menu = buildingToolMenu,
      close = @() showBuildingToolMenu(false)
      open = openBuildingToolMenu
      event = "HUD.BuildingToolMenu"
      group = groups.pieMenu,
      id = "BuildingToolMenu"
    }
    { show = showWallposterMenu,
      menu = wallposterMenu,
      close = @() showWallposterMenu(false)
      open = @() showWallposterMenu(true)
      event = "HUD.WallposterMenu"
      group = groups.pieMenu,
      id = "WallposterMenu"
    }
    { show = showPieMenu,
      open = openCommandsMenu,
      close = @() showPieMenu(false)
      menu = pieMenu,
      event = "HUD.CommandsMenu"
      group = groups.pieMenu,
      id = "PieMenu"
    }
    { show = showChatInput                           event = "HUD.ChatInput" group = groups.chatInput  id = "Chat" }
    { show = showBriefing        menu = briefing     event = "HUD.Briefing"  group = groups.gameHud    id = "Briefing" }
    { show = showArtilleryMap,   menu = artilleryMap,                        group = groups.gameHud,   id = "ArtilleryMap" }
    { show = showBigMap          menu = bigMap       event = "HUD.BigMap"    group = groups.gameHud    id = "BigMap" }
    { show = showScores,         menu = scoresMenuUi, event = "HUD.Scores",  group = disableMenu ? groups.debriefing : groups.gameHud, id = "Scores" }
    { show = debriefingShow,     menu = debriefing,                          group = groups.debriefing,id = "Debriefing" }
    { show = showSpawnMenu,      menu = respawn,                             group = groups.respawn,   id = "Respawn" }
  ]
)

debriefingDataExt.subscribe(function(val) {
  if (val.len() > 0)
    openMenu("Debriefing")
})

return menusUi 