local {Alert} = require("ui/style/colors.nut")
local contactsState = require("contactsState.nut")
local {isContactsVisible} = contactsState
local buildCounter = require("buildCounter.nut")
local contactsListWnd = require("enlist/contacts/contactsListWnd.nut")
local squareIconButton = require("enlist/components/squareIconButton.nut")

local onlineFriendsCounter = buildCounter({
  pos = [-hdpx(3), hdpx(4)]
  watched = contactsState?.lists?.approved?.list
  textfunc = function(watched){
    local text = (watched?.value ?? [])
        .filter( @(contact) contact.online.value == true )
        .len()
    return text != 0 ? text : null
  }
})
local invitationsCounter = buildCounter({
  pos = [-hdpx(3), -hdpx(4)]
  vplace = ALIGN_BOTTOM
  watched = contactsState?.lists?.requestsToMe?.list color=Alert
  textfunc = function(watched) {
    local text = (watched?.value ?? []).len()
    return text != 0 ? text : null
  }
})

local contactsButton = @() {
  watch = isContactsVisible
  children = [
    squareIconButton({
      onClick = @() contactsListWnd.show()
      tooltipText = ::loc("tooltips/contactsButton")
      iconId = "users"
      selected = isContactsVisible
    })
    onlineFriendsCounter
    invitationsCounter
  ]
}

return contactsButton
 