local { eulaVersion, showEula } = require("enlist/eula/eula.nut")
local platform = require("globals/platform.nut")

local onlineSettings = require("enlist/options/onlineSettings.nut")
local eulaEnabled = (platform.is_xbox || platform.is_sony || platform.is_nswitch)
local function action(login_status, cb) {
  if (!eulaEnabled) {
    log("eula check disabled")
    cb({})
    return
  }

  log($"eulaVersion {eulaVersion}")
  if (onlineSettings.settings.value?["acceptedEULA"] != eulaVersion) {
    showEula(function(accept) {
      log("showEula")
      if (accept) {
        onlineSettings.settings.update(@(value) value["acceptedEULA"] <- eulaVersion)
        cb({})
      }
      else
        cb({stop = true})
    })
  }
  else {
    cb({})
  }
}

return {
  id  = "eula"
  action = action
} 