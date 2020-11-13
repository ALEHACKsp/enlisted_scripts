local roomState = require("state/roomState.nut")
local textButton = require("components/textButton.nut")
local msgbox = require("components/msgbox.nut")
local colors = require("ui/style/colors.nut")
local chatRoom = require("globals/chat/chatRoom.nut")
local LobbyStatus  = require("enlist/lobbyStatusEnum.nut")
local matching_errors = require("matching.errors")
local roomSettings = require("roomSettings.nut")
local membersSpeaking = require("ui/hud/state/voice_chat.nut")
local remap_nick = require("globals/remap_nick.nut")
local JB = require("ui/control/gui_buttons.nut")

local function startSessionCb(response) {
  local function reportError(text) {
    console_print(text)
    msgbox.show({text=text})
  }

  if (response?.accept == false) // server rejected invite
    reportError("Failed to start session in room: {0}".subst(response?.reason ?? ""))
  else if (response.error != 0)
    reportError("Failed to start session in room: Battle servers not found")

}


local function doStartSession() {
  roomState.lobbyStatus.update(LobbyStatus.CreatingGame)
  roomState.startSession(startSessionCb)
}


local function leaveRoomCb(response) {
  if (response.error) {
    msgbox.show({
      text = "Failed to leave room: {0}".subst(matching_errors.error_string(response.error))
    })
  }
}

local function doLeaveRoom() {
  roomState.leaveRoom(leaveRoomCb)
}

local function destroyRoomCb(response) {
  if (response.error) {
    msgbox.show({
      text = "Failed to destroy room: {0}".subst(matching_errors.error_string(response.error))
    })
  }
}

local function doDestroyRoom() {
  roomState.destroyRoom(destroyRoomCb)
}

local function memberInfoItem(member) {
  local colorSpeaking = Color(20, 220, 20, 255)
  local colorSilent = colors.TextHighlight
  return function() {
    local prefix = member.squadNum == 0 ? "" : $"[{member.squadNum}] "
    local text = prefix + remap_nick(member.name)

    return {
      watch = [membersSpeaking]
      color = membersSpeaking.value?[member.name] ? colorSpeaking : colorSilent
      rendObj = ROBJ_DTEXT
      text = text
      font = Fonts.medium_text
      margin = sh(1)
      hplace = ALIGN_LEFT
      validateStaticText = false
    }
  }
}


local function listContent() {
  local players = roomState.roomMembers.value.
    filter(@(member) !member.public?.host)
  players.sort(@(a, b) (a.public?.squadId ?? 0) <=> (b.public?.squadId ?? 0))

  local squadNum = 0
  local prevSquadId = null
  foreach (player in players) {
    local squadId = player.public?.squadId
    if (squadId == null)
      player.squadNum <- 0
    else {
      if (squadId != prevSquadId) {
        squadNum += 1
        prevSquadId = squadId
      }
      player.squadNum <- squadNum
    }
  }

  local children = players.map(@(member) memberInfoItem(member))

  return {
    watch = [roomState.roomMembers]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    size = [flex(), SIZE_TO_CONTENT]
    children = children
  }
}


//dlogsplit(roomState.room.value.public)
local header = {
  vplace = ALIGN_TOP
  rendObj = ROBJ_SOLID
  color = colors.HeaderOverlay
  size = [flex(), sh(4)]
  flow = FLOW_HORIZONTAL
  gap = hdpx(1)
  children = function() {
    local scene = null
    if (roomState.room.value?.roomId) {
      scene = roomState.room.value.public?.title
      if (scene == null) {
        scene = roomState.room.value.public?.scene
        if (scene != null)
          scene = scene.split("/")
        if (scene.len()>0)
          scene = scene[scene.len()-1]
        scene = scene.split(".")
                .slice(0,-1)
        scene = "".join(scene.filter(@(val) val != "" && val != null))
      }
    }
    return {
      watch = [roomState.room]
      margin = [sh(1), sh(3)]
      rendObj = ROBJ_DTEXT
      font = Fonts.small_text
      text = roomState.room.value?.roomId != null ?
        "{roomName}. {loccreator}{:} {creator}, {server}{:} {cluster}, {scene}".subst(roomState.room.value.public.__merge({
            scene=scene, [":"]=":",loccreator=::loc("Creator")
            server=::loc("server")
            creator = remap_nick(roomState.room.value.public?.creator ?? "")
          })
        )
        :
        null
//      ::loc("lobby/roomName","Name: ") + (roomState.room.value?.roomId != null ? roomState.room.value.public.roomName : "")
    }
  }
}


