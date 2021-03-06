local matchingCli = require("enlist/matchingClient.nut")

return {
  id = "matching"
  function action(processState, cb) {
    local stageResult = processState.stageResult
    local uinfo = {
      userId = stageResult.auth_result.userId
      name = stageResult.auth_result.name
      chardToken = stageResult.char.chard_token
    }
    matchingCli.startLogin(uinfo, cb)
  }
  actionOnReload = @(state, cb) null
}
 