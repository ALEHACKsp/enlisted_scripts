local {get_sync_time} = require("net")
local {sound_play} = require("sound")

local warningsList = persist("warningsList", @() Watched([]))

local WARNING_PRIORITIES = {
  HIGH = 0
  MEDIUM = 1
  LOW = 2
  ULTRALOW = 3
}

local possibleWarningsList = {}

::assert(possibleWarningsList.len()==0, "should be added only where it used")

local function addWarnings(wList) {
  possibleWarningsList.__update(wList)
}

local updateWarinigsTime = @() null //fwd declaration
local function setWarningsList(list) {
  local curTime = get_sync_time()
  list = list.filter(@(v) v.showEndTime <= 0 || v.showEndTime > curTime)
    .sort(@(a, b) a.priority <=> b.priority || a.showEndTime <=> b.showEndTime || a.id <=> b.id)
  warningsList(list)

  local closestWarningTime = list
    .reduce(@(res, w) w.showEndTime > 0 && (res <= 0 || res > w.showEndTime) ? w.showEndTime : res, 0)
  if (closestWarningTime > 0)
    ::gui_scene.resetTimeout(closestWarningTime - curTime, updateWarinigsTime)
}
warningsList.whiteListMutatorClosure(setWarningsList)

updateWarinigsTime = @() setWarningsList(warningsList.value)


local function warningShow(warningId) {
  local wparams = possibleWarningsList?[warningId]
  if (wparams == null) {
    log($"Failed to add warning {warningId} it does not exist in possibleWarningsList")
    return
  }

  local list = warningsList.value
  local curWarning = list.findvalue(@(w) w.id == warningId)
  local newWarning = {
    id = warningId
    locId = wparams?.locId ?? warningId
    priority = wparams.priority
    showEndTime = "timeToShow" in wparams ? get_sync_time() + wparams.timeToShow : -1
    color = wparams?.color
  }
  if (curWarning)
    curWarning.__update(newWarning)
  else
    list.append(newWarning)
  setWarningsList(list)

  local snd = wparams?.getSound()
  if (snd != null)
    sound_play(snd)
}

local function warningHide(warningId) {
  local idx = warningsList.value.findindex( @(v) v.id == warningId )
  if (idx == null)
    return
  warningsList.value.remove(idx)
  setWarningsList(warningsList.value)
}

local warningUpdate = @(warningId, shouldShow)
  shouldShow ? warningShow(warningId) : warningHide(warningId)


::console.register_command(function(idx=0) {
  local id = idx in possibleWarningsList ? idx
    : (possibleWarningsList.keys()?[idx] ?? possibleWarningsList.keys()?[0])
  local isVisible = warningsList.value.findindex(@(w) w.id == id) != null
  warningUpdate(id, !isVisible)
}, "ui.warning_debug")

return {
  warningsList = warningsList
  warningShow = warningShow
  warningHide = warningHide
  addWarnings = addWarnings
  warningUpdate = warningUpdate
  WARNING_PRIORITIES = WARNING_PRIORITIES
}

 