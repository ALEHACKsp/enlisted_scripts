local { setIntervalForUpdateFunc } = require("ui/helpers/timers.nut")
local { INVALID_USER_ID } = require("matching.errors")
local blacklist = require("globals/blacklist.nut")

local lines = persist("lines", @() Watched([]))
local totalLines = persist("totalLines", @() Watched(0))
local log = persist("log", @() Watched([]))
local outMessage = persist("outMessage",@() Watched(""))
local sendMode = persist("sendMode", @() Watched("team"))
local function updateChat(dt) {
  local modified = false
  for (local i=lines.value.len()-1; i>=0; --i) {
    local rec = lines.value[i]
    rec.ttl -= dt
    if (rec.ttl <= 0.0) {
      lines.value.remove(i)
      modified = true
    }
  }

  if (modified) {
    lines.trigger()
  }
}


setIntervalForUpdateFunc(0.45, updateChat)

local function pushMsg(sender_team, name_from, user_id_from, text, send_mode) {
  if (user_id_from in blacklist.value)
    return

  totalLines.update(totalLines.value+1)
  local l = lines
  local MAX_LINES = 10
  local MAX_LOG_LINES = 1000
  local rec = {
    team = sender_team
    name = name_from
    userId = user_id_from
    text = text
    sendMode = send_mode
  }

  l.update(function(val) {
    val.append(rec.__merge({ttl=15.0}))
    if (val.len()>MAX_LINES) {
      val.remove(0)
    }
  })

  log.update(function(val) {
    val.append(rec)
    if (val.len()>MAX_LOG_LINES) {
      val.remove(0)
    }
  })
}

local function sendChatCmd(params = {mode="team", text=""}) {
  params = params.__merge({mode=params?.mode ?? "team"})
  local evt = ::ecs.event.CmdChatMessage(params)
  ::ecs.client_msg_sink(evt)
}

local function mkTextFromQchatMsg(data) {
  //currently KISS for team hints and usual msg. Text is used as loc id or text itself
  return (type(data?.qmsg) == "table")
      ? ::loc(data?.text ?? "", {item=::loc(data.qmsg?.item ?? "", {count = data.qmsg?.count, nickname = data.qmsg?.nickname})})
      : data?.text ?? ""
}

local function onChatMessage(evt, eid, comp) {
  local data = evt?.data
  if (data==null)
    return
  local text = mkTextFromQchatMsg(data)
  local send_mode = data?.mode ?? "team"
  local sender_team_id = data?.team ?? 0
  local name_from = data?.name ?? "unknown"
  local userId = data?.senderUserId ?? INVALID_USER_ID
  pushMsg(sender_team_id, name_from, userId, text, send_mode)
}

::ecs.register_es("chat_client_es", {
    [::ecs.sqEvents.EventSqChatMessage] = onChatMessage
  }, {comps_rq = ["msg_sink"]}
)

return {
  lines = lines
  totalLines = totalLines
  log = log
  outMessage = outMessage
  sendMode = sendMode
  sendChatCmd = sendChatCmd

  update = updateChat
  pushMsg = pushMsg
}
 