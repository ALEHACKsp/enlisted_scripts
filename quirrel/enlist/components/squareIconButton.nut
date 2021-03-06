local fa = require("daRg/components/fontawesome.map.nut")
local colors = require("ui/style/colors.nut")
local cursors = require("ui/style/cursors.nut")
local {buttonSound} = require("ui/style/sounds.nut")
local tooltipTextArea = require("ui/style/tooltipTextArea.nut")

local buttonIcon = @(iconId = "user-plus", iconOverride = {}) {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = [hdpx(1), 0, 0, hdpx(2)]
  rendObj = ROBJ_STEXT
  validateStaticText = false
  text = fa[iconId]
  color = colors.Inactive
  font = Fonts.fontawesome
  fontSize = hdpx(21)
}.__update(iconOverride)

local DEFAULT_BUTTON_PARAMS = {
  onClick = null
  selected = null
  iconId = "user-plus"
  key = null
  animations = null
  tooltipText = null
  needBlink = false
  blinkAnimationId = ""
}

local headupTooltip = @(tooltip) tooltipTextArea({text = ::loc(tooltip)}, {pos = [0, hdpx(-50)]})

local btnHgt = calc_comp_size({size=SIZE_TO_CONTENT children={font=Fonts.big_text margin = [sh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_DTEXT}})[1]

return function(params = DEFAULT_BUTTON_PARAMS, iconOverride = {}) {
  params = DEFAULT_BUTTON_PARAMS.__merge(params)
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = [btnHgt, btnHgt]

    behavior = Behaviors.Button
    onClick = params.onClick
    onHover = params.tooltipText
                ? @(on) cursors.tooltip.state(on ? headupTooltip(params.tooltipText) : null)
                : null
    color = (sf & S_HOVER) ? colors.statusIconBg : Color(240, 240, 240, 255)
    sound = buttonSound
    children = @() {
      size = flex()
      watched = params.selected
      key = params.key
      animations = params.animations
      transform = { pivot=[0.5, 0.5] }
      children = [
        buttonIcon(params.iconId, params.selected?.value
          ? { color = colors.Active, fontFx = FFT_GLOW }.__update(iconOverride)
          : { color = (sf & S_HOVER) ? colors.Active : colors.Inactive }.__update(iconOverride)
        )
        params.needBlink
          ? {
              size = flex()
              rendObj = ROBJ_SOLID
              transform = {}
              opacity = 0
              animations = [
                { trigger = params.blinkAnimationId
                  prop = AnimProp.opacity, from = 0, to = 0.35, duration = 1.2,
                  play = true, loop = true, easing = Blink
                }
              ]
            }
          : null
      ]
    }
  })
} 