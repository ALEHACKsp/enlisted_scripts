local {has_network} = require("net")
local sessionId = Watched(null)
local {EventLevelLoaded} = require("gameevents")
local { get_session_id } = require("app")

//not sure if this is the best way to handle sessionId in game. It can be straightforward with native Observable
if (has_network()){
  ::ecs.register_es(
    "session_id_ui_es",
    {[EventLevelLoaded] = @(evt, eid, comp) sessionId.update(get_session_id())}
  )
}
return sessionId 