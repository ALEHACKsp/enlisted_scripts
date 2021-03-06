local profileServer = require("enlist/profileServer/profileServer.nut")
local ipc = require("ipc")
local ipc_hub = require("ui/ipc_hub.nut")

local function sendResult(data, id) {
  ipc.send({
    msg = "profile_srv.response"
    data = data
    id = id
  })
}


local function handleMessages(msg) {
  local msgId = msg.id
  profileServer.request(msg.data.method, msg.data?.params, msgId,
    @(result) sendResult(result, msgId),
    msg.data?.token)
}


ipc_hub.subscribe("profile_srv.request", handleMessages)
 