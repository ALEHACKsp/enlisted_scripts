local dagor_sys = require("dagor.system")

local LobbyStatus  = require("enlist/lobbyStatusEnum.nut")
local userInfo = require("enlist/state/userInfo.nut")
local matchingCli = require("enlist/matchingClient.nut")
local clusterState = require("enlist/clusterState.nut")
local gameLauncher = require("enlist/gameLauncher.nut")
local matching_api = require("matching.api")
local matching_errors = require("matching.errors")
local roomSettings = require("enlist/roomSettings.nut")
local msgbox = require("ui/components/msgbox.nut")
local {isInQueue} = require("enlist/quickMatchQueue.nut")
local loginChain = require("enlist/login/login_chain.nut")
local {isCallable} = require("std/functools.nut")
local chatApi = require("globals/chat/chatApi.nut")
local chatState = require("globals/chat/chatState.nut")
local voiceState = require("enlist/voiceChat/voiceState.nut")

local room = persist("room" @() Watched(null))
local roomInvites = persist("roomInvites", @() Watched([]))
local roomMembers = persist("roomMembers", @() Watched([]))
local roomIsLobby = persist("roomIsLobby", @() Watched(false))
local connectAllowed = persist("connectAllowed", @() Watched(null))
local hostId  = persist("hostId", @() Watched(null))
local lobbyStatus = persist("lobbyStatus", @() Watched(LobbyStatus.ReadyToStart))
local {squadId} = require("enlist/squad/squadState.nut")
local chatId = persist("chatId", @() Watched(null))
local squadVoiceChatId = persist("squadVoiceChatId", @() Watched(null))


local lastRoomResult = ::Watched(null)

local function canOperateRoom() {
  if (userInfo.value==null || !roomMembers.value.len())
    return false
  foreach (member in roomMembers.value) {
    if (member.userId == userInfo.value?.userId) {
      return member?.public?.operator ?? false
    }
  }
  return false
}

local function getRoomMember(user_id) {
  foreach (idx, member in roomMembers.value)
    if (member.userId == user_id)
      return member
  return null
}

local function cleanupRoomState() {
  log("cleanupRoomState")
  room.update(null)
  roomInvites.update([])
  roomMembers.update([])
  roomIsLobby.update(false)
  hostId.update(null)
  connectAllowed.update(null)
  if (chatId.value != null) {
    chatApi.leaveChat(chatId.value, null)
    chatState.clearChatState(chatId.value)
    chatId(null)
  }

  if (squadVoiceChatId.value != null) {
    voiceState.leave_voice_chat(squadVoiceChatId.value)
    squadVoiceChatId(null)
  }
}

local function addRoomMember(member) {
  if (member.public?.host) {
    log("found host ", member.name,"(", member.userId,")")
    hostId.update(member.userId)
  }

  roomMembers.update(@(value) value.append(member))
}

local function removeRoomMember(user_id) {
  foreach (idx, member in roomMembers.value) {
    if (member.userId == user_id) {
      roomMembers.update(@(value) value.remove(idx))
      break
    }
  }

  if (user_id == hostId.value) {
    log("host leaved from room")
    hostId.update(null)
    connectAllowed.update(null)
  }

  if (user_id == userInfo.value?.userId)
    cleanupRoomState()
}

local function makeCreateRoomCb(user_cb) {
  return function(response) {
    if (response.error != 0) {
      log("failed to create room:", matching_errors.error_string(response.error))
    } else {
      roomIsLobby(true)
      room.update(response)
      log("you have created the room", response.roomId)
      foreach (member in response.members)
        addRoomMember(member)
    }

    if (squadId.value != null) {
      matchingCli.call("mrooms.set_member_attributes", null, {
                        public = {
                          squadId = squadId.value
                        }
                      })
    }

    if (user_cb)
      user_cb(response)
  }
}

local function createRoom(params, user_cb) {
  chatApi.createChat(function(chat_resp) {
    if (chat_resp.error == 0) {
      params.public.chatId <- chat_resp.chatId
      params.public.chatKey <- chat_resp.chatKey
      chatId(chat_resp.chatId)
    }
    matchingCli.call("mrooms.create_room", makeCreateRoomCb(user_cb), params)
  })
}

local function setMemberAttributes(params, user_cb) {
  matchingCli.call("mrooms.set_member_attributes", user_cb, params)
}

local function makeLeaveRoomCb(user_cb) {
  return function(response) {
    if (response.error != 0) {
      log("failed to leave room:", matching_errors.error_string(response.error))
      response.error = 0
      cleanupRoomState()
    }

    if (room.value) {
      log("you left the room", room.value.roomId)
    }

    if (user_cb)
      user_cb(response)
  }
}

local function leaveRoom(user_cb) {
  if (gameLauncher.gameClientActive.value) {
    if (user_cb != null)
      user_cb({error = "Can't do that while game is running"})
    return
  }

  matchingCli.call("mrooms.leave_room", makeLeaveRoomCb(user_cb))
}

