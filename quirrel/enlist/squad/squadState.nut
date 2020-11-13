local string = require("string")
local frp = require("std/frp.nut")
local { debounce } = require("utils/timers.nut")
local { isEqual } = require("std/underscore.nut")
local { fabs } = require("math")
local mailboxState = require("enlist/mailboxState.nut")
local popupsState = require("enlist/popup/popupsState.nut")    // CODE SMELLS: ui state in logic module!
local contactsState = require("enlist/contacts/contactsState.nut")
local userInfo = require("enlist/state/userInfo.nut")
local Contact = require("enlist/contacts/contact.nut")
local validateNickNames = require("enlist/contacts/validateNickNames.nut")
local SquadMember = require("enlist/squad/squadMember.nut")
local MSquadAPI = require("squadAPI.nut")
local matchingCli = require("enlist/matchingClient.nut")
local matching_api = require("matching.api")
local msgbox = require("enlist/components/msgbox.nut")
local voiceState = require("enlist/voiceChat/voiceState.nut")
local chatApi = require("globals/chat/chatApi.nut")

local platform = require("globals/platform.nut")
local log = require("std/log.nut")().with_prefix("[SQUAD]")
local ps4session = (platform.is_sony ? require("enlist/ps4/session.nut") : null)
local ipc = require("ipc")

local enabled = Watched(true)
const INVITE_ACTION_ID = "squad_invite_action"
const INVITE_REJECT_ACTION_ID = "squad_invite_reject_action"
const SQUAD_OVERDRAFT = 0

local availableMaxMembers = Watched(1)

local function makeSharedData(persistId) {
  local res = {}
  foreach(key in ["clusters", "squadChat"])
    res[key] <- persist(persistId + key, @() Watched(null))
  return res
}

local squadId = persist("squadId", @() Watched(null))
local members = persist("members", @() Watched({}))
local invited = persist("invited", @() Watched({}))
local autoSquad = persist("autoSquad", @() Watched(true))
local sharedData = makeSharedData("sharedData")
local serverSharedData = makeSharedData("serverSharedData")
local delayedInvites = persist("delayedInvites", @() Watched(null))
local isDataInited = persist("inited", @() Watched(false))
local allMembersState = persist("allMembersState", @() ::Watched({}))
local squadChatJoined = persist("squadChatJoined", @() Watched(false))

local myExtData = {}
local myExtDataRW = {}
local myDataRemote = persist("myDataRemoteWatch", @() ::Watched({}))
local myDataLocal = ::Watched({})

local totalPossibleMembersNum = ::Computed(@()
  ::max(1, members.value.len() + invited.value.len())) //not in squad is 1 member, not 0

local selfUid = ::Computed(@() userInfo.value?.userId ?? null)

local selfMember = ::Computed(@() members.value?[selfUid.value])

local voiceChatId        = @(s) string.format("squad-channel-%X", s)
local leader             = ::Computed(@() squadId.value == selfUid.value)
local inSquad            = ::Computed(@() squadId.value != null)
local canInviteToSquad   = ::Computed(@() enabled.value && (!inSquad.value || leader.value))
local isLeavingWillDisband = ::Computed(@() members.value.len() == 1 || (members.value.len() + invited.value.len() <= 2))
local onlineMembers      = ::Computed(@() members.value.filter(@(m) m.contact.online.value))
local leaderState        = ::Computed(@() allMembersState.value?[squadId.value])

squadId.subscribe(function(val) {
  isDataInited(false)
  if (val != null)
    voiceState.join_voice_chat(voiceChatId(val))
})
members.subscribe(@(list) validateNickNames(list.map(@(m) m.contact)))
invited.subscribe(@(list) validateNickNames(list))

local getSquadInviteUid = @(inviterSquadId) "".concat("squad_invite_", inviterSquadId)

local notifyMemberAdded = []
local notifyMemberRemoved = []

local function sendEvent(handlers, val) {
  foreach (h in handlers)
    h(val)
}

