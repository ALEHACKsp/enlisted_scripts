local progressBar = @(color, scale, halign, hitTrigger = null) {
  rendObj = ROBJ_SOLID
  size = flex()
  color = color
  transform = {
    scale = [scale, 1.0]
    pivot = [halign == ALIGN_RIGHT ? 1 : 0, 0]
  }
  transitions = [
    { prop=AnimProp.scale, duration=0.25, easing=OutCubic }
  ]
  animations = hitTrigger
    ? [
        { prop = AnimProp.color, from = Color(255,10,10,50), easing = OutCubic,
          duration = 0.5, trigger = hitTrigger
        }
      ]
    : null
}

local function healthBar(hp, maxHp, scaleHp = 0, halign = ALIGN_RIGHT, hitTrigger = null, maxHpTrigger = null,
  colorBg = null, colorFg = null
) {
  if (hp == null || maxHp <= 0)
    return null
  if (hp <= 0)
    hp = maxHp + hp

  local isVisible = hp < maxHp
  local baseScale = scaleHp <= 0 ? 1.0 : maxHp.tofloat() / scaleHp
  local ratio = ::clamp(hp.tofloat() / maxHp, 0.0, 1.0)
  colorBg = colorBg ?? Color(30+50*(1.0-ratio), 50*ratio, 30*ratio, 80)
  colorFg = colorFg ?? (ratio >= 1 ? Color(105, 255, 105, 50) : Color(255, 105, 105, 50))
  return {
    size = flex()
    halign = halign
    opacity = isVisible ? 1.0 : 0.0
    children = [
      progressBar(colorBg, baseScale, halign, hitTrigger)
      progressBar(colorFg, baseScale * ratio, halign)
    ]

    transitions = [
      { prop=AnimProp.opacity, duration=0.2, easing=InOutCubic }
    ]
    animations = maxHpTrigger
      ? [
          { prop = AnimProp.opacity, from = 0.5, to = 1.0, easing = DoubleBlink,
            duration = 1.0, trigger = maxHpTrigger
          }
        ]
      : null
  }
}

return ::kwarg(healthBar)
 