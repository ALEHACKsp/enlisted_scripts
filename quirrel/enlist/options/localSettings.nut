local {get_setting_by_blk_path, set_setting_by_blk_path_and_save} = require("settings")
return function(settingsPath, write = true) {
  // value-key order is for table.map
  return function(defVal, saveId) {
    local key = "".concat(settingsPath,saveId)
    local watch = Watched(get_setting_by_blk_path(key) ?? defVal)
    if (write)
      watch.subscribe(@(val) set_setting_by_blk_path_and_save(key, val))
    return watch
  }
}
 