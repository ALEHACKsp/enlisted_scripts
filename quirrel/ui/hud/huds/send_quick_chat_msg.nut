local function sendChatMsg(params) { //should be some enum
  local evt = ::ecs.event.CmdChatMessage(params)
  ::ecs.client_msg_sink(evt)
}

local function sendQuickChatItemMsg(text, item_name=null) {
  sendChatMsg({mode="qteam", text = text, qmsg={item=item_name}})
}

local function sendItemHint(item_name, item_eid, item_count, item_owner_nickname) {
  sendChatMsg({mode="qteam", text= "squad/item_hint", qmsg={item=item_name, count = item_count, nickname = item_owner_nickname}, eid = item_eid/*, showOnMap = true*/})
}

return {
  sendQuickChatMsg = sendQuickChatItemMsg
  sendQuickChatItemMsg = sendQuickChatItemMsg
  sendItemHint = sendItemHint
} 