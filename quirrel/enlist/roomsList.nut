local {showCreateRoom} = require("globals/uistate.nut")
local frp = require("std/frp.nut")
local roomsListState = require("roomsListState.nut")
local localGames = require("localGames.nut")
local roomState = require("state/roomState.nut")
local textButton = require("components/textButton.nut")
local textInput = require("ui/components/textInput.nut")
local centeredText = require("components/centeredText.nut")
local checkBox = require("ui/components/checkbox.nut")
local msgbox = require("ui/components/msgbox.nut")
local math = require("math")
local scrollbar = require("ui/components/scrollbar.nut")
local createRoom = require("createRoom.nut")
local colors = require("ui/style/colors.nut")
local {tostring_any} = require("std/string.nut")
local matching_errors = require("matching.errors")
local {squadId} = require("enlist/squad/squadState.nut")

local {lobbyEnabled} = roomsListState

local selectedRoom = Watched(null)
local string = require("string")

local scrollHandler = ScrollHandler()

local function tryToJoin(room, cb, password="" ){
  local params = { roomId = room.roomId.tointeger() }
  if (squadId.value != null)
    params.member <- { public = {squadId = squadId.value} }
  if (selectedRoom.value.public?.hasPassword)
    params.password <- string.strip(password)
  roomState.joinRoom(params, true, cb)
}

local function mkFindSomeMatch(cb) {
  return function(){
    local candidates = []
    foreach (room in roomsListState.list.value) {
      if (room.public?.hasPassword)
        continue
      if (room.membersCnt >= (room?.size??0) || !room.membersCnt)
        continue
      candidates.append(room)
    }

    if (!candidates.len()) {
      msgbox.show({
        text = ::loc("Cannot find existing game. Create one?")
        buttons = [
          { text = ::loc("Yes"), action = @() showCreateRoom.update(true) }
          { text = ::loc("No")}
        ]
      })
    }
    else {
      local room = candidates[math.rand() % candidates.len()]
      tryToJoin(room, cb, "")
    }
  }
}

local function fullRoomMsgBox(action) {
  msgbox.show({
    text = ::loc("msgboxtext/roomIsFull")
    buttons = [
      { text = ::loc("Yes"), action = action }
      { text = ::loc("No")}
    ]
  })
}

local function joinCb(response) {
  if (response.error != matching_errors.OK){
    if (response.error == matching_errors.SERVER_ERROR_ROOM_FULL) {
      fullRoomMsgBox(mkFindSomeMatch(joinCb))
      return
    }

    msgbox.show({
      text = ::loc("msgbox/failedJoinRoom", "Failed to join room: {error}", {error=matching_errors.error_string(response.error)})
    })
  } else {
    selectedRoom.update(null)
  }
}
local findSomeMatch = mkFindSomeMatch(joinCb)


local function doJoin() {
  local roomPassword = Watched("")
  local room = selectedRoom.value
  if (!room) {
    msgbox.show({text=::loc("msgbox/noRoomTOJoin", "No room selected")})
    return
  }

  if (room && room.public?.hasPassword){
    local function passwordInput() {
      local input = null

      if (room && room.public?.hasPassword) {
        input = textInput(roomPassword, {
          placeholder="password"
        })
      }

      return {
        key = "room-password"
        size = [sw(20), SIZE_TO_CONTENT]
        children = input
      }
    }

    msgbox.show({
      text = ::loc("This room requires password to join")
      children = passwordInput
      buttons = [
        { text = ::loc("Proceed"), action = function() {tryToJoin(room, joinCb, roomPassword.value)} }
        { text = ::loc("Cancel") }
      ]
    })
  }
  else
    tryToJoin(room, joinCb)
}


local function itemText(text, options={}) {
  return {
    rendObj = ROBJ_DTEXT
    font = Fonts.small_text
    text = text
    margin = sh(1)
    size = ("pw" in options) ? [flex(options.pw), SIZE_TO_CONTENT] : SIZE_TO_CONTENT
  }
}


local colWidths = [25, 35, 12, 8, 25]

local getGameTitle = @(id) localGames?[id].title ?? id

local function listItem(room) {
  local stateFlags = Watched(0)

  local roomName = room.public?.roomName ?? tostring_any(room.roomId)
  if (room.public?.hasPassword)
    roomName = "{0}*".subst(roomName)

  return function() {
    local color
    if (selectedRoom.value && (room.roomId == selectedRoom.value.roomId))
      color = colors.SelectedItemBg
    else
      color = (stateFlags.value & S_HOVER) ? colors.HoverItemBg : Color(0,0,0,0)

    return {
      rendObj = ROBJ_SOLID
      color = color
      size = [flex(), SIZE_TO_CONTENT]

      behavior = Behaviors.Button
      onClick = @() selectedRoom.update(room)
      onDoubleClick = doJoin
      onElemState = @(sf) stateFlags.update(sf)
      watch = [selectedRoom, stateFlags]
      key = room.roomId

      sound = {
        click  = "ui/enlist/button_click"
        hover  = "ui/enlist/button_highlight"
        active = "ui/enlist/button_action"
      }

      flow = FLOW_HORIZONTAL
      children = [
        itemText(roomName, {pw=colWidths[0]})
        itemText(getGameTitle(room.public?.gameName ?? "???"), {pw=colWidths[1]})
        itemText(room.public?.hasSession ? ::loc("In session") : ::loc("In lobby"), {pw=colWidths[2]})
        itemText(tostring_any(room.membersCnt), {pw=colWidths[3]})
        itemText(room.public?.creator ?? ::loc("creator/auto"), {pw=colWidths[4]})
      ]
    }
  }
}


