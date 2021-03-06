local {playerEvents} = require("eventlog.nut")
local {CmdHeroLogEvent} = require("gameevents")


local function onCmdHeroLogEvent(evt, eid, comp){
  playerEvents.pushEvent({event=evt[0], text = ::loc(evt[1]), myTeamScores=false, ttl = evt[2] && evt[2] > 0 ? evt[2] : null})
}
::ecs.register_es("cmd_hero_log_event_es",
  { [CmdHeroLogEvent] = onCmdHeroLogEvent },
  { comps_rq = ["hero"] }
)

::ecs.register_es("cmd_hero_log_ex_event_es",
  { [::ecs.sqEvents.CmdHeroLogExEvent] = function onCmdHeroLogExEvent(evt, eid, comp) {
      local e = {event=evt.data["_event"], text=::loc(evt.data["_key"], evt.data), myTeamScores=false}
      playerEvents.pushEvent(e)
    }
  },
  { comps_rq = ["hero"] }, {tags="gameClient"}
)

::ecs.register_es("cmd_player_log_event_es",
  { [CmdHeroLogEvent] = function onCmdPlayerLogEvent(evt, eid, comp) {
      if (!comp.is_local)
        return
      onCmdHeroLogEvent(evt, eid, comp)
    }
 },
  {comps_ro = [["is_local", ::ecs.TYPE_BOOL]], comps_rq = ["possessed"] }
) 