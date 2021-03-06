local matching_api = require("matching.api")

local function createChat(cb) {
  matching_api.call("chat.create_chat",  cb, {})
}

local function joinChat(chatId, chatKey, cb) {
  matching_api.call("chat.join_chat", cb,
  {
    chatId = chatId
    chatKey = chatKey
  })
}

local function leaveChat(chatId, cb) {
  matching_api.call("chat.leave_chat", function(resp) {
    if (cb != null)
      cb(resp)
  },
  {
    chatId = chatId
  })
}

local function sendMessage(chatId, msg_txt) {
  matching_api.call("chat.send_chat_message", @(resp) null,
  {
    chatId = chatId,
    message = {
      text = msg_txt
    }
  })
}

return {
  createChat = createChat
  joinChat = joinChat
  leaveChat = leaveChat
  sendMessage = sendMessage
}
 