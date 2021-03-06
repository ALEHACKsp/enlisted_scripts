local slider = require("slider.nut")

local function optionSlider(opt, group, xmbNode) {
  local sliderElem = {
    size = flex()

    children = slider.Horiz(opt.var, {
      ignoreWheel = true
      min = opt?.min ?? 0
      max = opt?.max ?? 1
      unit = opt?.unit ?? 0.1
      scaling = opt?.scaling
      pageScroll = opt?.pageScroll ?? 0.1
      group = group
      xmbNode = xmbNode
      setValue = opt?.setValue
    })
  }

  return sliderElem
}

local export = class {
  _call = @(self, opt, group, xmbNode) optionSlider(opt, group, xmbNode)
  scales = slider.scales
}()

return export
 