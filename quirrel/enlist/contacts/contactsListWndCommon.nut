local contactsState = require("contactsState.nut")
local colors = require("ui/style/colors.nut")
local { gap } = require("enlist/viewConst.nut")
local textInput = require("ui/components/textInput.nut")
local {makeVertScroll} = require("ui/components/scrollbar.nut")
local fontIconButton = require("enlist/components/fontIconButton.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local txt = require("daRg/components/text.nut").dtext
local userInfo = require("enlist/state/userInfo.nut")
local {popupBlockStyle, defPopupBlockPos} = require("enlist/popup/popupBlock.nut")
local modalPopupWnd = require("enlist/components/modalPopupWnd.nut")
local {CANCEL_INVITE, APPROVE_INVITE, ADD_TO_BLACKLIST, INVITE_TO_FRIENDS,
      INVITE_TO_SQUAD, REMOVE_FROM_BLACKLIST, COMPARE_ACHIEVEMENTS,
      REVOKE_INVITE, REMOVE_FROM_FRIENDS, REMOVE_FROM_SQUAD, BREAK_APPROVAL,
      PROMOTE_TO_LEADER, SHOW_USER_LIVE_PROFILE } = require("contactActions.nut")
local contactBlock = require("contactBlock.nut")
local windowPadding = sh(2)
local searchPlayer = persist("searchPlayer", @() Watched(""))

local {lists, searchResults, isOnlineContactsSearchEnabled, isContactsEnabled, isContactsManagementEnabled} = contactsState
local buildContactsButton = require("buildContactsButton.nut")
local buildCounter = require("buildCounter.nut")
local {safeAreaBorders} = require("enlist/options/safeAreaState.nut")

local CONTACTLIST_MODAL_UID = "contactsListWnd_modalUid"
local display = persist("display", @() Watched("approved"))
local contactListWidth = hdpx(250)

local function hdrTxt(text,params={}){
  return {
    padding=[hdpx(2),sh(1)]
    size = [flex(),SIZE_TO_CONTENT]
    children = txt(text,params.__merge({
      behavior=[Behaviors.Marquee,Behaviors.Button]
      size = [flex(), SIZE_TO_CONTENT]
      speed = hdpx(100)
      font = Fonts.small_text
      scrollOnHover=true
    }))
  }
}

/*
todo:
  - sort in contextMenu
-----
  - split online and offline users and remove presence icon
  - move a search to invitations panel, and make a filter inputbox for contacts and blocklist
*/

local function contactsList(params={list=Watched([]), title="", placeholder=null, contactBlockParams={}}) {
  local list = params?.list ?? Watched([])
  local placeholder = params?.placeholder
  local contactBlockParams = params?.contactBlockParams ?? {}
  local online = list.value.filter( @(contact) contact.online.value == true )
  local offline = list.value.filter( @(contact) contact.online.value != true )

  local contactsBlocksList = online.extend(offline).map(@(c) contactBlock({contact = c}.__update(contactBlockParams)))
  local title = (params?.title!=null) ? hdrTxt(::loc(params.title)) : null
  local function listRoot() {
    return {
      size = [flex(), SIZE_TO_CONTENT]
      watch = list
      flow = FLOW_VERTICAL
      margin = hdpx(4)
      gap = hdpx(3)
      children = contactsBlocksList.len() > 0 ? contactsBlocksList : placeholder
    }
  }

  return {
    size = flex()
    flow = FLOW_VERTICAL
    children = [
      title
      makeVertScroll(listRoot)
    ]
  }
}

local closeButton = fontIconButton(fa["close"], { onClick = @() modalPopupWnd.remove(CONTACTLIST_MODAL_UID) })

local header = @(){
  size = [flex(), sh(4)]
  watch = userInfo
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  gap = hdpx(8)
  padding = [hdpx(8),hdpx(8),hdpx(8),windowPadding]
  color = colors.WindowHeader
  children = [
    {
      rendObj = ROBJ_DTEXT
      font = Fonts.medium_text
      text = userInfo.value?.name ?? ""
      size = [flex(), SIZE_TO_CONTENT]
      color = colors.Inactive
      clipChildren = true
      behavior = [Behaviors.Marquee, Behaviors.Button]
      scrollOnHover=true
    }
    {size = [hdpx(8),0]}
    closeButton
  ]
}

local function exitSearch(){
  display.update("approved")
  searchPlayer("")
  searchResults.update(@(val) val.clear())

  if (!isOnlineContactsSearchEnabled.value)
    contactsState.searchContacts("", null)
}

local function searchPlayers(value) {
  if (value.len() == 0) {
    exitSearch()
    return
  }
  contactsState.searchContacts(
    value,
    function () {
      display.update("search_results")
      display.trigger()
    }
  )
}
display.subscribe(function(val){
  if (val == "search_results")
    return
  searchPlayer("")
  searchResults.update(@(val) val.clear())
})

local exitSearchButton = @() {
  watch = [display,searchPlayer]
  isHidden = display.value != "search_results" || searchPlayer.value.len()==0
  behavior = Behaviors.Button
  onClick = exitSearch
  margin = [0, sh(0.5)]

  rendObj = ROBJ_STEXT
  validateStaticText = false
  font = Fonts.fontawesome
  text = fa["close"]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER

  sound = {
    click  = "ui/enlist/button_click"
    hover  = "ui/enlist/button_highlight"
    active = "ui/enlist/button_action"
  }
}

local searchBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  margin =[ hdpx(2), windowPadding]
  children = [
    textInput(searchPlayer, {
      font = Fonts.small_text
      placeholder = ::loc(isOnlineContactsSearchEnabled.value ? "Search for new friends..." : "Search in friends list...")
      textmargin = hdpx(5)
    }, {
      onChange = @(value) !isOnlineContactsSearchEnabled.value || value.len() != 1 ? searchPlayers(value) : null
      onReturn = @() searchPlayers(searchPlayer.value)
      onEscape = exitSearch
    })
    exitSearchButton
  ]
}


