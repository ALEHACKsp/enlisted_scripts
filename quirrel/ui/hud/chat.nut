local scrollbar = require("ui/components/scrollbar.nut")
local {CONTROL_BG_COLOR, TEAM1_TEXT_COLOR, TEAM0_TEXT_COLOR} = require("style.nut")
local chatState = require("state/chat.nut")
local {setInteractiveElement} = require("state/interactive_state.nut")
local {localPlayerTeam, localPlayerName} = require("state/local_player.nut")
local dagor_sys = require("dagor.system")
local remap_nick = require("globals/remap_nick.nut")
local JB = require("ui/control/gui_buttons.nut")
local {sound_play} = require("sound")
local {UserNameColor} = require("ui/style/colors.nut")
local { showInventory } = require("ui/hud/menus/inventory.nut")

local showChatInput = persist("showChatInput", @() Watched(false))

local settings = {
  switchSendModesAllowed = dagor_sys.DBGLEVEL > 0
}

local inputBoxHeight = sh(8)

local itemTextAnim = [
//  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.2, play=true, easing=OutCubic }
//  { prop=AnimProp.opacity, from=0.5, to=1, duration=0.2, play=true}
//  { prop=AnimProp.scale, from=[1,1], to=[1,0.01], duration=0.4, playFadeOut=true}
]

local itemGap = {size=[0,hdpx(1)]}

local itemAnim = [
  { prop=AnimProp.opacity, from=1.0, to=0, duration=0.6, playFadeOut=true}
  { prop=AnimProp.scale, from=[1,1], to=[1,0.01], delay=0.4, duration=0.6, playFadeOut=true}
]

local function chatItem(item, params={}){
  local text = $"{remap_nick(item.name)}: {item.text}"
  local color = item.team == localPlayerTeam.value
    ? TEAM0_TEXT_COLOR
    : TEAM1_TEXT_COLOR

  return {
    size = [flex(), SIZE_TO_CONTENT]
    key = item
    flow = FLOW_VERTICAL
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(200,200,200,200)
    children = [
      {
        flow = FLOW_HORIZONTAL
        key = item
        transform = { pivot = [0, 1.0] }
        size = [flex(), SIZE_TO_CONTENT]
        animations = (params?.noanim) ? null : itemTextAnim
        children = [
          (item.sendMode != "all") ? null
            : {
                rendObj = ROBJ_DTEXT, color = color, text = $"[{::loc("chat/all")}]"
              }

          {
            rendObj = ROBJ_DTEXT,
            color = item.name == localPlayerName.value ? UserNameColor : color,
            text = $"{remap_nick(item.name)}: "
          }
          { rendObj = ROBJ_TEXTAREA, behavior = Behaviors.TextArea, color = color, text = item.text, size = [flex(), SIZE_TO_CONTENT] }
        ]
      }
    ]
    transform = {
      pivot = [0, 0]
    }
    animations = (params?.noanim) ? null :itemAnim
  }
}

local lastScrolledTo = null
local scrollHandler = ::ScrollHandler()

local function chatLog() {
  local logLines = chatState.log.value.map(@(line) chatItem(line, {noanim=true}))
  local scrollTo = chatState.log.value.len() ? chatState.log.value.top() : null
  local chatLogContent = @(){
    key = "chatLog"
    size = [flex(),SIZE_TO_CONTENT]
    minHeight = SIZE_TO_CONTENT
    clipChildren = true
    gap = itemGap
    flow = FLOW_VERTICAL
    children = logLines
    behavior = Behaviors.RecalcHandler
    onRecalcLayout = function(initial) {
      if (scrollTo && scrollTo != lastScrolledTo) {
        lastScrolledTo = scrollTo
        scrollHandler.scrollToChildren(@(desc) ("key" in desc) && (desc.key == scrollTo), 2, false, true)
      }
    }
    watch = chatState.log
  }
  return {
    size = [flex(), flex()]
    flow = FLOW_VERTICAL
    children = scrollbar.makeVertScroll(chatLogContent, {scrollHandler = scrollHandler})
    vplace = ALIGN_BOTTOM
  }
}


