local dedicated = require_optional("dedicated")
local {get_dedicated_user_permissions = @(...) null} = require_optional("dedicated/users_permissions.nut")
local {get_client_user_permissions} = require("globals/client_user_permissions.nut")
local {isInternalCircuit} = require("globals/appInfo.nut")
local {INVALID_USER_ID} = require("matching.errors")
local {has_network, INVALID_CONNECTION_ID} = require("net")

local peersThatWantToReceiveQuery = ::ecs.SqQuery(
  "peersThatWantToReceiveQuery",
  {
    comps_ro = [["connid",::ecs.TYPE_INT], ["userid",::ecs.TYPE_INT64, INVALID_USER_ID], ["receive_logerr", ::ecs.TYPE_BOOL]],
    comps_rq=["player"]
  },
  "and(ne(connid, {0}), receive_logerr)".subst(INVALID_CONNECTION_ID)
)
const DBG_PERMISSIONS = "DBG_PERMISSIONS"

local function getUserPermissions(userid){
  if (isInternalCircuit.value)
    return DBG_PERMISSIONS
  if (has_network()){
    if (dedicated!= null)
      return get_dedicated_user_permissions(userid)?.receive_server_messages ?? false
    else
      return get_client_user_permissions(userid)?.receive_server_messages ?? false
  }
  return null
}
local function getConnidForLogReceiver(eid, comp){
  if ( getUserPermissions(comp["userid"]))
    return comp.connid
  return INVALID_CONNECTION_ID
}
local function sendLogToClients(log, connids=null){
  local event = ::ecs.event.EventSqChatMessage(({team=-1, name="dedicated", text=log}))
  if (!has_network())
    ::ecs.server_msg_sink(event, null)
  else {
    connids = connids==null ? (::ecs.query_map(peersThatWantToReceiveQuery, getConnidForLogReceiver) ?? []) : connids
    if (connids.len()>0)
      ::ecs.server_msg_sink(event, connids)
  }
}
return {
  sendLogToClients = sendLogToClients
  getConnidForLogReceiver = getConnidForLogReceiver
  DBG_PERMISSIONS = DBG_PERMISSIONS
  getUserPermissions = getUserPermissions
}
 