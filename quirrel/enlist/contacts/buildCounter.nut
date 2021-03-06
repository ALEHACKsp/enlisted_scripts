local colors = require("ui/style/colors.nut")

local function buildCounter(params={watched=Watched() textfunc = @(watched) null}) {
  local watched = params?.watched ?? null
  local textfunc = params?.textfunc
  return function(){
    return {
      vplace = ALIGN_TOP
      pos = [0, -hdpx(10)]
      hplace = ALIGN_RIGHT
      rendObj = ROBJ_DTEXT
      watch =  watched
      color = colors.TextHighlight
      font = Fonts.small_text
      fontFx = FFT_GLOW
      fontFxColor = colors.BtnTextHover
      text = textfunc(watched)
    }.__merge(params)
  }
}
return buildCounter 