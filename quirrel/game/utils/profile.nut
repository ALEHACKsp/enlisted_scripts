local rand = require("std/rand.nut")()
local dedicated = require_optional("dedicated")
local message_queue = require_optional("message_queue")
local sys = require("dagor.system")
local profile_server = require_optional("profile_server")
local netErrorConverter = require("enlist/netErrorConverter.nut")
local stdlog = require("std/log.nut")()
local log = stdlog.with_prefix("[profileServerClient]")
local json = require("json")
local { get_app_id } = require("app")

local lastRequest = persist("lastRequest", @() { id = rand.rint() })

local tubeName = sys.get_arg_value_by_name("profile_tube") ?? ""
if (dedicated != null)
  ::print($"profile_tube: {tubeName}")


local is_enabled = @() message_queue != null && dedicated != null && get_app_id() > 0

local function checkAndLogError(id, action, result) {
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
}


local function send_job(action, userid, data, id = null) {
  if (!is_enabled()) {
    stdlog.logerr($"Refusing to send job {action} to profile")
    return
  }

  id = id ?? (++lastRequest.id).tostring()

  local actionEx = $"das.{action}"

  local reqData = {
    method = actionEx
    id = id
    jsonrpc = "2.0"
  }

  if (data != null)
    reqData["params"] <- data

  if (tubeName != "") {
    log($"Sending request {id}, method: {actionEx} via message_queue")
    local transactid = message_queue.gen_transactid()
    message_queue.put_raw(tubeName, {
        action = actionEx,
        headers = {
          appid = get_app_id()
          userid = userid
          transactid = transactid
        },
        body = reqData
      })
  } else {
    log($"Sending request {id}, method: {actionEx} via http")
    profile_server.request({
        action = actionEx,
        headers = {
          appid = get_app_id()
          userid = userid
        },
        data = reqData
      },
      @(result) netErrorConverter.error_response_converter(
        @(r) checkAndLogError(id, actionEx, r),
        result))
  }
}

return {
  isEnabled = is_enabled
  sendJob = send_job
}
 