local function buildBtnParams(params={icon=null, option=null, count_list=null}){
  local icon = params.icon
  local option = params.option
  local counterFunc = params?.counterFunc ?? function(watched){
    local text = (watched?.value ?? []).len()
    return text != 0 ? text : null
  }
  local children = buildCounter({
    watched = lists[params?.count_list ?? option].list,
    textfunc = counterFunc
  })
  return {
    symbol = fa[icon]
    onClick = @() display(option)
    selected = ::Computed(@() display.value == option)
    children = children
    option = option
    icon = icon
  }
}

local friendsButton = buildContactsButton(buildBtnParams({icon="users", option="approved", counterFunc = function(watched){
    local text = (watched?.value ?? [])
        .filter( @(contact) contact.online.value == true )
        .len()
    return text != 0 ? text : null
  }
}))
local invitationsButton = buildContactsButton(buildBtnParams({icon="user-plus", option="invites", count_list="requestsToMe"}))
local myBlacklist = buildContactsButton(buildBtnParams({icon="user-times", option="myBlacklist"}))


local placeholder = txt(::loc("contacts/list_empty"), {color=colors.Inactive, font=Fonts.small_text, margin = [sh(1),windowPadding]})

local invitesKeys = [
  {list = "requestsToMe", inContactActions = [APPROVE_INVITE],
    contextMenuActions = [APPROVE_INVITE, INVITE_TO_SQUAD, ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]}
  {list = "myRequests", inContactActions = [CANCEL_INVITE],
    contextMenuActions = [CANCEL_INVITE, INVITE_TO_SQUAD, ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]}
  {list = "rejectedByMe", inContactActions=[],
    contextMenuActions = [APPROVE_INVITE, INVITE_TO_FRIENDS, INVITE_TO_SQUAD, ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]}
]

local function invites() {
  local children = []
  local watches = []
  foreach (v in invitesKeys) {
    local listName = v.list
    local contactsArr = lists[listName].list.value.map(@(c)
      contactBlock({contact = c, inContactActions=v.inContactActions, contextMenuActions=v.contextMenuActions})
    )
    if (contactsArr.len()==0)
      contactsArr = [placeholder]
    children.append(hdrTxt(::loc($"contacts/{listName}")))
    children.extend(contactsArr)
    watches.append(lists[listName].list)
  }
  return makeVertScroll(@(){
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = children
    watch = watches
  })
}


local modesList = ::Computed(@() isContactsManagementEnabled.value ? [
  { option = "approved", comp = friendsButton },
  { option = "invites", comp = invitationsButton},
  { option = "myBlacklist", comp = myBlacklist}
] : [])
local modesListCanBeChanged = ::Computed(@() modesList.value.len()>1)

local function modeSwitcher() {
  return modesListCanBeChanged.value ?
    {
      size = [pw(100), sh(5)]
      halign = ALIGN_RIGHT
      watch = [modesList, modesListCanBeChanged]
      valign = ALIGN_BOTTOM
      gap = hdpx(10)
      margin = [hdpx(8), windowPadding, hdpx(0), windowPadding]
      flow = FLOW_HORIZONTAL
      children = modesList.value.map(@(m) m.comp)
    }
  : { watch = modesListCanBeChanged }
}

