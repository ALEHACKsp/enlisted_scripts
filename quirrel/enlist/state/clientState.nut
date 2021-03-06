local {get_app_id} = require("app")
local {get_setting_by_blk_path} = require("settings")
local platform = require("globals/platform.nut")
local language = persist("language", @() Watched(get_setting_by_blk_path("language") ?? platform.get_language()))
local appId = persist("appId", @() Watched(get_app_id()))

if (platform.is_pc) {
  local online_storage_check = require_optional("onlineStorage")
  if (online_storage_check != null) {
    local onlineSettings = require("enlist/options/onlineSettings.nut")
    onlineSettings.onlineSettingUpdated.subscribe(function (...) {
      language(get_setting_by_blk_path("language") ?? platform.get_language())
    })
  }
}

return {
  language = language
  appId = appId
}
 