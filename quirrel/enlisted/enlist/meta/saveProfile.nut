local saveload = require("enlisted/enlist/soldiers/model/saveload.nut")
local shutdownHandler = require("enlist/state/shutdownHandler.nut")
local get_time_msec = require("dagor.time").get_time_msec
local sharedWatched = require("globals/sharedWatched.nut")

local canSaveDefault = sharedWatched("saveProfile.canSave", @() true)

local function mkRequestSave(fileName, getSaveData, saveDelayMsec = 10000,
  canSave = canSaveDefault, needSave = Watched(false), saveRequested = Watched(-1)
) {
  local function save() {
    local data = getSaveData()
    saveload.save(fileName, data)
    needSave(false)
  }

  local function trySave() {
    if (canSave.value && needSave.value)
      save()
  }

  canSave.subscribe(@(can) trySave())
  shutdownHandler.add(@() needSave.value && save())

  local function requestSave() {
    needSave(true)
    if (saveRequested.value < get_time_msec()) {
      saveRequested(get_time_msec() + saveDelayMsec)
      ::gui_scene.setTimeout(0.001 * saveDelayMsec, trySave)
    }
  }
  return requestSave
}

return {
  load = saveload.load
  mkRequestSave = ::kwarg(mkRequestSave)
  canSave = canSaveDefault
}
 