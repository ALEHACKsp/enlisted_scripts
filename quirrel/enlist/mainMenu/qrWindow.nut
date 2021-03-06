local colors = require("ui/style/colors.nut")
local { bigGap } = require("enlist/viewConst.nut")
local mkQrCode = require("daRg/components/mkQrCode.nut")
local openUrl = require("enlist/openUrl.nut")
local modalWindows = require("daRg/components/modalWindows.nut")
local spinner = require("enlist/components/spinner.nut")({height=::hdpx(80)})


const WND_UID = "qr_window"
const URL_REFRESH_SEC = 300 //short token life time is 5 min.

local close = @() modalWindows.remove(WND_UID)

local waitInfo = {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    { rendObj = ROBJ_DTEXT, text = ::loc("xbox/waitingMessage"), font = Fonts.small_text, color = colors.TextDefault }
    spinner
  ]
}

local function qrWindow(url, header) {
  local realUrl = ::Watched(null)
  local function receiveRealUrl() {
    openUrl(url, false, false, @(u) realUrl(u))
    ::gui_scene.setTimeout(URL_REFRESH_SEC, receiveRealUrl)
  }

  return @() {
    watch = realUrl
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = colors.WindowBlur
    padding = 2 * bigGap
    gap = bigGap

    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER

    onAttach = receiveRealUrl
    onDetach = @() ::gui_scene.clearTimer(receiveRealUrl)

    children = [
      { rendObj = ROBJ_DTEXT, text = header, font = Fonts.big_text }
      { rendObj = ROBJ_DTEXT, text = url, font = Fonts.small_text }
      realUrl.value ? mkQrCode({ data = realUrl.value }) : waitInfo
    ]
  }
}

return @(url, header = "") modalWindows.add({
  key = WND_UID
  size = [sw(100), sh(100)]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = colors.ModalBgTint
  onClick = close
  children = qrWindow(url, header)
  hotkeys = [["^J:B | Esc", { action = close, description = ::loc("Cancel") }]]
}) 