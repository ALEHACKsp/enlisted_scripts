local { isInBattleRumbleEnabled } = require("controls_online_storage.nut")

local comps = {comps_rq = ["rumbleEvents"]}
local findRumbleEvents = ::ecs.SqQuery("findRumbleEvents", comps)

local function setRumbleEnabled(eid, enabled){
  if (enabled)
    ::ecs.recreateEntityWithTemplates({eid = eid, addTemplates = ["rumble_enabled"]})
  else
    ::ecs.recreateEntityWithTemplates({eid = eid, removeTemplates = ["rumble_enabled"]})
}

isInBattleRumbleEnabled.subscribe(function(enabled) {
  findRumbleEvents(function(eid, comp) { setRumbleEnabled(eid, enabled) })
})

::ecs.register_es("rumble_ui_es", {
  onInit = @(evt,eid,comp) setRumbleEnabled(eid, isInBattleRumbleEnabled.value),
}, comps) 