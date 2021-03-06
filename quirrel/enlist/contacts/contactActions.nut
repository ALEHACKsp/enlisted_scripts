local fa = require("daRg/components/fontawesome.map.nut")
local contactsState = require("contactsState.nut")
local {squadMembers, canInviteToSquad, isInvitedToSquad, inviteToSquad, enabledSquad,
    dismissSquadMember, isSquadLeader, isInMySquad, transferSquad, revokeSquadInvite,
    isInSquad, leaveSquad} = require("enlist/squad/squadState.nut")
local userInfo = require("enlist/state/userInfo.nut")
local {maxSquadSize} = require("enlist/quickMatchQueue.nut")
local openUrl = require("enlist/openUrl.nut")
local {appId} = require("enlist/state/clientState.nut")
local platform = require("globals/platform.nut")
local ipcSend = require("ipc").send
local {isContactsManagementEnabled} = contactsState

/*************************************** ACTIONS LIST *******************************************/
/*
!!!TODO!!!!
isVisible and getWatch is BAD
make isVisible and calculated observable that is just frp.combine of watches - and that's all
to do this we need to refactor contacts first, to make it list\table of observables or just one observable list
*/


local function isMe(contact) {return contact.userId == (userInfo.value?.userIdStr ?? "")}

local actions = {
  INVITE_TO_SQUAD = {
    locId = "Invite to squad"
    icon = fa["handshake-o"]
    isVisible   = @(contact) !isMe(contact) && canInviteToSquad.value && !isInMySquad(contact)
      && maxSquadSize.value > 1
      && !isInvitedToSquad.value?[contact.uid]
    action      = @(contact) inviteToSquad(contact.uid)
    getWatch    = @(contact) [canInviteToSquad, squadMembers, isInvitedToSquad]
  }

  INVITE_TO_FRIENDS = {
    locId = "Invite to friends"
    icon = fa["user-plus"]

    isVisible   = @(contact) !isMe(contact) && contactsState.allowToRequest(contact)
                                            && isContactsManagementEnabled.value
    action      = @(contact) contactsState.execCharAction(contact, "contacts_request_for_contact")
    getWatch    = @(contact) [contact.groupsMask, isContactsManagementEnabled]
  }

  CANCEL_INVITE = {
    locId = "Cancel Invite"
    icon = fa["remove"]

    isVisible   = @(contact) !isMe(contact) && contactsState.isMyRequests(contact)
    action      = @(contact) contactsState.execCharAction(contact, "contacts_cancel_request")
    getWatch    = @(contact) contact.groupsMask
  }

  APPROVE_INVITE = {
    locId = "Approve Invite"
    icon = fa["user-plus"]

    isVisible   = @(contact) !isMe(contact) && contactsState.allowToApprove(contact)
    action      = @(contact) contactsState.execCharAction(contact, "contacts_approve_request")
    getWatch    = @(contact) contact.groupsMask
  }

  REJECT_INVITE = {
    locId = "Reject Invite"
    icon = fa["remove"]

    isVisible   = @(contact) !isMe(contact) && contactsState.isRequestToMe(contact)
    action      = @(contact) contactsState.execCharAction(contact, "contacts_reject_request")
    getWatch    = @(contact) contact.groupsMask
  }

  BREAK_APPROVAL = {
    locId = "Break approval"
    icon = fa["remove"]

    isVisible   = @(contact)
      !isMe(contact) && contactsState.isApproved(contact) && isContactsManagementEnabled.value
    action      = @(contact) contactsState.execCharAction(contact, "contacts_break_approval_request")
    getWatch    = @(contact) [contact.groupsMask, isContactsManagementEnabled]
  }


  ADD_TO_BLACKLIST = {
    locId = "Add to blacklist"
    icon = fa["remove"]

    isVisible   = @(contact) !isMe(contact) && contactsState.allowToBlacklist(contact)
                                            && isContactsManagementEnabled.value
    action      = @(contact) contactsState.execCharAction(contact, "contacts_add_to_blacklist")
    getWatch    = @(contact) [contact.groupsMask, isContactsManagementEnabled]
  }

  REMOVE_FROM_BLACKLIST = {
    locId = "Remove from blacklist"
    icon = fa["remove"]

    isVisible   = @(contact) !isMe(contact) && contactsState.isBlacklisted(contact)
    action      = @(contact) contactsState.execCharAction(contact, "contacts_remove_from_blacklist")
    getWatch    = @(contact) contact.groupsMask
  }

  REMOVE_FROM_SQUAD = {
    locId = "Remove from squad"

    isVisible   = @(contact) enabledSquad.value && !isMe(contact) && isSquadLeader.value && isInMySquad(contact)
    action      = @(contact) dismissSquadMember(contact.uid)
    getWatch    = @(contact) [enabledSquad, isSquadLeader, squadMembers]
  }

  PROMOTE_TO_LEADER = {
    locId = "Promote to squad chief"

    isVisible   = function(contact) {
                    return enabledSquad.value &&
                           !isMe(contact) &&
                           isSquadLeader.value &&
                           isInMySquad(contact) &&
                           !platform.is_xbox
                }
    action      = @(contact) transferSquad(contact.uid)
    getWatch    = @(contact) [enabledSquad, isSquadLeader, squadMembers]
  }

  REVOKE_INVITE = {
    locId = "Revoke invite"
    icon = fa["remove"]

    isVisible   = @(contact) isSquadLeader.value && !isInMySquad(contact) && isInvitedToSquad.value?[contact.uid]
    action      = @(contact) revokeSquadInvite(contact.uid)
    getWatch    = @(contact) [isSquadLeader, squadMembers, isInvitedToSquad]
  }

  REMOVE_FROM_FRIENDS = {
    locId = "Remove contact"

    isVisible   = @(contact) !isMe(contact) && contactsState.isFriend(contact)
    action      = @(contact) contactsState.removeContact(contact)
    getWatch    = @(contact) contact.groupsMask
  }

  LEAVE_SQUAD = {
    locId = "Leave squad"

    isVisible   = @(contact) enabledSquad.value && isMe(contact) && isInSquad.value
    action      = @(contact) leaveSquad()
    getWatch    = @(contact) [enabledSquad, isInSquad]
  }

  COMPARE_ACHIEVEMENTS = {
    locId = "Compare achievements"

    isVisible   = @(contact) platform.is_pc
    action      = @(contact) openUrl("https://achievements.gaijin.net/?app={0}&nick={1}".subst(appId.value, contact.nick.value))
    getWatch    = @(contact) []
  }

  SHOW_USER_LIVE_PROFILE = {
    locId = "show_user_live_profile"

    isVisible   = @(contact) platform.is_xbox
    action      = @(contact) ipcSend({ msg = "showXboxUserInfo", userId = contact.uid })
    getWatch    = @(contact) []
  }
}

return actions
 