local { TEAM_UNASSIGNED } = require("team")
local {INVALID_USER_ID} = require("matching.errors")
local {find_local_player, find_player_by_connid} = require("globals/common_queries.nut")
local {has_network, add_entity_in_net_scope, INVALID_CONNECTION_ID} = require("net")
local mapuserpointsevents = require("mapuserpointsevents")
local {startswith} = require("string")
local {sendLogToClients, getUserPermissions, DBG_PERMISSIONS} = require("game/utils/dedicated_debug_utils.nut")

local filtered_by_team_query = ::ecs.SqQuery("filtered_by_team_query", {comps_ro=[["team", ::ecs.TYPE_INT], ["connid",::ecs.TYPE_INT]], comps_rq=["player"], comps_no=["playerIsBot"]})
local notfiltered_byteam_query = {comps_ro=[["connid",::ecs.TYPE_INT]], comps_rq=["player"], comps_no=["playerIsBot"]}

local function find_connids_to_send(team_filter=null){
  local connids = []
  if (team_filter==null) {
    notfiltered_byteam_query.perform(function(eid, comp){
      connids.append(comp["connid"])
    }, "ne(connid,{0})")
  }
  else{
    filtered_by_team_query.perform(function(eid, comp){
      connids.append(comp["connid"])
    },"and(ne(connid,{0}), eq(team,{1}))".subst(INVALID_CONNECTION_ID,team_filter))
  }
  return connids
}


const SERVERCMD_PREFIX = "/servercmd"
const AUTOREPLACE_HERO = ":hero:"
const AUTOREPLACE_PLAYER = ":player:"

local function sendMessage(evt){
  local net = has_network()
  local senderEid = net ? find_player_by_connid(evt?.fromconnid ?? INVALID_CONNECTION_ID) : find_local_player()
  local senderTeam = ::ecs.get_comp_val(senderEid, "team", TEAM_UNASSIGNED)
  local senderName = ::ecs.get_comp_val(senderEid, "name", "")
  local senderBanStatus = ::ecs.get_comp_val(senderEid, "ban_status", "")
  local mode = evt?.mode ?? "team"
  local senderUserId = ::ecs.get_comp_val(senderEid, "userid", INVALID_USER_ID)
  local userPermissions = getUserPermissions(senderUserId)
  if (startswith(evt?.text ?? "", SERVERCMD_PREFIX) && (userPermissions?.send_server_commands || userPermissions==DBG_PERMISSIONS)){
    local text = evt.text.slice(SERVERCMD_PREFIX.len())
    local hero = ::ecs.get_comp_val(senderEid, "possessed", INVALID_ENTITY_ID)
    text = text.replace(AUTOREPLACE_HERO, $"{hero}")
    text = text.replace(AUTOREPLACE_PLAYER, $"{senderEid}")
    ::console.command($"net.set_console_connection_id {evt?.fromconnid ?? -1}")
    sendLogToClients(text)
    ::console.command(text)
    ::log($"console command '{text}' received userid:{senderUserId}")
    return
  }

  local data = { team = senderTeam, name = senderName, sender = senderEid, senderUserId = senderUserId }

  // /servercmd logerr 2
  if (net && senderBanStatus != "" && (mode == "all" || mode == "team")) {
    local text = ""
    if (senderBanStatus == "UNDEFINED")
      text = "chat/is_not_ready_yet"
    else
      text = "chat/not_allowed_to_write"

    data.__update({ text = text, qmsg = { item = "" } })
    local event = ::ecs.event.EventSqChatMessage(data)

    local connectionsToSend = [::ecs.get_comp_val(senderEid, "connid", INVALID_CONNECTION_ID)]

    ::ecs.server_msg_sink(event, connectionsToSend)
    ::log("Prevent broadcasting chat msg due to", text)
    return
  }

  data.__update({ text = evt?.text ?? "", qmsg = evt?.qmsg })
  local itemEid = evt?.eid ?? INVALID_ENTITY_ID
  local event = ::ecs.event.EventSqChatMessage(data)

  local connids = (mode == "team" || mode == "qteam")? find_connids_to_send(senderTeam) : null
  if (itemEid != INVALID_ENTITY_ID) {
    connids.map(@(connid) add_entity_in_net_scope(itemEid, connid))
    ::ecs.g_entity_mgr.sendEvent(senderEid, mapuserpointsevents.CmdAttachMapUserPoint(itemEid, "item"))
    ::ecs.server_send_event(itemEid, ::ecs.event.EventTeamItemHint(), connids.filter(@(connid) evt?.fromconnid != connid))
  }
  ::ecs.server_msg_sink(event, connids)
}

::ecs.register_es("chat_server_es", {
    [::ecs.sqEvents.CmdChatMessage] = @(evt,eid,comp) sendMessage(evt.data)
  },
  {comps_rq=["msg_sink"]}
)
 