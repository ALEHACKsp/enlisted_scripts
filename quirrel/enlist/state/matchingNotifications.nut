local matching_api = require("matching.api")
local userInfo = require("enlist/state/userInfo.nut")
local appId = require("enlist/state/clientState.nut").appId

local subscriptions = {}

matching_api.subscribe("mrpc.generic_notify", function(ev) {
  if (userInfo.value == null || appId.value <= 0)
    return
  subscriptions?[ev?.from].each(@(handler) handler(ev))
})

local function subscribe(from, handler) {
  if (!(from in subscriptions))
    subscriptions[from] <- []
  subscriptions[from].append(handler)
}

local function unsubscribe(from, handler) {
  if (!(from in subscriptions))
    return
  local idx = subscriptions[from].indexof(handler)
  if (idx != null)
    subscriptions[from].remove(idx)
}

return {
  subscribe = subscribe
  unsubscribe = unsubscribe
} 