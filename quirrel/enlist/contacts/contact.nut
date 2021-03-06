local frp = require("std/frp.nut")
local remap_nick = require("globals/remap_nick.nut")
local invalidNickName = "????????"

local contacts = {}
//probably much simpler would be contacts = Watched contactList, and each Contact just ::Computed or even static object
// this will eliminate overengineering of contacts observables subscription (just simple contact list would be observable)
// and here it will eliminate frp and persist engineering

local function loadContact(userIdStr) {
  local res = persist(userIdStr, @() {
    userId          = userIdStr
    uid             = userIdStr.tointeger() //userId.tointeger()
    presences       = Watched({}) //table
    groupsMask      = Watched(0) //int, mask of contacts groups. updated from contactsState
    onlineBySquad   = Watched(null) //bool or null, modified by squad
    realnick        = Watched(invalidNickName) //string
  })
  res.nick        <- frp.map(res.realnick, remap_nick) //string
  res.isNickValid <- frp.map(res.realnick, @(nick) nick != invalidNickName)//bool
  res.online      <- frp.combine([res.onlineBySquad, res.presences], @(l) l[0] ?? (l[1]?.unknown ? null : l[1]?.online)) //bool or null
  return res
}

local function Contact(userIdStr, name=null) {
  assert(type(userIdStr)==type(""), "Contact can be created only by string user id")
  if (!(userIdStr in contacts))
    contacts[userIdStr] <- loadContact(userIdStr)
  if (name != null)
    contacts[userIdStr].realnick(name)
  return contacts[userIdStr]
}

return {
  get = Contact
  make = Contact
}
 