local searchTbl = {
  list=searchResults, title="contacts/search_results", placeholder=placeholder,
  contactBlockParams = {
    inContactActions = [INVITE_TO_FRIENDS],
    contextMenuActions = [
      INVITE_TO_FRIENDS, APPROVE_INVITE, APPROVE_INVITE,
      INVITE_TO_SQUAD, CANCEL_INVITE, REMOVE_FROM_BLACKLIST, ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS
    ]
  }
}
local myBlackTbl = {
  list=lists?.myBlacklist?.list,
  title="contacts/myBlacklist",
  placeholder=placeholder,
  contactBlockParams = {
    inContactActions=[REMOVE_FROM_BLACKLIST],
    contextMenuActions = [REMOVE_FROM_BLACKLIST, COMPARE_ACHIEVEMENTS]
  }
}
local approvedTbl = {
  list=lists?.approved?.list, title="contacts/friends", placeholder=placeholder,
  contactBlockParams = {
    inContactActions = [INVITE_TO_SQUAD],
    contextMenuActions = [
      REMOVE_FROM_SQUAD, REVOKE_INVITE, INVITE_TO_SQUAD, PROMOTE_TO_LEADER,
      REMOVE_FROM_FRIENDS, BREAK_APPROVAL, COMPARE_ACHIEVEMENTS, SHOW_USER_LIVE_PROFILE
    ]
  }
}
local isContactsWndVisible = Watched(false)
local popupsOffset = [-contactListWidth+defPopupBlockPos[0], defPopupBlockPos[1]]
isContactsWndVisible.subscribe(@(v) popupBlockStyle(@(style) style.pos <- (v ? popupsOffset : defPopupBlockPos)))

local function contactsBlock() {
  local watches = [display, isContactsEnabled]
  foreach (n,l in lists)
    watches.append(l.list)
  local contactsTbl = {
    search_results = contactsList(searchTbl),
    invites = invites,
    myBlacklist = contactsList(myBlackTbl),
    approved = contactsList(approvedTbl)
  }?[isOnlineContactsSearchEnabled.value ? display.value : "approved"]

  return  {
    size = [contactListWidth, flex() ]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = colors.WindowBlur
    valign = ALIGN_BOTTOM
    watch = watches
    stopMouse = true
    key = "contactsBlock"
    onAttach = @() isContactsWndVisible(true)
    onDetach = @() isContactsWndVisible(false)

    children = {
      size = flex()
      rendObj = ROBJ_SOLID
      color = colors.WindowContacts
      flow = FLOW_VERTICAL
      children = [
        header
        {
          flow = FLOW_VERTICAL
          size = flex()
          children = [
            modeSwitcher
            searchBlock
            contactsTbl
          ]
        }
      ]
    }
  }
}


local curModeIdx = ::Computed(@() modesList.value.findindex(@(m) m.option == display.value) ?? -1)
local changeMode = @(delta) display(modesList.value[(curModeIdx.value + delta + modesList.value.len()) % modesList.value.len()].option)

local btnContactsNav = @() {
  watch = modesListCanBeChanged
  size = SIZE_TO_CONTENT
  children = modesListCanBeChanged.value ? {
    hotkeys = [
      ["^J:RB | Tab", {action = @() changeMode(1), description=::loc("contacts/next_mode")} ],
      ["^J:LB | L.Shift Tab | R.Shift Tab", { action = @() changeMode(-1), description=::loc("contacts/prev_mode")} ]
    ]
  } : null
}



local popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = colors.ModalBgTint }
local function show(additionalChild=null){
  local enabled = isContactsEnabled.value
  if (!enabled)
    return

  local bottomOffset = safeAreaBorders.value[2] + gap
  local popupHeight = sh(95) - bottomOffset

  modalPopupWnd.add([sw(100), sh(100) - bottomOffset],
  {
    size = [SIZE_TO_CONTENT, popupHeight]
    uid = CONTACTLIST_MODAL_UID
    fillColor = Color(0,0,0)
    padding = 0
    popupFlow = FLOW_HORIZONTAL
    popupValign = ALIGN_BOTTOM
    popupOffset = 0
    margin = 0
    children = [contactsBlock, btnContactsNav, additionalChild]
    popupBg = popupBg
  })
}

return ::kwarg(show)
 