local {Alert,Inactive} = require("ui/style/colors.nut")
local mailboxState = require("mailboxState.nut")
local {isMailboxVisible} = mailboxState
local {sound_play} = require("sound")
local squareIconButton = require("enlist/components/squareIconButton.nut")
local mailboxWndOpen = require("mailboxBlock.nut")

local animsCounter = [
  {prop = AnimProp.scale from =[2.1, 2.1] to = [1.0,1.0]  duration = 0.9 trigger="new_mail" easing = OutCubic}
]
local soundNewMail = "ui/enlist/notification"

local function readNumCounter(){
  local num = mailboxState.inbox.value.len()-mailboxState.readNum.value
  if (num < 1)
    num = ""
  return {
    rendObj = ROBJ_DTEXT
    text = num
    hplace = ALIGN_RIGHT
    watch = [mailboxState.readNum,mailboxState.inbox]
    vplace = ALIGN_TOP
    key = num
    font = Fonts.small_text
    pos = [-hdpx(3), hdpx(4)]
    fontFx = FFT_GLOW
    transform = {pivot =[0.5,0.5]}
    fontFxColor = Color(0, 0, 0, 255)
    animations = animsCounter
  }
}
local inboxNum = mailboxState.inbox.value.len()
mailboxState.inbox.subscribe(function(new_val) {
  if (new_val.len() > inboxNum) {
    sound_play(soundNewMail)
    anim_start("new_mail")
  } else {
    anim_request_stop("new_mail")
  }
  inboxNum = new_val.len()
})

return function() {
  return {
    watch = [mailboxState.hasUnread, isMailboxVisible]
    children = [
      squareIconButton({
        onClick = mailboxWndOpen
        tooltipText = ::loc("tooltips/mailboxButton")
        iconId = "envelope"
        selected = isMailboxVisible
        key = mailboxState.hasUnread.value
        animations = mailboxState.hasUnread.value
          ? [{prop = AnimProp.scale, from =[1.0, 1.0], to = [1.1, 1.1], duration = 1.3, loop = true, play = true, easing = CosineFull }]
          : null
      }, {
        animations = mailboxState.hasUnread.value
          ? [{prop = AnimProp.color, from = Inactive, to = Alert, duration = 1.3, loop = true, play = true, easing = CosineFull }]
          : null
      })
      readNumCounter
    ]
  }
}
 