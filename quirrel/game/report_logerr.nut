local {get_setting_by_blk_path} = require("settings")
local {INVALID_CONNECTION_ID} = require("net")
local dedicated = require_optional("dedicated")
local dagorDebug = require("dagor.debug")
local {register_logerr_monitor, debug, clear_logerr_interceptors} = dagorDebug
local {DBGLEVEL} = require("dagor.system")
local {sendLogToClients} = require_optional("game/utils/dedicated_debug_utils.nut")
local {isInternalCircuit} = require("globals/appInfo.nut")

if (dedicated == null){
  ::ecs.register_es("enableLoggerrMsg",
    {
      [["onInit","onChange"]] = function(evt,eid,comp) {
        if (!comp.is_local || comp.connid==INVALID_CONNECTION_ID)
          return
        local enable = (DBGLEVEL > 0 || isInternalCircuit.value) ? true : get_setting_by_blk_path("debug/receiveServerLogerr")
        debug($"ask for dedicated logerr: {enable}")
        ::ecs.client_send_event(eid, ::ecs.event.CmdEnableDedicatedLogger({on = enable ?? (DBGLEVEL > 0)}))
      }
    },
    {
      comps_rq=["player"],
      comps_track = [["connid",::ecs.TYPE_INT], ["is_local", ::ecs.TYPE_BOOL]],
    },
    {tags="gameClient"}
  )
  return
}
clear_logerr_interceptors()

local function sendErrorToClient(tag, logstring, timestamp) {
  debug($"sending {logstring} to")
  sendLogToClients(logstring)
}

register_logerr_monitor([""], sendErrorToClient)
::ecs.register_es("enable_send_logerr_msg_es", {
    [::ecs.sqEvents.CmdEnableDedicatedLogger] = function(evt,eid,comp) {
      local on = evt.data?.on ?? false
      debug("setting logerr sending to '{3}', for connid:{0}, userid:{1}, username:'{2}'".subst(comp["connid"], comp["userid"], comp["name"], on))
      comp["receive_logerr"] = on
    }
  },
  {
    comps_ro = [
      ["name", ::ecs.TYPE_STRING, ""],
      ["connid", ::ecs.TYPE_INT],
      ["userid", ::ecs.TYPE_INT64, -1],
    ]
    comps_rq = ["player"]
    comps_rw = [["receive_logerr", ::ecs.TYPE_BOOL]]
  },
  {tags = "server"}
)

/*
local i=0
::ecs.set_callback_timer(
  function() {
    i++
    dagorDebug.logerr($"logerrnum: {i}")
  },
10, true)
*/
 