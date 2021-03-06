local loginState = require("enlist/login/login_state.nut")
local lowLevelCharClient = require("charClient.nut").low_level_client
local userstat = require_optional("userstats")
local inventory = require_optional("inventory")

loginState.isLoggedIn.subscribe(function(logged) {
  if (logged == false) {
    lowLevelCharClient?.clearCallbacks()
    inventory?.clearCallbacks()
    userstat?.clearCallbacks()
  }
}) 