local function isFloatEqual(a, b, eps = 1e-6) {
  local absSum = fabs(a) + fabs(b)
  return absSum < eps ? true : fabs(a - b) < eps * absSum
}

local isEqualWithFloat = @(v1, v2) isEqual(v1, v2, { float = isFloatEqual })

local updateMyData = debounce(function() {
  if (selfMember.value == null)
    return //no need to try refresh when no self member

  local needSend = myDataLocal.value.findindex(@(value, key) !isEqualWithFloat(myDataRemote.value?[key], value)) != null
  if (needSend) {
    log("update my data: ", myDataLocal.value)
    MSquadAPI.setMemberData(myDataLocal.value)
  }
}, 0.1)

frp.subscribe([selfMember, myDataLocal, myDataRemote], @(_) updateMyData())

local function linkVarToMsquad(name, var) {
  myDataLocal[name] <- var.value
  var.subscribe(@(val) myDataLocal[name] <- val)
}

linkVarToMsquad("name", keepref(::Computed(@() userInfo.value?.name))) //always set

local function bindROVar(name, var) {
  myExtData[name] <- var
  linkVarToMsquad(name, var)
}

local function bindRWVar(name, var) {
  myExtData[name] <- var
  myExtDataRW[name] <- var
  linkVarToMsquad(name, var)
}

local function setSelfRemoteData(member_data) {
  myDataRemote(clone member_data)
  foreach (k, v in member_data) {
    if (k in myExtDataRW) {
      myExtDataRW[k].update(v)
    }
  }
}

local function subscribeSquadMember(member) {
  // add remote state change triggers here
  member.addSubscription("online", member.contact.online, @(v) members.trigger()) // -> onlineMembers
  allMembersState[member.userId] <- member.state.value
  member.addSubscription("memberData", member.state, @(v) allMembersState[member.userId] <- v) //!!FIX ME: States must be store in allMembersState by default, and only computed version in member
}

foreach(key, oldMember in members.value) {
  //script reload
  oldMember.clearSubscriptions()
  local newMember = SquadMember(oldMember.userId, squadId).setBySquadMember(oldMember)
  members.value[key] = newMember
  subscribeSquadMember(newMember)
}

local function reset() {
  if (squadId.value >= 0)
    voiceState.leave_voice_chat(voiceChatId(squadId.value))
  squadId.update(null)
  invited.update({})
  allMembersState.update({})

  if (sharedData.squadChat.value != null) {
    squadChatJoined(false)
    chatApi.leaveChat(sharedData.squadChat.value?.chatId, null)
  }

  foreach(w in sharedData)
    w.update(null)
  foreach(w in serverSharedData)
    w.update(null)

  foreach(member in members.value) {
    member.onRemove()
    sendEvent(notifyMemberRemoved, member.userId)
  }
  members.update({})
  delayedInvites(null)

  myExtData.ready(false)
  myDataRemote({})
}

local function removeInvited(user_id) {
  if (!(user_id in invited.value))
    return false
  invited.update(@(value) delete value[user_id])
  return true
}

local function addInvited(user_id) {
  if (user_id in invited.value)
    return false
  invited.update(@(value) value[user_id] <- Contact.get(user_id.tostring()))
  return true
}

local function applySharedData(dataTable) {
  if (!inSquad.value)
    return

  foreach(key, w in serverSharedData)
    if (key in dataTable)
      w.update(dataTable[key])

  if (!leader.value)
    foreach(key, w in sharedData)
      w.update(serverSharedData[key].value)
}

local requestMemberData = @(uid, isMe,  isNewMember, cb = @(res) null)
  MSquadAPI.getMemberData(uid,
    { onSuccess = function(response) {
        local member = members.value?[uid]
        if (member) {
          local data = member.applyRemoteData(response)
          if (isMe && data)
            setSelfRemoteData(data)
          if (isNewMember) {
            subscribeSquadMember(member)
            sendEvent(notifyMemberAdded, uid)
          }
        }
        members.trigger()
        cb(response)
      }
    })

