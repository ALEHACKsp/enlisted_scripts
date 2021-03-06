local app = require("enlist.app")

return {
  id = "save_login_data"
  function action(state, cb) {
    local params = state.params
    app.local_storage.hidden.set_value("login",
      (params?.saveLogin && params.login_id.len()) ? params.login_id : null)
    app.local_storage.hidden.set_value("password", params?.savePassword ? params.password : null)
    cb({})
  }
} 