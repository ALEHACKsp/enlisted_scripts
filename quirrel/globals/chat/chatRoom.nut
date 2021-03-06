local colors = require("ui/style/colors.nut")
local textInput = require("ui/components/textInput.nut")
local scrollbar = require("ui/components/scrollbar.nut")
local textButton = require("enlist/components/textButton.nut")
local chatState = require("globals/chat/chatState.nut")
local chatApi = require("globals/chat/chatApi.nut")
local time = require("dagor.time")

local function messageInLog(entry) {
  local fmtString = "%H:%H:%S"
  return {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    font = Fonts.small_text
    text = $"[{time.format_unixtime(fmtString, entry.timestamp)}] {entry.sender.name}: {entry.text}"
    key = entry.timestamp
    margin = sh(0.5)
    size = [flex(), SIZE_TO_CONTENT]
  }
}


local function chatRoom(chatId) {
  if (chatId == null)
    return null

  local formState = {
    chatMessage = Watched("")
  }


  local scrollHandler = ::ScrollHandler()


  local function doSendMessage() {
    chatApi.sendMessage(chatId, formState.chatMessage.value)
    formState.chatMessage.update("")
  }


  local function chatInputField() {
    local field = formState.chatMessage
    local options = {
      font = Fonts.small_text
      placeholder = ::loc("chat/inputPlaceholder")
      margin = 0
    }
    return {
      size = [flex(), SIZE_TO_CONTENT]
      children = textInput(field, options, { onReturn = doSendMessage })
    }
  }


  local function chatInput() {
    return {
      flow = FLOW_HORIZONTAL
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_BOTTOM
      gap = sh(1)
      padding = [sh(1), 0, 0, 0]

      children = [
        chatInputField
        {
          valign = ALIGN_BOTTOM
          size = [SIZE_TO_CONTENT, flex()]
          halign = ALIGN_RIGHT
          children = textButton(::loc("chat/sendBtn"), doSendMessage, {font=Fonts.small_text, margin=0})
        }
      ]
    }
  }

  local lastScrolledTo = null

  local function logContent() {
    local chatLog = chatState.getChatLog(chatId)
    if (chatLog == null)
      return {}
    local messages = chatLog.value.map(messageInLog)
    local scrollTo = chatLog.value.len() ? chatLog.value.top().timestamp : null

    return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      behavior = Behaviors.RecalcHandler

      watch = chatLog

      children = messages

      onRecalcLayout = function(initial) {
        if (scrollTo && scrollTo != lastScrolledTo) {
          lastScrolledTo = scrollTo
          scrollHandler.scrollToChildren(@(desc) ("key" in desc) && (desc.key == scrollTo), 2, false, true)
        }
      }
    }
  }


  local function chatLog() {
    return {
      size = flex()

      rendObj = ROBJ_FRAME
      color = colors.Inactive
      borderWidth = [2, 0]
      padding = [2, 0]

      children = scrollbar.makeVertScroll(logContent, {scrollHandler = scrollHandler})
    }
  }

  return function () {
    if (!chatState.getChatLog(chatId))
      return {}

    return {
      size = flex()
      flow = FLOW_VERTICAL
      stopMouse = true

      children = [
        chatLog
        chatInput
      ]
    }
  }
}


return chatRoom
 