local function updateSquadInfo(squad_info) {
  if (squadId.value != squad_info.id)
    return

  foreach (uid in squad_info.members) {
    local isNewMember = false
    local isMe = (uid == selfUid.value)
    if (!(uid in members.value)) {
      local sMember = SquadMember(uid, squadId)
      members.value[uid] <- sMember
      removeInvited(uid)
      isNewMember = true
      if (isMe) {
        requestMemberData(uid, isMe, isNewMember)
        continue
      }
    }

    requestMemberData(uid, isMe, isNewMember)
  }
  members.trigger()

  foreach(uid in squad_info?.invites ?? [])
    addInvited(uid)

  if (squad_info?.data)
    applySharedData(squad_info.data)

  isDataInited(true)
}

local function checkDisbandEmptySquad() {
  if (members.value.len() == 1 && !invited.value.len())
    MSquadAPI.disbandSquad()
}

local function revokeInvite(user_id) {
  if (!removeInvited(user_id))
    return

  MSquadAPI.revokeInvite(user_id)
  checkDisbandEmptySquad()
}

local function revokeAllInvites() {
  foreach(userId, contact in invited.value)
    revokeInvite(userId)
}

local function leaveSquadImpl(cb = null) {
  if (!inSquad.value) {
    cb?()
  }
  if (members.value.len() == 1)
    revokeAllInvites()
  ps4session?.leave?()
  MSquadAPI.leaveSquad({ onAnyResult = function(...) {
    reset()
    cb?()
  } })
}

local showSizePopup = @(text, isError = true)
    popupsState.addPopup({ id = "squadSizePopup", text = text, styleName = isError ? "error" : "" })

local fetchSquadInfo = null

local function acceptInviteImpl(invSquadId) {
  MSquadAPI.acceptInvite(invSquadId,
      { onSuccess = function(...) {
          squadId.update(invSquadId)
          fetchSquadInfo()
        }
        onFailure = function(resp) {
          msgbox.show({ text = ::loc(
            "".concat("squad/nonAccepted/", (resp?.error_id ?? "")),
            ": ".concat(::loc("squad/inviteError"), (resp?.error_id ?? ""))) })

          ipc.send({ msg = "ipc.squadIsFull", data = { } })
          ps4session?.leave?()
        }
      })
}

local function acceptInvite(invSquadId) {
  if (!inSquad.value)
    acceptInviteImpl(invSquadId)
  else
    leaveSquadImpl(@() acceptInviteImpl(invSquadId))
}

local persistActions = persist("persistActions", @() {})

local function processSquadInvite(contact) {
  // we are already in that squad. do nothing
  if (inSquad.value && squadId.value == contact.uid) {
    return
  }

  // always accept invites on xboxone
  if (platform.is_xbox) {
    acceptInvite(contact.uid)
    return
  }

  local onShow = @() persistActions[INVITE_ACTION_ID]({ uid = contact.uid })
  local onRemove = @() persistActions[INVITE_REJECT_ACTION_ID]({ uid = contact.uid })
  mailboxState.pushNotification({
    id = getSquadInviteUid(contact.uid)
    styleId = "toBattle"
    text = ::loc("squad/invite", {playername=contact.nick.value})
    onShow = function (remove_notify) {
      remove_notify()
      onShow()
    }
    onRemove = onRemove
    needPopup = true
  })
}

local function onInviteRevoked(inviterSquadId, invitedMemberId) {
  if (inviterSquadId == squadId.value)
    removeInvited(invitedMemberId)
  else
    mailboxState.removeNotification(getSquadInviteUid(inviterSquadId))
}

local function addInviteByContact(inviter) {
  if (inviter.uid == selfUid.value) // skip self invite
    return

  if (contactsState.isBlacklisted(inviter)) {
    log("got squad invite from blacklisted user" inviter)
    MSquadAPI.rejectInvite(inviter.uid)
  }
  else {
    processSquadInvite(inviter)
  }
}

