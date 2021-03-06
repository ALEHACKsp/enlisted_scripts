local msgbox = require("components/msgbox.nut")
local frp = require("std/frp.nut")
local matching_api = require("matching.api")
local popupsState = require("enlist/popup/popupsState.nut")

local platform = require("globals/platform.nut")

 //no messages for xbox/ps4 yet
local mailboxEnabled = Watched(!(platform.is_xbox || platform.is_sony))

local isMailboxVisible  = persist("isMailboxVisible", @() Watched(false))
local inbox = persist("inbox", @() Watched([]))
local onNewMail = persist("onNewMail", @() Watched({}))
local readNum = persist("readNum", @() Watched(0))
local counter = persist("counter", @() { last = 0 })

local hasUnread = frp.combine({inbox=inbox, readNum=readNum} function(_){
  return _.inbox.len()>_.readNum
})

local function removeNotification(id) {
  foreach(idx, notify in inbox.value)
    if (notify.id == id) {
      inbox.update(@(value) value.remove(idx))
    }
}

local showPopup = @(notify)
  popupsState.addPopup({ id = $"mailbox_{notify.id}", text = notify.text.value, onClick = notify.show })

local NOTIFICATION_PARAMS = {
  id = null //string
  text = "" //string or Watched
  onShow = null //function(removeFunc)
  onRemove = null //function()
  isRead = false
  needPopup = false
  styleId = ""
}
local function pushNotification(notify = NOTIFICATION_PARAMS) {
  notify = NOTIFICATION_PARAMS.__merge(notify)

  if (!(notify.text instanceof ::Watched))
    notify.text = ::Watched(notify.text)

  if (notify.id != null)
    removeNotification(notify.id)
  else
    notify.id = "_{0}".subst(counter.last++)

  local function removeNotify() {
    removeNotification(notify.id)
    notify.show = null
  }
  notify.show <- function() {
    if (notify.onShow)
      notify.onShow(removeNotify)
    else
      removeNotify()
  }
  notify.remove <- function() {
    if (notify.onRemove)
      notify.onRemove()
    removeNotify()
  }
  inbox.value.append(notify)
  if (!notify.isRead)
    inbox.trigger()
  else
    readNum.update(readNum.value+1)

  if (notify.needPopup && mailboxEnabled.value)
    showPopup(notify)
}

local function markReadAll() {
  readNum.update(inbox.value.len())
}
local function clearAll() {
  readNum.update(0)
  inbox.update([])
}
matching_api.subscribe("postbox.notify_mail", @(mail_obj) onNewMail.update(mail_obj))

console.register_command(
  function(text){
    counter.last++
    pushNotification({
      id = "m_{0}".subst(counter.last)
      text = text,
      onShow = @(...) msgbox.show({text=text, buttons = [ {text = ::loc("Yes"), action = @() removeNotification("m_{0}".subst(counter.last)) }]}),
    })
  },
  "mailbox.push"
)

return {
  mailboxEnabled
  inbox
  hasUnread
  readNum
  onNewMail
  pushNotification
  removeNotification
  markReadAll
  clearAll
  isMailboxVisible
}
 