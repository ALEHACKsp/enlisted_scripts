local { showInventory } = require("inventory.nut")
local { showSettingsMenu } = require("settings_menu.nut")
local { showControlsMenu } = require("controls_setup.nut")
local { exit_game } = require("app")

local msgbox = require("ui/components/msgbox.nut")
local {request_suicide} = require("dm")

local items = {
  btnResume = {
    text = ::loc("gamemenu/btnResume")
    action = @() true
  }
  btnOptions = {
    text = ::loc("gamemenu/btnOptions")
    action = @() showSettingsMenu.update(true)
  }
  btnBindKeys = {
    text = ::loc("gamemenu/btnBindKeys")
    action = @() showControlsMenu.update(true)
  }
  btnSuicide = {
    text = loc("gamemenu/btnSuicide")
    action = function() {
      msgbox.show({
        text = loc("suicide_confirmation")
        buttons = [
          { text=loc("Yes"), action = @() request_suicide() }
          { text=loc("No"), isCurrent = true}
        ]
      })
    }
  }
  btnInventory = {
    text = loc("gamemenu/btnInventory")
    action = @() showInventory.update(true)
  }
  btnExitGame = {
    text = loc("gamemenu/btnExitGame")
    action = function() {
      msgbox.show({
        text = loc("exit_game_confirmation")
        buttons = [
          { text=loc("Yes"), action=exit_game}
          { text=loc("No"), isCurrent=true}
        ]
      })
    }
  }
}

return items
 