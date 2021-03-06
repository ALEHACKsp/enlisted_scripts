local Contact = require("contact.nut")
local contextMenu = require("ui/components/contextMenu.nut")

local function open(contactOrUid, event, actions) {
  local contact = contactOrUid
  if (typeof contactOrUid  == "string")
    contact = Contact.get(contactOrUid)

  local actionsButtons = (actions ?? []).map(function(action) {
    return action.isVisible(contact) ? {
      text = ::loc(action.locId)
      action = @() action.action(contact)
    } : null
  }).filter(@(v) v!=null)
  if (actionsButtons.len())
    contextMenu(event.screenX + 1, event.screenY + 1, sh(30), actionsButtons)
}

return {
  open = open
} 