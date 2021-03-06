local ipc_hub = require("ui/ipc_hub.nut")

local function mkOnlineSaveData(saveId, defValueFunc = @() null, validateFunc = @(v) v) {
  local watch = Watched(defValueFunc())
  local update = @(value) watch(validateFunc(value ?? defValueFunc()))
  watch.whiteListMutatorClosure(update)
  ipc_hub.subscribe($"onlineData.changed.{saveId}", @(msg) update(msg.value))
  ipc_hub.send({ msg = "onlineData.init", saveId = saveId })

  return {
    watch = watch
    setValue = function(value) {
      update(value)
      ipc_hub.send({ msg = "onlineData.setValue", saveId = saveId, value = value })
    }
  }
}

return mkOnlineSaveData 