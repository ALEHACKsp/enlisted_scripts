local style = require("ui/hud/style.nut")
return @(valWatch, sliderComp, morphText = @(val) val) {
  size = flex()
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = sh(1)

  children = [
    sliderComp
    @() {
      watch = valWatch
      size = [::hdpx(60), SIZE_TO_CONTENT]
      rendObj = ROBJ_DTEXT
      font = Fonts.medium_text
      color = style.DEFAULT_TEXT_COLOR
      text = morphText(valWatch.value)
    }
  ]
}
 