local {strip} = require("string")
local {get_setting_by_blk_path} = require("settings")

local appBgImages = (get_setting_by_blk_path("bgImage") ?? "")
  .split(";")
  .map(strip)
  .filter(@(v) v!="")

return {
  appBgImages = appBgImages
}
 