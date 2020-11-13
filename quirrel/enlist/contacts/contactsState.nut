local charClient = require("enlist/charClient.nut")
local mailboxState = require("enlist/mailboxState.nut")
local Contact = require("contact.nut")
local userInfo = require("enlist/state/userInfo.nut")
local matchingCli = require("enlist/matchingClient.nut")
local matching_api = require("matching.api")
local msgbox = require("enlist/components/msgbox.nut")
local validateNickNames = require("enlist/contacts/validateNickNames.nut")
local platform = require("globals/platform.nut")
local ps4state = platform.is_sony ? require("enlist/ps4/state.nut") : null
local { get_app_id } = require("app")
local blacklist = require("globals/blacklist.nut")
local isOnlineContactsSearchEnabled = Watched(platform.is_pc || platform.is_nswitch)
local isContactsEnabled = Watched(platform.is_pc || platform.is_sony || platform.is_nswitch)
local isContactsVisible = persist("isContactsVisible", @() Watched(false))

local isContactsManagementEnabled = Watched(platform.is_pc || platform.is_nswitch)

const ADD_MODE = "add"
const DEL_MODE = "del"

userInfo.subscribe(function(uInfo) {
  if (uInfo?.userIdStr)
    Contact.make(uInfo.userIdStr, uInfo.name)
})

local sort_contacts = @(a, b) b.online.value <=> a.online.value
  || a.nick.value.tolower() <=> b.nick.value.tolower()

enum GROUPS {
  NONE           = 0x0000
  FRIEND         = 0x0001
  BLACKLIST      = 0x0002
  MY_REQUEST     = 0x0004
  REQUEST_TO_ME  = 0x0008
  REJECTED_BY_ME = 0x0010
  MY_REJECTED    = 0x0020
  APPROVED       = 0x0040
}

const GAME_GROUP_NAME = "Enlisted"

local contacts = persist("contacts", @() Watched([]))
local searchResults = persist("searchResults", @() Watched([]))

local listIds = ["approved", "myRequests", "requestsToMe", "rejectedByMe", "myBlacklist"]
local lists = {}

listIds.map(function (name) {
  console_print($"registerList {name}")
  lists[name] <- {
    list = persist($"list__{name}", @() Watched([]))
    mask = GROUPS.NONE
  }
})

lists["approved"].mask = GROUPS.APPROVED
lists["myRequests"].mask = GROUPS.MY_REQUEST
lists["myBlacklist"].mask = GROUPS.BLACKLIST
lists["requestsToMe"].mask = GROUPS.REQUEST_TO_ME
lists["rejectedByMe"].mask = GROUPS.REJECTED_BY_ME

// forward declarations
local addContactLocal = null
local fetchContacts = null
local removeContactLocal = null


local function execCharAction(contact, charAction) {
  contact.groupsMask.update(GROUPS.NONE)
  charClient[charAction](contact.userId.tointeger(), GAME_GROUP_NAME, {
    success = function () {
      fetchContacts(null)
    }

    failure = function (err) {
      msgbox.show({
        text = ::loc(err)
      })
    }
  })
}


local function buildFullListName(name) {
  return $"#{GAME_GROUP_NAME}#{name}"
}

local function onNotifyListChanged(body, mark_read) {
  local changed = body?.changed

  if (changed != null) {
    local perUidList = {}
    local function handleList(changedListObj, mode, listName) {
      if (mode in changedListObj) {
        local list = changedListObj[mode]
        foreach (uid in list) {
          if (!(uid in perUidList))
            perUidList[uid] <- {}
          perUidList[uid][mode] <- { listName = listName }
        }
      }
    }

    foreach (name, value in lists) {
      if (typeof changed != "table")
        continue

      local listName = buildFullListName(name)
      if (listName in changed) {
        local changedListObj = changed[listName]
        console_print(changedListObj)
        handleList(changedListObj, ADD_MODE, name)
        handleList(changedListObj, DEL_MODE, name)
      }
    }

    local function defaultOnShow(remove_notify) {
      mark_read()
      remove_notify()
    }


    foreach (_uid, _data in perUidList) {
      local uid = _uid
      local data = _data
      local contact = Contact.get($"{uid}")
      validateNickNames([contact], function() {

        local notification = null
        if (data?[ADD_MODE]?.listName == "requestsToMe") {
          notification = {
            styleId = "primary"
            text = ::Computed(@() ::loc("contact/incomingInvitation", { user = contact.nick.value }))
            onShow = function (remove_notify) {
              mark_read()
              msgbox.show({
                text = ::Computed(@() ::loc("contact/mbox_add_to_friends", { user = contact.nick.value }))
                buttons = [
                  { text = ::loc("Yes"), action = @() execCharAction(contact, "contacts_approve_request"), isCurrent = true }
                  { text = ::loc("No"), action = @() execCharAction(contact, "contacts_reject_request"), isCancel = true }
                ]
              })
              remove_notify()
            }
            onRemove = mark_read
          }
        }
  /*
        else if (data?[DEL_MODE]?.listName == "requestsToMe") {
          notification = {
            text = ::Computed(@() $"{contact.nick.value} have revoked his invitation")

            onShow = defaultOnShow
            isRead = true
            onRemove = mark_read
          }
        }
  */
        else if (data?[DEL_MODE]?.listName == "approved") {
          notification = {
            text = ::Computed(@() ::loc("contact/removedYouFromFriends", { user = contact.nick.value }))

            onShow = defaultOnShow
            isRead = true
            onRemove = mark_read
          }
        }
        if (contact != null && notification!=null) {
          contact.nick.trigger()
          mailboxState.pushNotification(notification)
        }
      })
    }
  }
}

