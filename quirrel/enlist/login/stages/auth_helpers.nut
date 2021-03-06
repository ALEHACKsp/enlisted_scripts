local auth  = require("auth")

local function status_cb(cb) {
  return function(result) {
    if (result?.status != auth.YU2_OK)
      result.error <- auth.status_string_full(result.status)
    cb(result)
  }
}

return {
  status_cb = status_cb
}

 