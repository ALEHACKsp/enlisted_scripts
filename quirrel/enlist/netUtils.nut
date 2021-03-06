local matchingCli = require("matchingClient.nut")
local {error_response_converter} = require("netErrorConverter.nut")

local function request_nick_by_uid_batch(user_ids, cb) {
  matchingCli.call("mproxy.nick_server_request",
                        function(response) {
                          if (response.error != 0) {
                            cb(null)
                            return
                          }
                          local result = response?.result
                          if (typeof result != "table") {
                            cb(null)
                            return
                          }
                          cb(result)
                        },
                        { ids = user_ids })
}

local request_nick_by_uid = @(uid, cb) request_nick_by_uid_batch([uid],
                                                        @(result) result == null ? cb(result) : cb(result?[uid.tostring()]))


local function request_full_userinfo(user_id, cb) {
  matchingCli.call("mproxy.get_user_info",
                        function(response) {
                          cb(response)
                        },
                        { userId = user_id})
}


console.register_command(
  @(user_id) request_nick_by_uid(user_id, @(nick) console_print(nick))
  "netutils.request_nick_by_uid")

console.register_command(
  @(user_id) request_full_userinfo(user_id, @(info) console_print(info))
  "netutils.request_full_userinfo")

return {
  request_nick_by_uid = request_nick_by_uid
  request_nick_by_uid_batch = request_nick_by_uid_batch
  request_full_userinfo = request_full_userinfo
  error_response_converter = error_response_converter
}
 