local msgbox = require("enlist/components/msgbox.nut")
local matching_api = require("matching.api")
local matching_errors = require("matching.errors")
local connectHolder = require("matching/connectHolderR.nut")
local loginState = require("enlist/login/login_state.nut")
local appInfo =  require("globals/appInfo.nut")
local platform = require("globals/platform.nut")
local nswitchNetwork = platform.is_nswitch ? require("nswitch.network") : null

local matchingLoginActions = []

loginState.isLoggedIn.subscribe(function(val) {
  if (!val)
    connectHolder.deactivate_matching_login()
})

local function netStateCall(func) {
  if (connectHolder.login_state.value == true)
    func()
  else
    matchingLoginActions.append(func)
}

local mkDetailsDisconnect = platform.is_nswitch
         ? @() { text = ::loc("Details"), action = @() nswitchNetwork.handleRequestAndShowError() }
         : null


local function matchingCall(cmd, cb, params=null) {
  netStateCall(function() { matching_api.call(cmd, cb, params) })
}

local function matchingNotify(cmd, params=null) {
  netStateCall(function() { matching_api.notify(cmd, params) })
}

local function startLogin(userInfo, login_cb) {
  local function loginCb(result) {
    if (result?.error) {
      matchingLoginActions = []
      loginState.logOut()
    }
    login_cb(result)
  }

  local loginInfo = {
    userId = userInfo.userId
    userName = userInfo.name
    token = userInfo.chardToken
    versionStr = appInfo.version.value
  }

  connectHolder.activate_matching_login(loginInfo, loginCb)
}

connectHolder.login_state.subscribe(function(logged) {
  if (logged == false) {
    matchingLoginActions = []
    loginState.logOut()
  }
  else {
    local actions = matchingLoginActions
    matchingLoginActions = []
    foreach (act in actions)
      act()
  }
})

connectHolder.logout_notify.subscribe(function(notify) {
  if (notify == null)
    return

  if (notify.reason == matching_errors.DisconnectReason.ConnectionClosed) {
    local buttons = [{ text = ::loc("Ok"), isCurrent = true, action = @() null }]
    local detailsBtn = mkDetailsDisconnect?()
    if (detailsBtn != null)
      buttons.append(detailsBtn)
    msgbox.show({
      text = ::loc("error/CLIENT_ERROR_CONNECTION_CLOSED")
      buttons = buttons
    })
  }
  else
    msgbox.show({text=::loc("msgboxtext/matchingDisconnect",
      { error = ::loc("error/{0}".subst(matching_errors.disconnect_reason_string(notify.reason))) })})

})

matching_api.subscribe("mlogin.update_online_info", @(info) info)

return {
  connected = connectHolder.login_state
  connecting = connectHolder.connecting_state
  call = matchingCall
  notify = matchingNotify
  startLogin = startLogin
  netStateCall = netStateCall
}
 