                    

local matching_api = require("matching.api")
local matching_errors = require("matching.errors")
local delayedActions = require("utils/delayedActions.nut")
local string = require("string")
local log = require("std/log.nut")().with_prefix("[MATCHING] ")

local state = persist("state", @() {
  connecting = false
  stopped = false
})

local loginState = persist("loginState", @() Watched(false))
local connectingState = persist("connectingState", @() Watched(false))
local logoutNotify = persist("logoutNotify", @() Watched(null))
local srvDisconnectNotify = persist("srvDisconnectNotify", @() {})

loginState.subscribe(function(logged) {
  if (logged) {
    if (state.stopped == true) {
      log("matching connection was stopped during connect process")
      matching_api.logout()
    }
  }
})

matching_api.subscribe(matching_api.SRV_NOTIFY_DISCONNECT,
  function(data) {
    local reason = data?["reason"] ?? 0
    local message = data?["message"]
    log(string.format("got disconnect request from server. reason %s. %s",
                       matching_errors.error_string(reason),
                       (message == null) ? "" : message))
    srvDisconnectNotify.__update({reason = reason, message = message})
    matching_api.logout()
  })

local function is_retriable_login_error(loginerror) {
  if (loginerror == matching_errors.LoginResult.NameResolveFailed ||
      loginerror == matching_errors.LoginResult.FailedToConnect ||
      loginerror == matching_errors.LoginResult.ServerBusy ||
      loginerror == matching_errors.LoginResult.PeersLimitReached)
    return true
  return false
}

local function performConnect(login_info, on_disconnect, login_cb, iter) {
  log($"matching.performConnect [{iter}]")
  connectingState(true)
  if (state.connecting) {
    login_cb({error = "already connecting"})
    return
  }
  local self = ::callee()
  state.stopped = false
  state.connecting = true
  local function on_connect(connectError) {
    state.connecting = false
    if (connectError == 0) {
      log("matching login successfull")

      login_cb({})
      if (!loginState.value)
        loginState(true)
      else
        loginState.trigger()

      connectingState(false)
    }
    else {
      log($"matching login failed: \"{matching_errors.login_result_string(connectError)}\"")
      if (iter <= 3 && !state.stopped && is_retriable_login_error(connectError)) {
        delayedActions.add(
          @() self(login_info, on_disconnect, login_cb, iter + 1),
          3000)
      }
      else {
        login_cb({error = matching_errors.login_result_string(connectError)})
      }
    }
  }
  matching_api.dial(login_info, on_connect, on_disconnect)
}

local function deactivate_matching_login() {
  state.stopped = true
  if (!state.connecting)
    matching_api.logout()
}

local function activate_matching_login(loginInfo, login_cb) {
  log(string.format("matching login using name %s and user_id %d", loginInfo.userName, loginInfo.userId))

  local self = ::callee()
  local function onDisconnect(reason, message) {
    log(string.format("client had been disconnected from matching: '%s'", matching_errors.disconnect_reason_string(reason)))
    connectingState(true)

    if (state.stopped) {
      log("do logout")
      loginState(false)
      return
    }

    local doLogout = srvDisconnectNotify.len() > 0
    switch (reason) {
      case matching_errors.DisconnectReason.CalledByUser:
      case matching_errors.DisconnectReason.ForcedLogout:
      case matching_errors.DisconnectReason.SecondLogin:
        doLogout = true
        break
      //case matching_errors.DisconnectReason.ConnectionClosed:
      //case matching_errors.DisconnectReason.ForcedReconnect:
    }

    if (doLogout) {
      loginState.update(false)
      if (srvDisconnectNotify.len() > 0) {
        logoutNotify(clone srvDisconnectNotify)
        srvDisconnectNotify.clear()
      }
      else
        logoutNotify.update({reason = reason})
      logoutNotify.update(null)
    }
    else {
      local function reloginCb(result) {
        if ("error" in result) {
          loginState.update(false)
          logoutNotify.update({reason = matching_errors.DisconnectReason.ConnectionClosed})
          logoutNotify.update(null)
        }
      }
      delayedActions.add(@() self(loginInfo, reloginCb), 3000)
    }
  }

  performConnect(loginInfo, onDisconnect, login_cb, 0)
}

return {
  activate_matching_login = activate_matching_login
  deactivate_matching_login = deactivate_matching_login
  login_state = loginState
  connecting_state = connectingState
  logout_notify = logoutNotify
}
 