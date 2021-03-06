local colors = require("ui/style/colors.nut")
local roomState = require("state/roomState.nut")
local textButton = require("components/textButton.nut")
local textInput = require("ui/components/textInput.nut")
local checkbox = require("ui/components/checkbox.nut")
local msgbox = require("components/msgbox.nut")
local string = require("string")
local showCreateRoom = require("globals/uistate.nut").showCreateRoom
local comboBox = require("ui/components/combobox.nut")
local clusterState = require("clusterState.nut")
local matching_errors = require("matching.errors")
local roomSettings = require("roomSettings.nut")
local localGames = require("localGames.nut")
local gameLauncher = require("gameLauncher.nut")
local {get_app_id} = require("app")
local JB = require("ui/control/gui_buttons.nut")

local playersAmountList = [1, 2, 4, 8, 12, 16, 20, 24, 32, 40, 50, 64, 70, 80, 100, 128]
local groupSizes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]


local formState = make_persists(persist, {
  usePassword = Watched(false)
  password = Watched("")
  focusedField = Watched(null)
})

formState.__update({ //!!FIX ME: better to remove this, and use direct roomSettings
  game = roomSettings.game
  scenes = roomSettings.scenes
  scene = roomSettings.scene
  roomName = roomSettings.roomName
  minPlayers = roomSettings.minPlayers
  maxPlayers = roomSettings.maxPlayers
  startOffline = roomSettings.startOffline
  botsPopulation = roomSettings.botsPopulation
  writeReplay = roomSettings.writeReplay
  groupSize = roomSettings.groupSize
})

local function getGamesList() {
  local ret = []
  foreach (id, gameInfo in localGames)
    if (gameInfo.scenes.len() > 0)
      ret.append([gameInfo, gameInfo.title])
  return ret
}

local function createRoomCb(response) {
  if (response.error != 0) {
    formState.roomName.update("")
    formState.password.update("")

    msgbox.show({
      text = ::loc("customRoom/failCreate", {responce_error=matching_errors.error_string(response.error)})
    })
  }
}

local function availableFields() {
  return [
    formState.roomName,
    formState.usePassword,
    formState.startOffline,
    (formState.usePassword.value ? formState.password : null),
  ].filter(@(val) val)
}


/*
local function tabFocusTraverse(delta) {
  local tabOrder = availableFields()

  local curIdx = tabOrder.indexof(formState.focusedField.value)
  if (curIdx==null)
    ::set_kb_focus(tabOrder[0])
  else {
    local newIdx = (curIdx + tabOrder.len() + delta) % tabOrder.len()
    ::set_kb_focus(tabOrder[newIdx])
  }
}
*/
local function doCreateRoom() {
  local isValid = true

  foreach (f in availableFields()) {
    if (typeof(f.value)=="string" && !string.strip(f.value).len()) {
      ::anim_start(f)
      isValid = false
    }
  }

  if (isValid) {
    local params = {
      public = {
        players = formState.maxPlayers.value
        roomName = string.strip(formState.roomName.value)
        gameName = formState.game.value?.id
        scene = formState.scene.value?.id
        cluster = clusterState.oneOfSelectedClusters.value
        appId = get_app_id()
        groupSize = formState.groupSize.value
      }
    }
    if (formState.usePassword.value && formState.password.value)
      params.password <- string.strip(formState.password.value)
    if (formState.botsPopulation.value > 0)
      params.public.botpop <- formState.botsPopulation.value

    if (formState.writeReplay.value)
      params.public.writeReplay <- true

    if (!formState.startOffline.value)
      roomState.createRoom(params, createRoomCb)
    else {
      roomState._beforeGameLaunchCbs.callback(function(extraGameLaunchParams) {
        local launchParams = {
          game = formState.game.value.id
          scene = formState.scene.value.id
        }.__update(extraGameLaunchParams)
        gameLauncher.startGame(launchParams, function(...) {})
      })
    }
  }
}

local function makeFormItemHandlers(field) {
  return {
    onFocus = @() formState.focusedField.update(field)
    onBlur = @() formState.focusedField.update(null)
    onAttach = function(elem) {
      local focusOn = formState.focusedField.value
      if (focusOn && field == focusOn)
        ::set_kb_focus(elem)
    }

    onReturn = doCreateRoom
  }
}

local function formText(params) {
  local options = {
    placeholder = params?.placeholder ?? ""
  }.__update(params)
  return textInput.Underlined(params.state, options, makeFormItemHandlers(params.state))
}


local function formCheckbox(params={}) {
  return checkbox(params.state, params?.name, makeFormItemHandlers(params.state))
}

local formComboWithTitle = @(watch, values, title) {
  size=[flex(), fontH(180)]
  font=Fonts.medium_text
  flow = FLOW_HORIZONTAL
  margin = ::hdpx(2)
  children = [
    {
      rendObj = ROBJ_DTEXT
      text = title
      color = colors.Inactive
      vplace = ALIGN_CENTER
      size=[flex(), fontH(180)]
    }
    {
      size = [fontH(650), fontH(180)]
      hplace = ALIGN_RIGHT
      halign = ALIGN_RIGHT
      children = comboBox(watch, values)
    }
  ]
}


local function createRoom() {
  return {
    size = [sh(30), sh(60)]
    pos = [0, sh(20)]
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER

    key = "create-room"

    watch = [formState.usePassword, formState.game]
    children = [
      {
        flow = FLOW_VERTICAL
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          {
            size=[flex(), fontH(180)]
            font=Fonts.medium_text
            children = comboBox(formState.game, getGamesList()) // current game
          },
          @() {
            watch = formState.scenes
            size = [flex(), fontH(180)]
            font = Fonts.medium_text
            children = comboBox(formState.scene, formState.scenes.value.map(@(s) [s, s.title])) // current scene
          },
          formComboWithTitle(formState.minPlayers, playersAmountList, ::loc("players to start")),
          formComboWithTitle(formState.maxPlayers, playersAmountList, ::loc("Max players")),
          formComboWithTitle(formState.botsPopulation, [0].extend(playersAmountList), ::loc("Bots population")),
          formComboWithTitle(formState.groupSize, groupSizes, ::loc("Group size")),
          formText({state=formState.roomName, placeholder = ::loc("customRoom/roomName_placeholder")}),
          formCheckbox({state=formState.startOffline, name=::loc("customRoom/startOffline")}),
          formCheckbox({state=formState.usePassword, name=::loc("customRoom/usePassword")}),
          (formState.usePassword.value ? formText({state=formState.password placeholder=::loc("password_placeholder","password") password="*"}) : null),
          formCheckbox({state=formState.writeReplay, name=::loc("customRoom/writeReplay")})
        ]
      }
      {
        size = SIZE_TO_CONTENT
        vplace = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        children = [textButton(::loc("Create"), doCreateRoom, {hotkeys=[["^J:X"]]}),
                    textButton(::loc("Close"), function() {showCreateRoom.update(false)}, {hotkeys=[["^{0} | Esc".subst(JB.B)]]}) ]
      }
    ]
  }
}

return createRoom
 