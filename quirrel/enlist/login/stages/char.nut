local charClient = require("enlist/charClient.nut")

return {
  id = "char"
  action = @(login_state, cb) charClient.char_login(login_state.stageResult.auth_result.token, cb)
}
 