local function destroyRoom(user_cb) {
  if (gameLauncher.gameClientActive.value) {
    if (user_cb != null)
      user_cb({error = "Can't do that while game is running"})
    return
  }

  matchingCli.call("mrooms.destroy_room", makeLeaveRoomCb(user_cb))
}

local function makeJoinRoomCb(lobby, user_cb) {
  return function(response) {

    if (response.error != 0) {
      log("failed to join room:", matching_errors.error_string(response.error))
    } else {
      roomIsLobby(lobby)

      room.update(response)
      local roomId = response.roomId
      log("you joined the room", roomId)
      foreach (member in response.members)
        addRoomMember(member)

      local newChatId = room.value?.public.chatId
      if (newChatId) {
        chatApi.joinChat(newChatId, room.value.public.chatKey,
        function(chat_resp) {
          if (chat_resp.error == 0)
            chatId(newChatId)
        })
      }

      local squadSelfMember = getRoomMember(userInfo.value?.userId)
      local selfSquadId = squadSelfMember?.public?.squadId
      if (selfSquadId != null) {
        squadVoiceChatId($"__squad_${selfSquadId}_room_${roomId}")
        voiceState.join_voice_chat(squadVoiceChatId.value)
      }
    }

    if (user_cb)
      user_cb(response)
  }
}

local function joinRoom(params, lobby, user_cb) {
  matchingCli.netStateCall(function() {
    matchingCli.call("mrooms.join_room", makeJoinRoomCb(lobby, user_cb), params)
  })
}

local function makeStartSessionCb(user_cb) {
  return function(response) {
    if (user_cb)
      user_cb(response)
  }
}

local function startSession(user_cb) {
  local params = {
    cluster = clusterState.oneOfSelectedClusters.value
  }
  matchingCli.call("mrooms.start_session", makeStartSessionCb(user_cb), params)
}

local function onRoomDestroyed(notify) {
  cleanupRoomState()
}

/*
  HERE STARTS VERY OBFUSCATED and BAD CODE
  The only purpose for it - to get async gameLaunchParams (signedItems for CR or alike)
  Correct way to do async data processing would be introducing state that is calculated from anything else
  and has a corresponding sessionId as key (Watched(?{sessionId = {gameLaunchParams = params, result="success", reason=null, timeRequested=<time>}})
  gameLaunch should wait for correct data in SessionID to launch (better limited in time) or cancel launch with error
  However that a "bit" more to change, and first of all I need to remove dependency of CR code in Enlisted
*/
local _beforeGameLaunchCbs = {callback = @(cb) cb({})}
local function setBeforeGameLaunchCb(cb){
  ::assert(isCallable(cb))
  _beforeGameLaunchCbs.callback = cb
}
local function gameLaunchParamsCb(extraGameLaunchParams) {
  if (!room.value) {
    log("ConnectToHost error: room leaved while wait for items sign")
    return
  }

  local launchParams = {
    host_urls = getRoomMember(hostId.value)?.public?.host_urls
    sessionId = room.value.public?.sessionId
    game = room.value.public?.gameName
    authKey = getRoomMember(userInfo.value?.userId)?.private?.auth_key
  }
  launchParams.each(function(val) {
    if (val == null){
      log("ConnectToHost error: some room params are incorrect:",val)
      return
    }
  })

  launchParams.__update(extraGameLaunchParams)

  local lastLoginTime = loginChain.loginTime.value
  room.gameStarted <- true
  lastRoomResult(null)
  gameLauncher.startGame(launchParams, function(isDisconnect) {
    leaveRoom(function(...){})
    local wasRelogin = lastLoginTime != loginChain.loginTime.value
    log($"gameLauncherCb isDisconnect = {isDisconnect}, wasRelogin = {wasRelogin}")
    if (wasRelogin)
      return

    if (!isDisconnect)
      // normal leave from session
      // so tell matchmaking we won't participate in that match anymore
      matchingCli.call("enlmm.remove_from_match", function(...){},
                       {sessionId = launchParams.sessionId})
    lastRoomResult({ isDisconnect = isDisconnect, sessionId = launchParams.sessionId })
  })
}


local function connectToHost() {
  if (hostId.value == null)
    return

  if (!connectAllowed.value) {
    msgbox.show({text=::loc("msgboxtext/connectNotAllowed")})
    return
  }
  _beforeGameLaunchCbs.callback(gameLaunchParamsCb)//@(cb) cb({})
}
//  HERE ENDS VERY OBFUSCATED and BAD CODE

local function onHostNotify(notify) {
  log(notify)
  if (notify.hostId != hostId.value) {
    log($"warning: got host notify from host that is not in current room {notify.hostId} != {hostId.value}")
    return
  }

  if (notify.roomId != room.value?.roomId) {
    log("warning: got host notify for wrong room")
    return
  }

  if (notify.message == "connect-allowed") {
    connectAllowed.update(true)
    connectToHost()
  }
}

local function onRoomMemberJoined(notify) {
  if (notify.roomId != room.value?.roomId)
    return
  log("{0} ({1}) joined to room".subst(notify.name, notify.userId))
  if (notify.userId != userInfo.value?.userId)
    addRoomMember(notify)
}