local function onInviteNotify(invite_info) {
  if ("invite" in invite_info) {
    local inviter = Contact.get(invite_info?.leader.id.tostring(), invite_info?.leader.name)

    if (invite_info.invite.id == selfUid.value)
      addInviteByContact(inviter)
    else
      addInvited(invite_info.invite.id)
  }
  else if ("replaces" in invite_info) {
    onInviteRevoked(invite_info.replaces, selfUid.value)
    addInviteByContact(Contact.get(invite_info?.leader.id.tostring()))
  }
}


fetchSquadInfo = function(cb = null) {
  MSquadAPI.getSquadInfo({
    onAnyResult = function (result) {
      if (result.error != 0) {
        if (result?.error_id == "NOT_SQUAD_MEMBER")
          squadId.update(null)
        if (cb)
          cb(result)
        return
      }

      if ("squad" in result) {
        squadId.update(result.squad.id)
        updateSquadInfo(result.squad)
        if (cb)
          cb(result)
      }

      local validateList = (result?.invites ?? []).map(@(id) Contact.get(id.tostring()))

      validateNickNames(validateList, function() {
        foreach (sender in validateList)
        addInviteByContact(sender)
      })
    }
  })
}

local function onMemberDataChanged(user_id, request) {
  local member = members.value?[user_id]
  if (member == null)
    return

  local data = member.applyRemoteData(request)
  local isMe = (user_id == selfUid.value)
  if (isMe && data)
    setSelfRemoteData(data)
  subscribeSquadMember(member)
}

local function addMember(member) {
  local userId = member.userId
  log("addMember", userId, member.name)

  local squadMember = SquadMember(member.userId, squadId)
  squadMember.contact.realnick(member.name)
  squadMember.setOnline(true)
  removeInvited(member.userId)

  members.update(@(val) val[userId] <- squadMember)
  sendEvent(notifyMemberAdded, userId)

  if (members.value.len() == availableMaxMembers.value && invited.value.len() > 0 && leader.value) {
    revokeAllInvites()
    showSizePopup(::loc("squad/squadIsReadyExtraInvitesRevoken"))
  }
}

local function removeMember(member) {
  local userId = member.userId

  if (userId == selfUid.value) {
    msgbox.show({
        text = ::loc("squad/kickedMsgbox")
      })
    reset()
  }
  else if (userId in members.value) {
    members.value[userId].onRemove()
    if (userId in members.value) //function above can clear userid
      delete members.value[userId]
    members.trigger()
    sendEvent(notifyMemberRemoved, userId)
    checkDisbandEmptySquad()
  }
}

  // public methods
local function leaveSquad() {
  msgbox.show({
    text = ::loc("squad/leaveSquadQst")
    buttons = [
      { text = ::loc("Yes"), action = @() leaveSquadImpl() }
      { text = ::loc("No") }
    ]
  })
}

local function dismissMember(user_id) {
  local member = members.value?[user_id]
  if (!member)
    return
  msgbox.show({
    text = ::loc("squad/kickPlayerQst", { name = member.contact.nick.value })
    buttons = [
      { text = ::loc("Yes"), action = @() MSquadAPI.dismissMember(user_id) }
      { text = ::loc("No"), isCancel = true, isCurrent = true }
    ]
  })
}

local function dismissAllOffline() {
  if (!leader.value)
    return
  foreach(member in members.value)
    if (!member.contact.online.value)
      MSquadAPI.dismissMember(member.userId)
}

local function transferSquad(user_id) {
  local is_leader = leader.value
  MSquadAPI.transferSquad(user_id,
  {
    onSuccess = function(r) {
      squadId.update(user_id)
      if (is_leader) {
        ps4session?.update_data?(user_id)
      }
    }
  })
}

