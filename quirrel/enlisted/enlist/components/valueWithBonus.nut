local { defTxtColor, titleTxtColor, bonusColor } = require("enlisted/enlist/viewConst.nut")
local { note } = require("defcomps.nut")
local { premiumImage } = require("enlisted/enlist/currency/premiumComp.nut")

local trim = @(str) "".join((str ?? "").tostring().split())

local function strikeThrough(child) {
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [
      [VECTOR_WIDTH, ::hdpx(1)],
      [VECTOR_COLOR, defTxtColor],
      [VECTOR_LINE, 0, 90, 100, 20]
    ]
    padding = [0, ::hdpx(5)]
    margin = [0, ::hdpx(5), 0, 0]
    children = child
  }
}

local function mkValueWithBonus(commonValue, bonusValue, style = {}) {
  local commonWatch = commonValue instanceof ::Watched ? commonValue : ::Computed(@() commonValue)
  local bonusWatch = bonusValue instanceof ::Watched ? bonusValue : ::Computed(@() bonusValue)
  local watches = [commonWatch, bonusWatch]
  return @() bonusWatch.value != null
    ? {
        watch = watches
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = [
          strikeThrough(note(trim(commonWatch.value)).__update(style))
          premiumImage(::hdpx(20), { pos = [0, ::hdpx(2)] })
          note({ text = trim(bonusWatch.value), color = bonusColor })
            .__update(style)
        ]
      }
    : note({ watch = watches, text = trim(commonWatch.value), color = titleTxtColor })
        .__update(style)
}

return mkValueWithBonus 