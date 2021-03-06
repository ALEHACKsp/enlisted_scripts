local sharedWatched = require("globals/sharedWatched.nut")
local matching_api = require("matching.api")

local chatLogs = {}

local function getChatLog(chatId) {
  if (!(chatId in chatLogs)) {
    chatLogs[chatId] <- sharedWatched($"chat_{chatId}", @() [])
  }
  return chatLogs[chatId]
}

local function clearChatState(chatId) {
  if (chatId in chatLogs) {
    chatLogs[chatId].update([])
    // chatLogs is a 'cache' for sharedWatched
    // we can't remove keys from that cache unless they are not removable
    // in sharedWatched
    // delete chatLogs[chatId]
  }
}

local chat_handlers = {
  ["chat.chat_message"] = function(params) {
    local chatLog = getChatLog(params.chatId)
    chatLog.value.extend(params.messages)
    chatLog.trigger()
  },
  ["chat.user_joined"] = function(params) {
    log($"{params.user.name} joined chat")
  },
  ["chat.user_leaved"] = function(params) {
    log($"{params.user.name} leaved from chat")
  }
}

local function subscribeHandlers() {
  foreach(k, v in chat_handlers)
    matching_api.subscribe(k, v)
}

return {
  getChatLog = getChatLog
  clearChatState = clearChatState
  subscribeHandlers = subscribeHandlers
}
 