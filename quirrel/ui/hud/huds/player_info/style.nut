local barWidth = sw(7)
local barHeight = sh(0.5)

local blurBack = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = flex()
  color=Color(250,250,250,250)
}

return {
  DEFAULT_TEXT_COLOR = Color(180, 180, 180, 120)
  HUD_ITEMS_COLOR = Color(180,180,180,50)
  blurBack = blurBack
  barWidth = barWidth
  barHeight = barHeight
  notSelectedItemColor = Color(180,180,180,150)
  iconSize = [sh(1.7), sh(1.7)]
  itemAppearing = [
    {prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic}
  ]
} 