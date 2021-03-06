local json = require("std/json.nut")
local debriefingState = require("debriefingStateInMenu.nut") //can be overrided by game
local { dbgShow, dbgData } = require("debriefingDbgState.nut")

local cfg = {
  state = debriefingState
  savePath = "debriefing.json"
  samplePath = ["../prog/scripts/enlist/debriefing/debriefing_sample.json"]
  loadPostProcess = function(debriefingData) {} //for difference in json saving format, as integer keys in table
}

local saveDebriefing = @(path = null)
  json.save(path ?? cfg.savePath, cfg.state.data.value, {logger = log_for_user})

local function loadDebriefing(path = null) {
  path = path ?? cfg.savePath
  local data = json.load(path, { logger = log_for_user })
  if (data == null)
    return false

  cfg.loadPostProcess(data)
  dbgData(data)
  dbgShow(true)
  return true
}

local function mkSessionPath(sessionId) {
  local idx = cfg.savePath.indexof(".")
  if (idx == null)
    return $"{cfg.savePath}_{sessionId}"
  return "{0}_{1}{2}".subst(cfg.savePath.slice(0, idx), sessionId, cfg.savePath.slice(idx))
}
local saveDebriefingBySession = @()
  saveDebriefing(mkSessionPath(cfg.state.data.value?.sessionId ?? "0"))

local loadSample = @(idx) loadDebriefing(cfg.samplePath[idx])

::console.register_command(@() loadSample(0), "ui.debriefing_sample")
::console.register_command(@() saveDebriefing(), "ui.debriefing_save")
::console.register_command(@() loadDebriefing(), "ui.debriefing_load")
::console.register_command(@() saveDebriefingBySession(), "ui.debriefing_save_by_session")
::console.register_command(@(sessionId) loadDebriefing(mkSessionPath(sessionId)), "ui.debriefing_load_by_session")

return {
  init = function(params) {
    cfg = cfg.__merge(params.filter(@(value, key) key in cfg))
    for(local i = 1; i < cfg.samplePath.len(); i++) {
      local idx = i
      ::console.register_command(@() loadSample(idx), $"ui.debriefing_sample{idx+1}")
    }
  }
}
 