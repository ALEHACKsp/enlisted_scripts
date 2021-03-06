local ipc = require("ipc")
local ipc_hub = require("ui/ipc_hub.nut")
local u = require("std/underscore.nut")

local sharedData = {}
local key = {}

local function make(name, ctor) {
  if (name in sharedData) {
    ::assert(false, $"sharedWatched: duplicate name: {name}")
    return sharedData[name]
  }

  local res = persist(name, @() Watched(key))
  sharedData[name] <- res
  if (res.value == key) {
    res(ctor())
    try {
      ipc.send({ msg = "sharedWatched.requestData", name = name, value = res.value })
    } catch (err) {
      ::log("ipc.send() failed")
      ::log(err)
      throw err?.errMsg ?? "Unknown error"
    }
  }

  res.subscribe(function(val) {
    try {
      ipc.send({ msg = "sharedWatched.update", name = name, value = val })
    } catch (err) {
      ::log("ipc.send() failed")
      ::log(err)
      throw err?.errMsg ?? "Unknown error"
    }
  })
  return res
}

ipc_hub.subscribe("sharedWatched.update",
  function(msg) {
    local w = sharedData?[msg.name]
    if (w && !u.isEqual(w.value, msg.value))
      sharedData[msg.name](msg.value)
  })

ipc_hub.subscribe("sharedWatched.requestData",
  function(msg) {
    local w = sharedData?[msg.name]
    if (w && !u.isEqual(w.value, msg.value)) {
      try {
        ipc.send({ msg = "sharedWatched.update", name = msg.name, value = w.value })
      } catch (err) {
        ::log("ipc.send() failed")
        ::log(err)
        throw err?.errMsg ?? "Unknown error"
      }
    }
  })

return make 