local function listHeader() {
  return {
    hplace = ALIGN_CENTER
    size = [flex(), SIZE_TO_CONTENT]
    pos = [0, sh(11)]
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      margin = [0, sh(1), 0, 0]
      flow = FLOW_HORIZONTAL
      children = [
        itemText(::loc("Name"), {pw=colWidths[0]})
        itemText(::loc("Game"), {pw=colWidths[1]})
        itemText(::loc("Status"), {pw=colWidths[2]})
        itemText(::loc("Players"), {pw=colWidths[3]})
        itemText(::loc("Creator"), {pw=colWidths[4]})
      ]
    }
  }
}


local nameFilter = persist("nameFilter", @() Watched(""))
local filteredList = frp.combine({nameFilter=nameFilter, rooms = roomsListState.list},
  function(_){
    return _.rooms.filter(
      function(room) {
        local flt = _.nameFilter.tolower()
        if (flt.len()) {
          local roomName = room.public?.roomName || tostring_any(room.roomId)
          if (roomName.tolower().indexof(flt)==null)
            return false
        }
        return true
      }
    )
  }
)

local function listContent() {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    watch = filteredList
    flow = FLOW_VERTICAL
    children = filteredList.value.map(@(room) listItem(room))
  }
}


local function roomsList() {
  return {
    size = [flex(), sh(60)]
    hplace = ALIGN_CENTER
    pos = [0, sh(15)]

    rendObj = ROBJ_FRAME
    color = colors.Inactive
    borderWidth = [2, 0]

    key = "rooms-list"

    valign = ALIGN_CENTER

    children = scrollbar.makeVertScroll(listContent, {
      scrollHandler = scrollHandler
      rootBase = class {
        size = flex()
        margin = [2, 0]
      }
    })
  }
}


local function roomFilter() {
  return {
    size = [flex(), sh(6)]

    vplace = ALIGN_BOTTOM
    halign = ALIGN_RIGHT

    flow = FLOW_HORIZONTAL
    onDetach = @() nameFilter.update("")
    onAttach = @() nameFilter.update("")
    children = [
      {
        size = [pw(colWidths[0] * 1.5), SIZE_TO_CONTENT]
        margin = [0, hdpx(10), 0, 0]
        children = textInput.Underlined(nameFilter, {
          placeholder=::loc("search by name")
          font = Fonts.small_text
        }, {
          onEscape = function() {
            nameFilter.update("")
          }
        })
      }
    ]
  }
}

local function actionButtons() {
  local joinBtn
  if (selectedRoom.value) {
    joinBtn = textButton(::loc("Join"), doJoin, {hotkeys = [["^Enter"]]})
  }
  return {
    size = [SIZE_TO_CONTENT, sh(6.5)] //FIX ME: need button height here
    watch = [selectedRoom]

    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL

    children = [
      textButton(::loc("Find custom game"), findSomeMatch, {hotkeys=[["^J:Y"]]})
      textButton(::loc("Create game"), @() showCreateRoom.update(true), {hotkeys=[["^J:X | Enter"]]})
      checkBox(roomsListState.showForeignGames, ::loc("Show foreign games"))
      joinBtn
    ]
  }
}

local function roomsListScreen() {
  local children = null

  if (roomsListState.error.value) {
    children = [centeredText(::loc("error/{0}".subst(roomsListState.error.value)))]
  }
  else if (roomsListState.list.value.len()==0) {
    children = [centeredText(::loc("No custom games found")) actionButtons]
  }
  else {
    children = [
      listHeader
      roomsList
      {
        flow = FLOW_HORIZONTAL
        size = flex()
        children = [actionButtons, roomFilter]
      }
    ]
  }

  return {
    children = children
    size = flex()
    onAttach = function() {
      if (lobbyEnabled)
        roomsListState.refreshEnabled.update(true)
    }
    onDetach = @() roomsListState.refreshEnabled.update(false)

    watch = [
      roomsListState.list
      roomsListState.error
      roomsListState.isRequestInProgress
    ]
  }
}

local function root() {
  local children = showCreateRoom.value ?  createRoom : roomsListScreen
  return {
    size = [sw(80), flex()]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(100,100,100,255)
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    padding = hdpx(5)
    key = "rooms-list"

    children = children
    watch = showCreateRoom
  }
}

return root
 