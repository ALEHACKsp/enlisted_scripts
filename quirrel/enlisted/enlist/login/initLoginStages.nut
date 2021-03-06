local platform = require("globals/platform.nut")
local { setStagesConfig } = require("enlist/login/login_chain.nut")
local defConfig = require("enlist/login/defaultLoginStages.nut")
local matchingStage = require("enlist/login/stages/matching.nut")
local pServerStage = require("pServerLoginStage.nut")
local { showStageErrorMsgBox } = require("enlist/login/login_cb.nut")
local { infoBlock, registerUrl } = require("enlist/login/ui/loginUiParams.nut")
local { activeTxtColor } = require("enlisted/enlist/viewConst.nut")
local { disableNetwork } = require("enlist/login/login_state.nut")

registerUrl("https://enlisted.net/en/#!/")

local mkOnInterrupt = @(defOnInterrupt) function(state) {
  if (state.stageResult?.error != "Maintenance") {
    defOnInterrupt(state)
    return
  }
  showStageErrorMsgBox(::loc("Maintenance"), state)
}

local config = ::Computed(function() {
  if (disableNetwork)
    return defConfig.value
  local res = clone defConfig.value
  res.stages = clone res.stages
  local idx = res.stages.indexof(matchingStage)
  if (idx == null || idx >= res.stages.len() - 1){
    res.stages.append(pServerStage)
  }
  else {
    res.stages.insert(idx + 1, pServerStage)
  }

  res.onInterrupt = mkOnInterrupt(res.onInterrupt)
  return res
})

setStagesConfig(config)

infoBlock({
  size = [sh(40), SIZE_TO_CONTENT]
  pos = [-sw(15), -sh(79.5)]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM

  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  font = Fonts.small_text
  color = activeTxtColor
  text = platform.is_xbox ? ::loc("xbox/betaInfo") : ::loc("hint/betaInfo")
})
 