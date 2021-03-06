local {actionTimer} = require("enlisted/ui/hud/state/fortification_builder_action.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local {mkCountdownTimer} = require("ui/helpers/timers.nut")

local endTimerTime = ::Computed(@() actionTimer.value.endTimeToComplete ?? 0.0)

local function indicatorCtor(){
  local countDownTimer = mkCountdownTimer(endTimerTime)
  local curProgressW = ::Computed(@() actionTimer.value.totalTime > 0 ?
   (1 - (countDownTimer.value / actionTimer.value.totalTime)) * actionTimer.value.actionTimerMul + actionTimer.value.curProgress : 0)
  local showProgress = ::Computed(@() curProgressW.value > 0.0 && curProgressW.value < 0.99)

  local destroyProgressSize = [hdpx(80), hdpx(80)]

  local commands = [
    [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
    [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
  ]
  local sector = commands[1]
  local destroyingProgress = {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_STEXT
        font = Fonts.fontawesome
        color = Color(255, 255, 255)
        text = fa["legal"]
        fontSize = hdpx(40)
      }
      {
        behavior = Behaviors.RtPropUpdate
        size = destroyProgressSize
        lineWidth = hdpx(6.0)
        color = actionTimer.value.actionTimerColor
        fillColor = Color(122, 1, 0, 0)
        rendObj = ROBJ_VECTOR_CANVAS
        commands = commands
        update = function() {
          sector[6] = 360.0 * curProgressW.value
        }
      }
    ]
  }

  return {
    watch = [showProgress]
    children = showProgress.value ? destroyingProgress : null
  }
}

return indicatorCtor 