local function chatContent() {
  local children = chatState.lines.value.map(chatItem)

  return {
    key = "chatContent"
    size = [flex(), flex()]
    clipChildren = true
    children = children
    valign = ALIGN_BOTTOM
    gap = itemGap
    flow = FLOW_VERTICAL
    watch = [chatState.lines, localPlayerTeam]
//    behavior = Behaviors.SmoothScrollStack
//    speed = sh(8)
  }
}


local function inputBox() {
  local textInput = {
    rendObj = ROBJ_SOLID
    color = CONTROL_BG_COLOR
    vplace = ALIGN_TOP
    size = [flex(), SIZE_TO_CONTENT]

    children = [
      function() {
        return {
          rendObj = ROBJ_DTEXT
          size = [flex(), fontH(120)]
          margin = sh(0.5)
          text = chatState.outMessage.value
          watch = chatState.outMessage
          behavior = Behaviors.TextInput
          function onChange(text) {
            chatState.outMessage(text)
          }
          function onAttach(elem) {
            ::set_kb_focus(elem)
            ::set_mouse_capture(elem)
          }
          function onReturn() {
            if (chatState.outMessage.value.len()>0) {
              chatState.sendChatCmd({mode = chatState.sendMode.value, text = chatState.outMessage.value})
            }
            chatState.outMessage("")
            showChatInput(false)
          }
          hotkeys = [
            [$"Esc | {JB.B}", function() {
              chatState.outMessage("")
              showChatInput(false)
            }, "Close chat"]
          ]
        }
      }
    ]
  }

  local function sendModeText() {
    local mode = chatState.sendMode.value
    if (mode == "all")
      return ::loc("chat/all")
    if (mode == "team")
      return ::loc("chat/team")
    return "???"
  }

  local modesHelp = {
    vplace = ALIGN_BOTTOM
    size = [flex(), sh(3)]
    children = [
      {
        rendObj = ROBJ_DTEXT
        vplace = ALIGN_CENTER
        font = Fonts.small_text
        text = ::loc("chat/help/short")
        color = Color(180, 180, 180, 180)
      }
      @() {
        rendObj = ROBJ_DTEXT
        vplace = ALIGN_CENTER
        hplace = ALIGN_RIGHT
        font = Fonts.medium_text
        watch = chatState.sendMode
        text = sendModeText()
      }
    ]
  }

  local function switchSendModes() {
    local newMode = chatState.sendMode.value == "all" ? "team" : "all"
    if (settings.switchSendModesAllowed)
      chatState.sendMode(newMode)
  }

  return {
    size = [flex(), inputBoxHeight]
    flow = FLOW_VERTICAL

    hotkeys = settings.switchSendModesAllowed ? [ ["^Tab", switchSendModes] ] : null

    children = [
      textInput
      settings.switchSendModesAllowed ? modesHelp : null
    ]
  }
}


local allowToShowChat = Computed(@() !showInventory.value)
local hasInteractiveChat = keepref(Computed(@() allowToShowChat.value && showChatInput.value))


hasInteractiveChat.subscribe(@(new_val) setInteractiveElement("chat", new_val))


local inputBoxDummy = {size=[flex(), inputBoxHeight]}

local function chatRoot() {
  local children = null
  if (allowToShowChat.value) {
    if (showChatInput.value) {
      children = [chatLog,inputBox]
    } else {
      children = [chatContent,inputBoxDummy]
    }
  }

  return {
    key = "chat"
    flow = FLOW_VERTICAL
    size = [flex(), sh(24)]

    watch = [showChatInput, allowToShowChat]

    children = children
  }
}

chatState.totalLines.subscribe(@(v) sound_play("ui/new_log_message"))

return {
  chatRoot = chatRoot
  settings = settings
  showChatInput = showChatInput
}
 