local function membersListRoot() {
  return {
    size = [sw(20), sh(60)]
    hplace = ALIGN_LEFT
    pos = [sw(10), sh(10)]

    rendObj = ROBJ_FRAME
    color = colors.Inactive
    borderWidth = [2, 0]
    padding = [2, 0]

    key = "members-list"

    children = {
      size = flex()
      clipChildren = true

      children = {
        size = flex()
        flow = FLOW_VERTICAL

        behavior = Behaviors.WheelScroll

        children = listContent
      }
    }
  }
}


local function statusText() {
  local text = ""
  local lobbyStatus = roomState.lobbyStatus.value
  if (lobbyStatus == LobbyStatus.ReadyToStart)
    text = ::loc("lobbyStatus/ReadyToStart", {num_players = roomSettings.minPlayers.value, start_game_btn=::loc("lobby/startGameBtn")})
  else if (lobbyStatus == LobbyStatus.NotEnoughPlayers)
    text = ::loc("lobbyStatus/NotEnoughPlayers")
  else if (lobbyStatus == LobbyStatus.CreatingGame)
    text = ::loc("lobbyStatus/CreatingGame")
  else if (lobbyStatus == LobbyStatus.GameInProgress)
    text = ::loc("lobbyStatus/GameInProgress")
  else if (lobbyStatus == LobbyStatus.GameInProgressNoLaunched)
    text = ::loc("lobbyStatus/GameInProgressNoLaunched", {play=::loc("lobby/playBtn")})

  return {
    size = [sw(100), SIZE_TO_CONTENT]
    vplace = ALIGN_TOP
    pos = [0, sh(5.8)]
    halign = ALIGN_CENTER
    watch = [
      roomState.lobbyStatus
    ]
    children = {
      rendObj = ROBJ_DTEXT
      text = text
      color = Color(200,200,50)
      font = Fonts.medium_text
    }
  }
}


local function startGameButton() {
  return textButton(::loc("lobby/startGameBtn"), doStartSession,
                    {
                      hotkeys=[["^J:X"]]
                      sound = {
                        click  = "ui/enlist/start_game_click"
                        hover  = "ui/enlist/button_highlight"
                        active = "ui/enlist/button_action"
                      }
                    })
}

local function actionButtons() {
  local function showStartGameButton() {
    return (roomState.lobbyStatus.value == LobbyStatus.ReadyToStart)
  }

  local function showPlayButton() {
    return roomState.lobbyStatus.value == LobbyStatus.GameInProgressNoLaunched
  }

  return {
    vplace = ALIGN_BOTTOM
    size = [flex(), SIZE_TO_CONTENT]
    watch = [
      roomState.lobbyStatus
      roomState.roomMembers
    ]

    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = [
      (showStartGameButton() ? startGameButton() : null),
      (showPlayButton() ? textButton(::loc("lobby/playBtn"), roomState.connectToHost) : null),
      textButton(::loc("lobby/leaveBtn"), doLeaveRoom, {hotkeys=[["^{0} | Esc".subst(JB.B)]]}),
      (roomState.canOperateRoom()
        ? textButton(::loc("lobby/destroyRoomBtn"), doDestroyRoom, {hotkeys=[["^J:Y"]]})
        : null)
    ]
  }
}

local function chatRoot() {
  return {
    size = [sw(55), sh(60)]
    pos = [sw(35), sh(10)]
    hplace = ALIGN_LEFT
    children = chatRoom(roomState.chatId.value)
    watch = roomState.chatId
  }
}


local function roomScreen() {
  return {
    size = [flex(), flex()]
    halign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(150,150,150,255)
    children = [
      header
      membersListRoot
      chatRoot
      statusText
      actionButtons
    ]
  }
}

return roomScreen
 