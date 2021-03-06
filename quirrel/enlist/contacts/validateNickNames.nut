local netUtils = require("enlist/netUtils.nut")

local requestedUids = {}

//contacts - array or table of contacts
local function validateNickNames(contacts, finish_cb = null) {
  local requestContacts = []
  foreach(c in contacts) {
    if (!c.isNickValid.value && !(c.uid in requestedUids)) {
      requestContacts.append(c)
      requestedUids[c.uid] <- true
    }
  }
  if (!requestContacts.len()) {
    if (finish_cb)
      finish_cb()
    return
  }

  netUtils.request_nick_by_uid_batch(requestContacts.map(@(c) c.uid),
    function(result) {
      foreach(contact in requestContacts) {
        local name = result?[contact.userId]
        if (name)
          contact.realnick(name)
        if (contact.uid in requestedUids)
          delete requestedUids[contact.uid]
      }
      if (finish_cb)
        finish_cb()
    })
}

return validateNickNames
 