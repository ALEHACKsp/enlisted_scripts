local ipc = require("ipc")

local subscriptions = {}

local function subscribe(msgName, cb) {
  if (!(msgName in subscriptions))
    subscriptions[msgName] <- []
  subscriptions[msgName].append(cb)
}

ipc.set_handler(function(data) {
  local list = subscriptions?[data?.msg]
  if (!list)
    return

  list = clone list
  foreach(cb in list)
    cb(data)
})

return {
  subscribe = subscribe
  send = ipc.send
}
 