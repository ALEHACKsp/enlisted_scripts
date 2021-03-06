local colors = require("ui/style/colors.nut")
local {buttonSound} = require("ui/style/sounds.nut")
local fa = require("daRg/components/fontawesome.map.nut")

local squadState = require("enlist/squad/squadState.nut")
local { contactBlockExtensionCtr, isFriendOrApproved } = require("contactsState.nut")
local contactContextMenu = require("contactContextMenu.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local userInfo = require("enlist/state/userInfo.nut")
local textButton = require("enlist/components/textButton.nut")

local contactBlock = ::kwarg(function contactBlock_impl(contact, inContactActions = [], contextMenuActions = [], style = {}) {
  local group = ::ElemGroup()
  local presenceIcon = @() {
    size = [fontH(100), SIZE_TO_CONTENT]
    rendObj = ROBJ_STEXT
    validateStaticText = false
    halign = ALIGN_CENTER
    font = Fonts.fontawesome
    color = contact.online.value == null ? Color(104, 86, 86)
      : contact.online.value ? Color(31, 205, 39)
      : Color(154, 26, 26)
    text = contact.online.value != null ? fa["circle"] : fa["circle-o"]
    fontSize = hdpx(10)
    watch = contact.online
  }

  local stateFlags = ::Watched(0)
  local function statusBlock() {
    local iconParams = null
    local textParams = null
    local watch = [squadState.enabledSquad, squadState.squadMembers, squadState.isInvitedToSquad, contact.online, contact.groupsMask, contactBlockExtensionCtr]
    local squadMember = squadState.enabledSquad.value && squadState.squadMembers.value?[contact.uid]

    if (squadMember) {
      if (squadMember.state.value?.inBattle) {
        iconParams = { color = colors.ContactInBattle, text = fa["gamepad"] }
        textParams = { text = ::loc("contact/inBattle") }
      }
      else if (squadMember.isLeader.value) {
        iconParams = { color = colors.ContactLeader, text = fa["star"] }
        textParams = { text = ::loc("squad/Chief") }
      }
      else if (!contact.online.value) {
        iconParams = { color = colors.ContactOffline, text = fa["times"] }
        textParams = { text = ::loc("contact/Offline") }
      }
      else if (squadMember.state.value?.ready) {
        iconParams = { color = colors.ContactReady, text = fa["check"] }
        textParams = { text = ::loc("contact/Ready") }
      }
      else {
        iconParams = { color = colors.ContactNotReady, text = fa["times"] }
        textParams = { text = ::loc("contact/notReady") }
      }
      watch.append(squadMember.isLeader, squadMember.state)
    }
    else if (squadState.isInvitedToSquad.value?[contact.uid]) {
      iconParams = {
        size = [fontH(100), SIZE_TO_CONTENT]
        margin = [0, fontH(10), 0, 0]
        key = contact.userId
        color = colors.ContactOffline
        text = fa["spinner"]
        transform = {}
        animations = [
          { prop=AnimProp.rotate, from = 0, to = 360, duration = 1, play = true, loop = true, easing = Discrete8 }
        ]
      }
      textParams = { text = ::loc("contact/Invited") }
    }
    else if (isFriendOrApproved(contact))
      textParams = { text = contact.online.value ? ::loc("contact/Online")
        : contact.online.value == null ? ::loc("contact/Unknown")
        : ::loc("contact/Offline") }

    local children = []
    if (iconParams)
      children.append({
        size = SIZE_TO_CONTENT
        rendObj = ROBJ_STEXT
        font = Fonts.fontawesome
        validateStaticText = false
      }.__update(iconParams))
    if (textParams)
      children.append({
        size = SIZE_TO_CONTENT
        rendObj = ROBJ_DTEXT
        color = colors.ContactOffline
        font = Fonts.small_text
      }.__update(textParams))
    local bottomLineChild = contactBlockExtensionCtr.value?.bottomLineChild
    return {
      size = [flex(), SIZE_TO_CONTENT]
      watch = watch
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          gap = hdpx(5)
          flow = FLOW_HORIZONTAL
          halign = ALIGN_LEFT
          valign = ALIGN_CENTER
          children = children
        }
        squadMember && (bottomLineChild != null) ? bottomLineChild(squadMember) : null
      ]
    }
  }

  local contactActionButton = @(contact, action) @() {
      size = action.isVisible(contact) ? [SIZE_TO_CONTENT, SIZE_TO_CONTENT] : SIZE_TO_CONTENT
      watch = action.getWatch(contact)
      group = group
      margin = [0,0,hdpx(2), 0]
      skipDirPadNav = true
      children = (action.isVisible(contact) && (stateFlags.value & S_HOVER))
        ? textButton.Small(::loc(action.locId), @() action.action(contact), { key = contact.userId, skipDirPadNav = true })
        : null
  }

  local actionsButtons = {
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = inContactActions.map(@(action) contactActionButton(contact, action))
  }

  local function onContactClick(event) {
    if (event.button >= 0 && event.button <= 2)
      contactContextMenu.open(contact, event, contextMenuActions)
  }

  local userNickname = @() {
    size = [flex(), fontH(120)]
    behavior = Behaviors.Marquee
    clipChildren = true
    scrollOnHover = true
    watch = contact.online
    rendObj = ROBJ_DTEXT
    font = Fonts.small_text
    group = group
    text = contact.nick.value
    color = contact.uid == userInfo.value?.userId ? colors.UserNameColor
              : contact.online.value ? colors.Active
              : colors.Inactive
  }

  local memberAvatar = contactBlockExtensionCtr.value?.memberAvatar(contact.uid)

  local namePrefix = contactBlockExtensionCtr.value?.namePrefixCtr(contact)

  return @() {
    size = flex()
    rendObj = style?.rendObj ?? ROBJ_SOLID
    color = (stateFlags.value & S_HOVER) ? (style?.hoverColor ?? colors.BtnBgNormal) : (style?.bgColor ?? colors.statusIconBg)
    minHeight = hdpx(55)
    padding = hdpx(4)
    gap = hdpx(4)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      memberAvatar
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = hdpx(4)
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = hdpx(4)
            valign = ALIGN_CENTER
            children = [presenceIcon, namePrefix, userNickname]
          }
          {
            size = [flex(), SIZE_TO_CONTENT]
            children = [
              statusBlock
              !isGamepad.value ? actionsButtons : null
            ]
          }
        ]
      }
    ]
    behavior = Behaviors.Button
    stopHover = true
    group = group
    onClick = onContactClick
    onElemState = @(sf) stateFlags.update(sf)
    watch = [ stateFlags, contact.nick, contact.online, isGamepad ]
    sound = buttonSound
  }
})

return contactBlock
 