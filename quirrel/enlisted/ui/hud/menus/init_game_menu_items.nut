local {exit_game} = require("app")
local {menuItems} = require("ui/hud/menus/game_menu.nut")
local {showScores} = require("enlisted/ui/hud/huds/scores.nut")
local { showBriefing } = require("enlisted/ui/hud/state/briefingState.nut")
local msgbox = require("ui/components/msgbox.nut")
local { localPlayerEid } = require("ui/hud/state/local_player.nut")
local { has_network } = require("net")

local { btnResume, btnOptions, btnBindKeys, btnSuicide } = require("ui/hud/menus/game_menu_items.nut")

local btnShowScores = {
  text = ::loc("controls/HUD.Scores")
  action = @() showScores(true)
}

local btnBriefing = {
  text = ::loc("gamemenu/btnBriefing")
  action = @() showBriefing(true)
}

local btnExitGame = {
  text = loc("gamemenu/btnExitGame")
  action = function() {
    msgbox.show({
      text = loc("exit_game_confirmation")
      buttons = [
        { text = loc("Yes"),
          action = function() {
            local playerEid = localPlayerEid.value
            if (playerEid == INVALID_ENTITY_ID) {
              exit_game()
              return
            }
            local evt = ::ecs.event.CmdGetBattleResult({})
            ::ecs.g_entity_mgr.sendEvent(playerEid, evt)
            if (has_network()) {
              ::ecs.client_request_unicast_net_sqevent(playerEid, evt)
              ::gui_scene.setTimeout(2.0, exit_game)
            } else
              exit_game()
          }
        }
        { text = loc("No"), isCurrent = true}
      ]
    })
  }
}

menuItems([
  btnResume,
  btnOptions,
  btnBindKeys,
  btnSuicide,
  btnShowScores,
  btnBriefing,
  btnExitGame,
])

 