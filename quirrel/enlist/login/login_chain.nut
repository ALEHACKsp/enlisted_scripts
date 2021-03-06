local {isEqual} = require("std/underscore.nut")
local {get_time_msec} = require("dagor.time")
local statsd = require("statsd")
local regexp2 = require("regexp2")
local log = require("std/log.nut")().with_prefix("[LOGIN_CHAIN]")

local stagesOrder = persist("stagesOrder", @() [])
local currentStage = persist("currentStage", @() Watched(null))
local processState = persist("processState", @() {})
local globalInterrupted = persist("interrupted", @() Watched(false))
local afterLoginOnceActions = persist("afterLoginOnceActions", @() [])

local statsFbdRe = regexp2(@"[^[:alnum:]]")
local STEP_CB_ACTION_ID = "login_chain_step_cb"

currentStage.subscribe(@(stage) log($"Login stage -> {stage}"))

local stagesConfig = ::Watched(null)
local isStagesInited = ::Watched(false)
local stages = {}
local onSuccess = null //@(processState)
local onInterrupt = null //@(processState)
local startLoginTs = -1
local loginTime = persist("loginTime", @() Watched(0))

local function makeStage(stageCfg) {
  local res = {
    id = ""
    action = @(state, cb) cb()
    actionOnReload = null
  }.__update(stageCfg)

  if (res.actionOnReload == null)
    res.actionOnReload = res.action
  return res
}
local persistActions = persist("persistActions", @() {})
local function makeStageCb() {
  local curStage = currentStage.value
  return @(result) persistActions[STEP_CB_ACTION_ID](curStage, result)
}

local reportLoginEnd = @(reportKey) statsd.send_profile("login_time", get_time_msec() - startLoginTs, {status=reportKey})

local function startStage(stageName) {
  currentStage(stageName)
  stages[stageName].action(processState, makeStageCb())
}

local function curStageActionOnReload() {
  stages[currentStage.value].actionOnReload(processState, makeStageCb())
}

local function startLogin(params) {
  assert(currentStage.value == null)
  assert(stagesOrder.len() > 0)

  processState.clear()
  processState.params <- params
  processState.stageResult <- {}
  processState.userInfo <- "userInfo" in params ? clone params.userInfo : {}

  startLoginTs = get_time_msec()
  globalInterrupted(false)

  startStage(stagesOrder[0])
}

local function fireAfterLoginOnceActions() {
  local actions = clone afterLoginOnceActions
  afterLoginOnceActions.clear()
  foreach(action in actions)
    action()
}

local function onStageResult(result) {
  local stageName = currentStage.value
  processState.stageResult[stageName] <- result
  if (result?.status != null)
    processState.status <- result.status

  local errorId = result?.error
  if (errorId != null) {
    processState.stageResult.error <- errorId
    statsd.send_counter("login_fail.{0}".subst(stageName), 1, {error=statsFbdRe.replace("_", errorId)} )
    log("login failed {0}: {1}".subst(stageName, errorId))
  }

  local needErrorMsg = result?.needShowError ?? true
  processState.stageResult.needShowError <- needErrorMsg

  foreach (key in ["errorWithLink", "quitBtn"])
    if (key in result)
      processState.stageResult[key] <- result[key]

  if (errorId != null || result?.stop == true || globalInterrupted.value == true) {
    processState.interrupted <- true
    currentStage(null)
    reportLoginEnd("failure")
    afterLoginOnceActions.clear()
    onInterrupt?(processState)
    return
  }

  local idx = stagesOrder.indexof(stageName)
  if (idx == stagesOrder.len() - 1) {
    loginTime.update(get_time_msec())
    currentStage(null)
    reportLoginEnd("success")
    onSuccess?(processState)
    fireAfterLoginOnceActions()
    return
  }

  startStage(stagesOrder[idx + 1])
}

persistActions[STEP_CB_ACTION_ID] <- function(curStage, result) {
  if (curStage == currentStage.value)
    onStageResult(result)
  else
    log($"Receive cb from stage {curStage} but current is {currentStage.value}. Ignored.")
}

local function makeStages(config) {
  assert(currentStage.value == null || stages.len() == 0)

  local prevStagesOrder = clone stagesOrder
  stagesOrder.clear()
  stages.clear()

  foreach(stage in config.stages) {
    assert(("id" in stage) && ("action" in stage), " login stage must have id and action")
    assert(!(stage.id in stages), " duplicate stage id")
    stages[stage.id] <- makeStage(stage)
    stagesOrder.append(stage.id)
  }
  isStagesInited(stages.len() > 0)

  onSuccess = config.onSuccess
  onInterrupt = config.onInterrupt

  if (currentStage.value == null)
    return

  if (!isEqual(prevStagesOrder, stagesOrder)) {
    //restart login process
    log("Full restart")
    currentStage(null)
    startLogin(processState?.params ?? {})
  }
  else {
    //continue login process
    log($"Reload stage {currentStage.value}")
    curStageActionOnReload()
  }
}

local function setStagesConfig(configWatch) {
  stagesConfig.unsubscribe(makeStages)
  stagesConfig = configWatch
  stagesConfig.subscribe(makeStages)
  makeStages(stagesConfig.value)
}

return {
  loginTime = loginTime
  currentStage = currentStage
  startLogin = startLogin
  interrupt = @() globalInterrupted(true)
  setStagesConfig = setStagesConfig //should be called on scripts load to correct continue login after reload scripts.
  isStagesInited = isStagesInited
  doAfterLoginOnce = @(action) afterLoginOnceActions.append(action) //only persist or native actions will work correct in all cases
}
 