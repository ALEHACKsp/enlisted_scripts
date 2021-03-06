local serverConfigs = persist("serverConfig", @() Watched({}))

local function updateAllConfigs(newValue) {
  local configs = newValue?.configs
  if (configs) {
    serverConfigs(configs)
  }
}
serverConfigs.whiteListMutatorClosure(updateAllConfigs)

return {
  configs = serverConfigs
  updateAllConfigs = updateAllConfigs
}
 