local function inviteToSquad(user_id) {
  if (inSquad.value) {
    if (user_id in members.value) // user already in squad
      return

    if (members.value.len() >= availableMaxMembers.value)
      return showSizePopup(::loc("squad/popup/squadFull"))
    else if (members.value.len() + invited.value.len() >= availableMaxMembers.value + SQUAD_OVERDRAFT)
      return showSizePopup(::loc("squad/popup/tooManyInvited"))
  }

  local _doInvite = function() {
    MSquadAPI.invitePlayer(user_id, {
      onFailure = function(resp) {
        showSizePopup(::loc("".concat("error/", (resp?.error_id ?? ""))), false)
      }
    })
  }

  local doInvite = _doInvite
  if (platform.is_sony) {
    doInvite = @() ps4session.invite(user_id, _doInvite)
  }

  if (delayedInvites.value != null) { // squad is creating now
    delayedInvites(@(inv) inv.append(doInvite))
    return
  }

  if (!inSquad.value) {
    delayedInvites([doInvite])

    local inviteDelayed = function() {
      if (delayedInvites.value == null)
        return
      foreach (f in delayedInvites.value)
        f()
      delayedInvites(null)
    }

    local cleanupDelayed = @() delayedInvites(null)

    MSquadAPI.createSquad({
      onSuccess = @(r)
        fetchSquadInfo(
          function(r) {
            if (r.error != 0) {
              cleanupDelayed()
              return
            }
            if (platform.is_sony) {
              ps4session.create(squadId.value, inviteDelayed)
            }
            else
              inviteDelayed()

            chatApi.createChat(function(chat_resp) {
              if (chat_resp.error == 0) {
                squadChatJoined(true)
                sharedData.squadChat({
                  chatId = chat_resp.chatId
                  chatKey = chat_resp.chatKey
                })
              }
            })
          }
        )
      onFailure = @(r) cleanupDelayed()
    })
  }
  else
    doInvite()
}

local isSharedDataRequestInProgress = false
local function syncSharedDataImpl() {
  local function isSharedDataDifferent() {
    foreach(key, w in sharedData)
      if (w.value != serverSharedData[key].value)
        return true
    return false
  }

  if (isSharedDataRequestInProgress || !leader.value || !isSharedDataDifferent())
    return

  local thisFunc = callee()
  isSharedDataRequestInProgress = true
  local requestData = sharedData.map(@(w) w.value)
  MSquadAPI.setSquadData(requestData,
    { onSuccess = function(res) {
        isSharedDataRequestInProgress = false
        applySharedData(requestData)
        thisFunc()
      }
      onFailure = function(res) {
        isSharedDataRequestInProgress = false
      }
    })
}

local syncSharedDataTimer = null
local function syncSharedData(...) {
  if (syncSharedDataTimer || !leader.value)
    return
  //wait for more changes in shared data before sync it with server
  syncSharedDataTimer = function() {
    ::gui_scene.clearTimer(syncSharedDataTimer)
    syncSharedDataTimer = null
    syncSharedDataImpl()
  }
  ::gui_scene.setInterval(0.1, syncSharedDataTimer)
}

foreach(w in sharedData)
  w.subscribe(syncSharedData)

persistActions[INVITE_ACTION_ID] <- function(params) {
  local uid = params.uid
  msgbox.show({
    text = ::loc("squad/acceptInviteQst")
    buttons = [
      { text = ::loc("Yes"), isCurrent = true, action = @() acceptInvite(uid) }
      { text = ::loc("No"), isCancel = true, action = @() MSquadAPI.rejectInvite(uid) }
    ]
  })
}

persistActions[INVITE_REJECT_ACTION_ID] <- @(p) MSquadAPI.rejectInvite(p.uid)

