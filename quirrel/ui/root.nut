require("ui/ui_config.nut")
require("game_console.nut")
local hud = require("hud/hud.nut")
local {msgboxes} = require("msgboxes.nut")
local {uiDisabled, levelLoaded} = require("ui/hud/state/appState.nut")
local {loadingUI} = require("ui/loading/loading.nut")
local globInput = require("glob_input.nut")
local hotkeysPanel = require("ui/hotkeysPanel.nut")
local speakingList = require("ui/speaking_list.nut")
local modalWindows = require("daRg/components/modalWindows.nut")
local {dbgSafeArea} = require("dbgSafeArea.nut")
local {DBGLEVEL} = require("dagor.system")
local platform = require("globals/platform.nut")
local {editor, showUIinEditor, editorIsActive} = require("editor.nut")
local {serviceInfo} = require("service_info.nut")

require("dainput2").set_double_click_time(220)
require("sound_handlers.nut")

if (platform.is_xbox || platform.is_sony)
  require("invitation/onInviteAccept.nut")

local function root() {

  local content = null
  if (uiDisabled.value) {
    content = null
  }
  else if (loadingUI.value != null || !levelLoaded.value) {
    content = loadingUI.value
  }
  else {
    content = hud
  }

  local children = !uiDisabled.value
    ? [
        globInput
        content
        modalWindows.component
        msgboxes
        hotkeysPanel
        speakingList
        dbgSafeArea
        globInput
      ]
    : [ dbgSafeArea, content ]


  if (editorIsActive.value && !showUIinEditor.value)
    children = [globInput, editor]
  else if (showUIinEditor.value)
    children.append(editor)

  if (!uiDisabled.value && levelLoaded.value && (DBGLEVEL > 0 || platform.is_pc))
    children.append(serviceInfo)

  return {
    watch = [loadingUI, uiDisabled, editorIsActive, showUIinEditor]
    size = flex()
    children = children
  }
}

return root
 