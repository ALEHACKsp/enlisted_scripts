local steam = require("steam")
local { disableNetwork, linkSteamAccount } = require("enlist/login/login_state.nut")
local { get_arg_value_by_name } = require("dagor.system")

local loginCb = steam.is_running() ? require("enlist/login/login_cb_steam.nut") : require("enlist/login/login_cb.nut")

local isDMMLogin = get_arg_value_by_name("dmm_user_id") != null

return ::Computed(function() {
  local stages = []
  local stagesTail = [
    require("enlist/login/stages/auth_result.nut")
    require("enlist/login/stages/char.nut")
    require("enlist/login/stages/online_settings.nut")
    require("enlist/login/stages/eula.nut")
    require("enlist/login/stages/matching.nut")
  ]

  if (disableNetwork) {
    stages = [require("enlist/login/stages/fake.nut")]
    stagesTail = []
  }
  else if (isDMMLogin) {
    stages = [require("enlist/login/stages/dmm.nut")]
  }
  else if (!steam.is_running()) {
    // password login in gaijin-online
    stages = [require("enlist/login/stages/go.nut")]
    stagesTail.append(require("enlist/login/stages/save_login_data.nut"))
  }
  else if (!linkSteamAccount.value) {
    // steam login
    stages = [
      require("enlist/login/stages/steam.nut")
    ]
  }
  else {
    // password login followed by steam login which links go account to steam
    stages = [
      require("enlist/login/stages/go.nut")
      require("enlist/login/stages/steam_link.nut")
    ]
  }
  stages.extend(stagesTail)

  return {
    stages = stages
    onSuccess = loginCb.onSuccess
    onInterrupt = loginCb.onInterrupt
  }
})
 