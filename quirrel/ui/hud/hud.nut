local {get_game_name} = require("app")
require_optional($"{get_game_name()}/ui/hud/beforeHudScriptLoad.nut") //this allow to inject in ANY module that allows injection

local inspector = require("ui/components/inspector.nut")
local {lastActiveControlsType} = require("ui/control/active_controls.nut")
local {gameHud}  = require("ui/hud/state/gameHuds.nut")
local {showSettingsMenu, mkSettingsMenuUi} = require("menus/settings_menu.nut")

local {gameMenu, showGameMenu} = require("menus/game_menu.nut")

local settingsMenuUi = mkSettingsMenuUi({
  onClose = @() showSettingsMenu(false)
})

local {controlsMenuUi, showControlsMenu} = require("menus/controls_setup.nut")

require_optional($"{get_game_name()}/ui/hud/onHudScriptLoad.nut")

local function gameMenus(){
  local children
  if (showGameMenu.value)
    children = gameMenu
  else if (showSettingsMenu.value)
    children = settingsMenuUi
  else if (showControlsMenu.value)
    children = controlsMenuUi

  return {
    size = flex()
    children = children
    eventHandlers = {["HUD.GameMenu"] = @(event) showGameMenu(!showGameMenu.value)}
    watch = [showSettingsMenu, showControlsMenu,
      showGameMenu]
  }
}

local function HudRoot() {
  local children = [].extend(gameHud.value  ?? []).append(gameMenus, inspector)

  return {
    size = flex()
//    rendObj = ROBJ_FRAME
    children = children
    watch = [lastActiveControlsType, gameHud]
  }
}

return HudRoot
 