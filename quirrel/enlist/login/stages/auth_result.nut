return {
  id = "auth_result"
  function action(state, cb) {
    require("auth").get_user_info(
      require("enlist/login/stages/auth_helpers.nut").status_cb(cb))
  }
}
 