local function onRoomMemberLeft(notify) {
  if (notify.roomId != room.value?.roomId)
    return
  log("{0} ({1}) left from room".subst(notify.name, notify.userId))
  removeRoomMember(notify.userId)
}

local function onRoomMemberKicked(notify) {
  removeRoomMember(notify.userId)
}

local function merge_attribs(upd_data, attribs) {
  foreach (key, value in upd_data) {
    if (value == null) {
      if (key in attribs)
        delete attribs[key]
    }
    else
      attribs[key] <- value
  }
}

local function onRoomAttrChanged(notify) {
  local roomVal = room.value
  local pub = notify?.public
  local priv = notify?.private

  if (typeof pub == "table")
    merge_attribs(pub, roomVal.public)
  if (typeof priv == "table")
    merge_attribs(priv, roomVal.private)

  room.trigger()
}

local function onRoomMemberAttrChanged(notify) {
  local member = getRoomMember(notify.userId)
  if (!member)
    return
  local pub = notify?["public"]
  local priv =notify?["private"]
  if (typeof pub == "table")
    merge_attribs(pub, member.public)
  if (typeof priv == "table")
    merge_attribs(priv, member.private)

  // maybe watched array 'members' should be replaced by array of watched
  // to reduce UI update on attributes sync
  roomMembers.trigger()
}


local function onRoomInvite(request, send_resp) {
  roomInvites.value.append({
    roomId = request.roomId
    senderId = request.invite_data.senderId
    senderName = request.invite_data.senderName
    send_resp = send_resp
  })

  log("got room invite from", request.invite_data.senderName)
}

local function onMatchInvite(request, send_resp) {
  log("got match invite from server")
  joinRoom(request, false, function(cb) {})
}

local function updateLobbyStatus(...) {
  local function getRoomMembersCnt() {
    if (!roomMembers.value)
      return 0
    return roomMembers.value.len()
  }
  local function allowToStartSession() {
    local minPlayersToStart = roomSettings.minPlayers.value
    if (dagor_sys.DBGLEVEL > 0)
      minPlayersToStart = 1
    return hostId.value == null && getRoomMembersCnt() >= minPlayersToStart
  }

  if (hostId.value == null){
    if (allowToStartSession())
      lobbyStatus.update(LobbyStatus.ReadyToStart)
    else
      lobbyStatus.update(LobbyStatus.NotEnoughPlayers)
  }
  else {
    if (!connectAllowed.value)
      lobbyStatus.update(LobbyStatus.CreatingGame)
    else{
      if (gameLauncher.gameClientActive.value)
        lobbyStatus.update(LobbyStatus.GameInProgress)
      else
        lobbyStatus.update(LobbyStatus.GameInProgressNoLaunched)
    }
  }
}

{
  [gameLauncher.gameClientActive, hostId, roomMembers, connectAllowed].each(@(v) v.subscribe(updateLobbyStatus))
}

local function list_invites(){
  foreach (i, invite in roomInvites){
    log(
      "{0} from {1} ({2}), roomId {3}".subst(
        i, invite.senderName, invite.senderId, invite.roomId))
  }
}


local gameIsLaunching = Computed(@() !((roomIsLobby.value || !room.value) && !isInQueue.value))

console.register_command(list_invites, "mrooms.list_invites")

matching_api.subscribe("mrooms.on_room_invite", onRoomInvite)
matching_api.subscribe("enlmm.on_room_invite", onMatchInvite)

// mrooms notifications
matching_api.subscribe("mrooms.on_room_member_joined", onRoomMemberJoined)
matching_api.subscribe("mrooms.on_room_member_leaved", onRoomMemberLeft)
matching_api.subscribe("mrooms.on_room_attributes_changed", onRoomAttrChanged)
matching_api.subscribe("mrooms.on_room_member_attributes_changed", onRoomMemberAttrChanged)
matching_api.subscribe("mrooms.on_room_destroyed", onRoomDestroyed)
matching_api.subscribe("mrooms.on_room_member_kicked", onRoomMemberKicked)
matching_api.subscribe("mrooms.on_host_notify", onHostNotify);

matchingCli.connected.subscribe(function(connected) {
  if (!connected) {
    cleanupRoomState()
  }
})

local allowReconnect = persist("allowReconnect", @() Watched(true))

return {
  room
  roomInvites
  roomMembers
  roomIsLobby
  lobbyStatus
  lastRoomResult

  chatId

  setMemberAttributes
  createRoom
  joinRoom
  leaveRoom
  startSession
  destroyRoom
  connectToHost
  canOperateRoom
  gameIsLaunching

  allowReconnect

  setBeforeGameLaunchCb = setBeforeGameLaunchCb //FIXME: VERY BAD IDEA - SEE ABOVE
  _beforeGameLaunchCbs = _beforeGameLaunchCbs //FIXME: VERY BAD IDEA - SEE ABOVE
}
 