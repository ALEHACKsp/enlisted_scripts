local { update_profile, get_all_configs } = require("enlisted/enlist/meta/clientApi.nut")
local { updateAllConfigs } = require("enlisted/enlist/configs/configs.nut")

local updateList = [
  { id = "update_profile", request = update_profile }
  { id = "get_all_configs", request = get_all_configs, onSuccess = updateAllConfigs }
]
local ALL = (1 << updateList.len()) - 1

local function startRequest(data, idx, shared) {
  local { id, request, onSuccess = @(res) null } = data
  request(function cb(res) {
    if (shared.isFailed)
      return //not actual answer
    shared.result[id] <- res
    if (res?.error != null) {
      shared.isFailed = true
      shared.result.error <- res.error
      shared.onAllFinishCb(shared.result)
      return
    }
    onSuccess(res)
    shared.current += 1 << idx
    if (shared.current == ALL)
      shared.onAllFinishCb(shared.result)
  }, shared.token)
}

return {
  id = "pServerProfileAndConfigs"
  function action(processState, cb) {
    local token = processState.stageResult.auth_result.token
    local shared = { current = 0, result = {}, onAllFinishCb = cb, isFailed = false, token = token }
    updateList.each(@(data, idx) startRequest(data, idx, shared))
  }
} 