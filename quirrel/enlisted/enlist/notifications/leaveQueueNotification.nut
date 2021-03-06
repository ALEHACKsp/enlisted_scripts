local msgbox = require("enlist/components/msgbox.nut")
local {leaveQueue, isInQueue} = require("enlist/quickMatchQueue.nut")

const MSG_UID = "leave_queue_msgbox"

local function QueueWatcher(watch, params={}) {
  local askLeave = params?.askLeave ?? @(self) self.watch.value != self.last
  local obj = {
    watch = watch
    askLeave = askLeave
    last = watch.value
  }
  local function showLeaveMsgBox() {
    if (msgbox.isInList(MSG_UID))
      return
    msgbox.show({
      uid = MSG_UID
      text = ::loc("msg/cancel_queue_question"),
      buttons = [
        { text = ::loc("Ok"),
          action = @() leaveQueue()
          isCurrent = true
        }
        { text = ::loc("Cancel")
          action = @() watch(obj.last)
          isCancel = true
        }
      ]
    })
  }
  obj.showLeaveMsgBox <- showLeaveMsgBox

  isInQueue.subscribe(function(val) {
    if (val)
      return
    msgbox.removeByUid(MSG_UID)
    obj.last = watch.value
  })

  watch.subscribe(function(val) {
    if (val == obj.last)
      return
    if (!isInQueue.value) {
      obj.last = val
      return
    }
    if (obj.askLeave(obj))
      obj.showLeaveMsgBox()
  })
  return obj
}

return QueueWatcher
 