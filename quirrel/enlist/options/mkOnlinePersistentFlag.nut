local mkOnlineSaveData = require("mkOnlineSaveData.nut")

local { watch, setValue } = mkOnlineSaveData("onlinePersistentFlags", @() {})

local function mkOnlinePersistentWatched(id, flag) {
  local function save(val) {
    if (val)
      setValue(watch.value.__update({ [id] = true }))
  }
  save(flag.value)
  flag.subscribe(save)
  return ::Computed(@() watch.value?[id] ?? flag.value ?? false)
}

local mkOnlinePersistentFlag = @(id) {
  flag = ::Computed(@() watch.value?[id] ?? false)
  activate = @() setValue(watch.value.__update({ [id] = true }))
}

console.register_command(@() setValue({}), "ui.resetPersistentFlags")
console.register_command(@()
  console_print("Persistent flags:", watch.value), "ui.printPersistentFlags")
console.register_command(function(id) {
  local val = !(watch.value?[id] ?? false)
  console_print($"Persistent flag {id} switched to {val}")
  setValue(watch.value.__update({ [id] = val }))
}, "ui.togglePersistentFlag")

return {
  mkOnlinePersistentWatched
  mkOnlinePersistentFlag
}
 