local function removeContact(contact) {
  if (!removeContactLocal(contact))
    return
  charClient.contacts_remove(contact.userId.tointeger(), {
    success = function () {
      fetchContacts(null)
    }
    failure = (@(err) addContactLocal(contact))
  })
}

local function addContactLocalToGroup(contactGroup, contact, needTrigger = true, addMask = GROUPS.NONE) {
  local contactIdx = contactGroup.value.indexof(contact)
  if (contactIdx != null)
    return false

  contactGroup.value.append(contact)
  contactGroup.value.sort(sort_contacts)
  contact.groupsMask.update(contact.groupsMask.value | addMask)
  if (needTrigger)
    contactGroup.trigger()
  return true
}

addContactLocal = function(contact, needTrigger = true) {
  return addContactLocalToGroup(contacts, contact, needTrigger, GROUPS.FRIEND)
}

removeContactLocal = function(contact, needTrigger = true) {
  local contactIdx = contacts.value.indexof(contact)
  if (contactIdx == null)
    return false
  contacts.value.remove(contactIdx)
  contact.presences({})
  contact.groupsMask.update(contact.groupsMask.value & ~GROUPS.FRIEND)
  if (needTrigger)
    contacts.trigger()
  return true
}


local function updatePresences(new_presences) {
  console_print("updatePresences")
  foreach (p in new_presences) {
    if (p.userId == (userInfo.value?.userIdStr ?? ""))
      continue

    local contact = Contact.make(p.userId, p.nick)
    local presences = p.presences
    contact.presences(!p?.update ? presences : function(curPr) { curPr.__update(presences) })
  }

  local ls = [lists["approved"].list, contacts]
  foreach (l in ls) {
    l.update(@(value) value.sort(sort_contacts))
  }
}

local function updateGroup(new_contacts, groupList, groupName, addMask = GROUPS.NONE) {
  local members = new_contacts?[groupName] ?? []
  local hasListChanges = groupList.value.len() > 0

  foreach (c in groupList.value) {
    c.groupsMask.update(c.groupsMask.value & ~addMask)
  }

  groupList.value.clear()

  foreach(member in members) {
    local contact = Contact.make(member.userId, member.nick)
    if (addContactLocalToGroup(groupList, contact, false, addMask))
      hasListChanges = true
  }
  return hasListChanges
}

local function updateAllLists(new_contacts) {
  foreach (name, value in lists) {
    local list = value.list
    if (updateGroup(new_contacts, list, buildFullListName(name), value.mask)) {
      list.update(@(val) val.sort(sort_contacts))
    }
  }
}

local function onUpdateContactsCb(result) {
  if ("groups" in result) {
    updateAllLists(result.groups)
  }

  if ("presences" in result) {
    log(result.presences)
    updatePresences(result.presences)
  }
}

fetchContacts = function (postFetchCb) {
  matchingCli.call("mpresence.reload_contact_list", function(result) {
    onUpdateContactsCb(result)
    if (postFetchCb != null)
      postFetchCb()
  })
}

local function searchByExternalId(external_id, external_id_type, callback) {
  local request = {
    externalIdList = [external_id]
    externalIdType = external_id_type
    maxCount = 1
  }
  charClient.char_request(
    "cln_find_users_by_external_id_list",
    request,
    function (result) {
      if (!(result?.result?.success ?? true)) {
        if (callback)
          callback(null)
        return
      }

      local myUserId = userInfo.value?.userIdStr ?? ""
      local resContacts = []
      foreach(uidStr, name in result)
        if ((typeof name == "string") && uidStr != myUserId && uidStr != "") {
          local a
          try {
            a = uidStr.tointeger()
          } catch(e){
            print($"uid is not an integer, uid: {uidStr}")
          }
          if (a!=null)
            resContacts.append(Contact.make(uidStr, name))
        }
      if (callback)
        callback(resContacts)
    }
  )
}


