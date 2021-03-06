local auth  = require("auth")
local ah = require("auth_helpers.nut")

return {
  id = "auth_go"
  function action(state, cb) {
    local login_id = state.params.login_id
    local password = state.params.password
    local two_step_code = state.params?.two_step_code

    if (two_step_code) {
      auth.login_2step(login_id, password, two_step_code, ah.status_cb(cb))
    } else {
      auth.login(login_id, password, ah.status_cb(cb))
    }
  }
  actionOnReload = @(state, cb) null
}
 