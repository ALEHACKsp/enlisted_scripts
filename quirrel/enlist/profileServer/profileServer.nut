local profile_server = require("profile_server")
local netErrorConverter = require("enlist/netErrorConverter.nut")
local appId = require("enlist/state/clientState.nut").appId
local stdlog = require("std/log.nut")()
local log = stdlog.with_prefix("[profileServerClient]")
local json = require("json")
local userInfo = require("enlist/state/userInfo.nut")

local function checkAndLogError(id, action, cb, result) {
  if ("error" in result) {
    local err = result.error
    if (typeof err == "table") {
      if ("message" in err) {
        if ("code" in err)
          err = $"{err.message} (code: {err.code})"
        else
          err = err.message
      }
    }
    if (typeof err != "string")
      err = $"(full answer dump) {json.to_string(result)}"
    stdlog.logerr($"[profileServerClient] request {id}: {action} returned error: {err}")
  } else {
    log($"request {id}: {action} completed without error")
  }
  if (cb)
    cb(result)
}


local function doRequest(action, params, id, cb, token = null) {
  token = token ?? userInfo.value?.token
  if (!token) {
    log($"Skip action {action}, no token")
    if (cb)
      cb({error="No token"})
    return
  }

  local actionEx = $"das.{action}"
  local reqData = {
    method = actionEx
    id = id
    jsonrpc = "2.0"
  }

  if (params != null)
    reqData["params"] <- params

  local request = {
    headers = {
      token = token
      appid = appId.value
    },
    action = actionEx
    data = reqData
  }

  log($"Sending request {id}, method: {action}")
  profile_server.request(request,
                         @(result) netErrorConverter.error_response_converter(
                              @(r) checkAndLogError(id, action, cb, r),
                              result))
}


return {
  request = doRequest
}
 