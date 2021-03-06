local { statusIconBg } = require("ui/style/colors.nut")
local { navBottomBarHeight } = require("enlisted/enlist/mainMenu/mainmenu.style.nut")
local { bigGap } = require("enlisted/enlist/viewConst.nut")
local { squadMembers, isInvitedToSquad, canInviteToSquad, leaveSquad, squadSelfMember, isSquadLeader, enabledSquad,
  myExtSquadData
} = require("enlist/squad/squadState.nut")
local { selectedQueue } = require("enlist/quickMatchQueue.nut")
local Contact = require("enlist/contacts/contact.nut")
local contactBlock = require("enlist/contacts/contactBlock.nut")
local contactsListWnd = require("enlist/contacts/contactsListWnd.nut")
local squareIconButton = require("enlist/components/squareIconButton.nut")
local textButton = require("enlist/components/textButton.nut")
local { INVITE_TO_FRIENDS, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, REVOKE_INVITE, SHOW_USER_LIVE_PROFILE
} = require("enlist/contacts/contactActions.nut")
local userInfo = require("enlist/state/userInfo.nut")

local userName = @() {rendObj=ROBJ_DTEXT text=userInfo.value?.name watch = userInfo, opacity = 0.5, font = Fonts.medium_text}

local contextMenuActions = [INVITE_TO_FRIENDS, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, REVOKE_INVITE, SHOW_USER_LIVE_PROFILE]
local maxMembers = ::Computed(@() selectedQueue.value?.maxGroupSize ?? 1)

local addUserButton = squareIconButton({
  onClick = @() contactsListWnd.show()
  tooltipText = ::loc("tooltips/addUser")
})

local leaveButton = squareIconButton({
    onClick = @() leaveSquad()
    tooltipText = ::loc("tooltips/disbandSquad")
    iconId = "close"
  },
  { margin = [hdpx(8), 0, 0, hdpx(1)] })

local squadControls = @() {
  watch = squadMembers
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  children = squadMembers.value.len() > 0 ? leaveButton : null
}

local horizontalContact = @(contact) {
  size = [(navBottomBarHeight * 4.0).tointeger(), navBottomBarHeight]
  children = contactBlock({
    contact = contact
    contextMenuActions = contextMenuActions
    style = {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      bgColor = Color(255, 255, 255, 255)
      hoverColor = statusIconBg
    }
  })
}

local function squadMembersUi() {
  local squadList = []
  foreach (id, member in squadMembers.value)
    if (member.isLeader.value)
      squadList.insert(0, horizontalContact(member.contact))
    else
      squadList.append(horizontalContact(member.contact))

  foreach(uid, val in isInvitedToSquad.value)
    squadList.append(horizontalContact(Contact.get(uid.tostring())))

  if (maxMembers.value > 1 && canInviteToSquad.value)
    for(local i = squadList.len(); i < maxMembers.value-1; i++)
      squadList.append(addUserButton)

  return {
    watch = [squadMembers, isInvitedToSquad, canInviteToSquad, maxMembers]
    flow = FLOW_HORIZONTAL
    gap = hdpx(4)
    children = squadList
  }
}

local squadReadyButton = @(ready) textButton(
  ready.value ? ::loc("Set not ready") : ::loc("Press when ready"),
  @() ready(!ready.value),
  { size = [SIZE_TO_CONTENT, flex()]
    margin = [0, 0, 0, hdpx(5)]
    textParams = { validateStaticText = false, font=Fonts.small_text, vplace = ALIGN_CENTER }
    style = !ready.value
      ? { BgNormal   = Color(220, 130, 0, 250), TextNormal = Color(210, 210, 210, 120) }
      : { TextNormal = Color(100, 100, 100, 120) }
  })

local function squadReadyButtonPlace() {
  local res = { watch = [squadSelfMember, isSquadLeader] }
  if (squadSelfMember.value && !isSquadLeader.value) {
    res.watch.append(myExtSquadData.ready)
    res.size <- [SIZE_TO_CONTENT, navBottomBarHeight]
    res.children <- squadReadyButton(myExtSquadData.ready)
  }
  return res
}

return @() {
  stopMouse = true
  watch = enabledSquad
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bigGap
  children = [userName].extend(enabledSquad.value ? [
    squadControls
    squadReadyButtonPlace
    squadMembersUi
  ] : null)
}
 