local userInfo = require("enlist/state/userInfo.nut")

local {has_network} = require("net")

::ecs.register_es(
  "fix_local_player_name_es",
  {
    [["onChange","onInit", ::ecs.sqEvents.EventLocalPlayerNameChanged]] = function(evt, eid, comp){
      if (!(comp.is_local) || has_network())
        return
      if (userInfo.value?.name != null && comp["name"]=="{Local Player}") { //warning disable: -forgot-subst
        comp["name"] = userInfo.value.name
      }
    }
  },
  {
    comps_rq = ["player"],
    comps_track = [["is_local", ::ecs.TYPE_BOOL]],
    comps_rw = [["name", ::ecs.TYPE_STRING]]
  }
)

::ecs.register_es("handle_localplayer_name_changed_es",
  {onChange = @(evt, eid, comp) ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventLocalPlayerNameChanged())},
  {comps_rq=["is_local", "player"], comps_track=[["name", ::ecs.TYPE_STRING]]}
) 