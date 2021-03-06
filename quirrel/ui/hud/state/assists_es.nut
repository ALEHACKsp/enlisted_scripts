local { isAimAssistEnabled } = require("controls_online_storage.nut")

local comps = {
  comps_rq = ["human_input"],
  comps_rw = [["human_input.aimAssistTargetSearchEnabled", ::ecs.TYPE_BOOL]]
}
local findHumanToAimAssist = ::ecs.SqQuery("findHumanToAimAssist", comps)

local function setAssistValToEntity(val, comp){
  comp["human_input.aimAssistTargetSearchEnabled"] = val
}

isAimAssistEnabled.subscribe(function(val) {
  findHumanToAimAssist.perform(function(eid, comp) {setAssistValToEntity(val, comp)})
})

::ecs.register_es("assists_ui_es", {
  onInit = @(evt,eid,comp) setAssistValToEntity(isAimAssistEnabled.value, comp),
}, comps)

 