local fa = require("daRg/components/fontawesome.map.nut")
local {mkCountdownTimer} = require("ui/helpers/timers.nut")

local function indicatorCtor(endTime, totalTime){
  local countDownTimer = mkCountdownTimer(endTime)
  local curProgressW = ::Computed(@() totalTime.value > 0 ? countDownTimer.value / totalTime.value : 0)
  local showProgress = ::Computed(@() curProgressW.value > 0.0 && curProgressW.value < 0.99)

  local changeSeatProgressSize = [hdpx(80), hdpx(80)]

  local commands = [
    [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
    [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
  ]
  local sector = commands[1]
  curProgressW.subscribe(@(v) sector[6] = 360.0 * v)

  local changeSeatProgress = {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_STEXT
        font = Fonts.fontawesome
        color = Color(255, 255, 255)
        text = fa["exchange"]
        fontSize = hdpx(30)
      }
      @() {
        watch = curProgressW
        size = changeSeatProgressSize
        lineWidth = hdpx(6.0)
        color = Color(255, 255, 255)
        fillColor = Color(122, 1, 0, 0)
        rendObj = ROBJ_VECTOR_CANVAS
        commands = commands
      }
    ]
  }

  return function() {
    return {
      watch = [showProgress]
      children = showProgress.value ? changeSeatProgress : null
    }
  }
}

return indicatorCtor 