local function searchOnline(nick, callback = null) {
  local request = {
    nick = nick
    maxCount = 100
    ignoreCase = true
    specificAppId = get_app_id()
  }
  log(request)
  charClient.char_request(
    "cln_find_users_by_nick_prefix_json",
    request,
    function (result) {
      if (!(result?.result?.success ?? true)) {
        searchResults.update(@(val) val.clear())
        if (callback)
          callback()
        return
      }

      local myUserId = userInfo.value?.userIdStr ?? ""
      local resContacts = []
      foreach(uidStr, name in result)
        if ((typeof name == "string") && uidStr != myUserId && uidStr != "") {
          local a
          try {
            a = uidStr.tointeger()
          } catch(e){
            print($"uid is not an integer, uid: {uidStr}")
          }
          if (a!=null)
            resContacts.append(Contact.make(uidStr, name))
        }
      searchResults.update(resContacts)
      if (callback)
        callback()
    }
  )
}

local offLineSearchParams = Watched(null)
local function searchOffline(nick, callback = null) {
  offLineSearchParams(nick.len() > 0 ? { nick = nick, callback = callback } : null)
}

local isApproved = @(contact) (contact.groupsMask.value & GROUPS.APPROVED) != 0
local isFriend = @(contact) (contact.groupsMask.value & GROUPS.FRIEND) != 0
local isFriendOrApproved = @(contact) (contact.groupsMask.value & (GROUPS.FRIEND|GROUPS.APPROVED)) != 0
local isBlacklisted = @(contact) (contact.groupsMask.value & GROUPS.BLACKLIST) != 0

local allowToBlacklist = @(contact) (contact.groupsMask.value & GROUPS.BLACKLIST) == 0 &&
                               (contact.groupsMask.value & GROUPS.APPROVED) == 0

local allowToApprove = @(contact) (contact.groupsMask.value & (GROUPS.REQUEST_TO_ME|GROUPS.REJECTED_BY_ME)) != 0

local isMyRequests  = @(contact) (contact.groupsMask.value & GROUPS.MY_REQUEST) != 0

local isRequestToMe = @(contact) (contact.groupsMask.value & GROUPS.REQUEST_TO_ME) != 0

local allowToRequest = @(contact) (contact.groupsMask.value & GROUPS.BLACKLIST) == 0 &&
                            (contact.groupsMask.value & GROUPS.APPROVED) == 0 &&
                            (contact.groupsMask.value & GROUPS.MY_REQUEST) == 0 &&
                            (contact.groupsMask.value & GROUPS.REJECTED_BY_ME) == 0 &&
                            (contact.groupsMask.value & GROUPS.REQUEST_TO_ME) == 0


if (platform.is_pc || platform.is_nswitch) {
  matching_api.subscribe("mpresence.notify_presence_update", onUpdateContactsCb)
  mailboxState.onNewMail.subscribe(
    function(mail_obj) {
      if (mail_obj.mail?.subj == "notify_contacts_update") {
        local function handleMail() {
          console_print(mail_obj.mail.body)
          onNotifyListChanged(mail_obj.mail.body, function() {
            matchingCli.call("postbox.notify_read", function(...) {},
                                  {mail_id = mail_obj.mail_id})
          })
        }
        fetchContacts(handleMail)
      }
    })

  lists.myBlacklist.list.subscribe(@(newList) blacklist(function(bl) {
    bl.clear()
    foreach(user in newList)
      bl[user.uid] <- true
  }))
}

if (platform.is_sony) {
  local function updatePS4Friends(friends) {
    local filtered = []
    foreach (entry in ps4state.friends.value) {
      if (offLineSearchParams.value == null || entry.nick.indexof(offLineSearchParams.value.nick) != null)
        filtered.append(entry)
    }
    updateAllLists({ ["#Enlisted#approved"] = filtered })
    updatePresences(filtered)
  }

  ps4state.friends.subscribe(updatePS4Friends)
  offLineSearchParams.subscribe(updatePS4Friends)
  ps4state.blocked.subscribe(@(newList) blacklist(function(bl) {
    bl.clear()
    foreach(u in newList)
      bl[u.userId.tointeger()] <- true
  }))
}

return {
  searchOnline
  contacts
  lists
  searchResults
  isOnlineContactsSearchEnabled
  isContactsEnabled
  isContactsManagementEnabled
  searchContacts = @(nick, callback = null) isOnlineContactsSearchEnabled.value ? searchOnline(nick, callback) : searchOffline(nick, callback)
  searchByExternalId

  isBlacklisted
  isFriendOrApproved
  isMyRequests
  isRequestToMe
  isApproved
  isFriend
  allowToRequest
  allowToApprove
  allowToBlacklist
  execCharAction
  removeContact
  isContactsVisible
  contactBlockExtensionCtr = ::Watched({})
}

 