local msubscribes = {
  ["msquad.notify_invite"] = onInviteNotify,
  ["msquad.notify_invite_revoked"] = function(params) {
    if (params?.squad?.id != null && params?.invite?.id != null)
      onInviteRevoked(params.squad.id, params.invite.id)
  },
  ["msquad.notify_invite_rejected"] = function(params) {
    if (leader.value) {
      local contact = Contact.get(params.invite.id.tostring())
      removeInvited(contact.uid)
      if (platform.is_xbox || platform.is_sony)
        return
      mailboxState.pushNotification({ text = ::loc("squad/mail/reject", {playername = contact.nick.value ?? "???" })})
    }
  },
  ["msquad.notify_invite_expired"] = @(params) removeInvited(params.invite.id),
  ["msquad.notify_disbanded"] = function(params) {
    ps4session?.leave?()
    if (!leader.value) {
      msgbox.show({text = ::loc("squad/msgbox_disbanded")})
    }
    reset()
  },
  ["msquad.notify_member_joined"] = addMember,
  ["msquad.notify_member_leaved"] = removeMember,
  ["msquad.notify_leader_changed"] = function(params) {
    squadId.update(params.userId)
    if (leader.value) {
      ps4session?.update_data?(params.userId)
    }
  },
  ["msquad.notify_data_changed"] = function(params){
    if (inSquad.value && !leader.value)
      fetchSquadInfo()
  },
  ["msquad.notify_member_data_changed"] = function(params) {
    MSquadAPI.getMemberData(params.userId,
        { onSuccess = @(response) onMemberDataChanged(params.userId, response) })
  },
  ["msquad.notify_member_logout"] = function(params) {
    local member = members.value?[params.userId]
    if (member!=null) {
      log(string.format("member %d going to offline", params.userId))
      member.setOnline(false)
      member.state.ready <- false
    }
  },
  ["msquad.notify_member_login"] = function(params) {
    local member = members.value?[params.userId]
    if (member){
      log("member", params.userId, "going to online")
      member.setOnline(true)
    }
  },
  ["msquad.notify_application"] = function(...) {},
  ["msquad.notify_application_revoked"] = function(...) {},
  ["msquad.notify_application_denied"] = function(...) {}
}

foreach(k, v in msubscribes)
  matching_api.subscribe(k, v)

matchingCli.connected.subscribe(function(value) {
  reset()
  if (value)
    fetchSquadInfo(@(val) log(val))
})

sharedData.squadChat.subscribe(function(value) {
  if (value != null && !squadChatJoined.value) {
    chatApi.joinChat(value?.chatId, value?.chatKey,
    function (resp) {
      if (resp.error == 0)
        squadChatJoined(false)
    })
  }
})

return {
  // state
  isSquadLeader = leader
  squadId = squadId
  isInSquad = inSquad
  squadMembers = members
  isInvitedToSquad = invited
  autoSquad = autoSquad
  enabledSquad = enabled
  isSquadDataInited = isDataInited
  totalPossibleSquadMembersNum = totalPossibleMembersNum
  isLeavingWillDisbandSquad = isLeavingWillDisband
  squadLeaderState = leaderState
  canInviteToSquad = canInviteToSquad
  availableSquadMaxMembers = availableMaxMembers
  squadSharedData = sharedData
  squadServerSharedData = serverSharedData
  squadOnlineMembers = onlineMembers
  myExtSquadData = myExtData
  squadSelfMember = selfMember
  bindSquadROVar = bindROVar
  bindSquadRWVar = bindRWVar


  // functions
  isInMySquad         = @(contact) members.value?[contact.userId.tointeger()] != null
  inviteToSquad = inviteToSquad
  dismissAllOfflineSquadmates = dismissAllOffline
  revokeAllSquadInvites = revokeAllInvites
  leaveSquad = leaveSquad
  leaveSquadSilent = leaveSquadImpl
  transferSquad = transferSquad
  dismissSquadMember = dismissMember

  removeInvitedSquadmate = removeInvited
  revokeSquadInvite = revokeInvite
  acceptSquadInvite = acceptInvite

  // events
  subsMemberAddedEvent = @(func) notifyMemberAdded.append(func)
  subsMemberRemovedEvent = @(func) notifyMemberRemoved.append(func)

  // utility
  voiceChatId = voiceChatId

  squadChat = sharedData.squadChat
}
 