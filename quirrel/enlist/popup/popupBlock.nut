local { popups } = require("popupsState.nut")
local textButton = require("enlist/components/textButton.nut")
local { BtnBgNormal } = require("ui/style/colors.nut")
local { sound_play } = require("sound")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { bigGap } = require("enlist/viewConst.nut")

local HighlightNeutral = Color(230, 230, 100)
local HighlightFailure = Color(255,60,70)

local POPUP_STYLE = {
  animColor = HighlightNeutral
  sound = "ui/enlist/notification"
}

local styles = {
  error = {
    animColor = HighlightFailure
    sound = "ui/enlist/notification"
  }
}
local popupWidth = ::calc_comp_size({rendObj = ROBJ_DTEXT text = "" font=Fonts.medium_text size=[fontH(1000), SIZE_TO_CONTENT]})[0]
local defPopupBlockPos = [-safeAreaBorders.value[1] - popupWidth, -(safeAreaBorders.value[2] + 4*bigGap)]
local popupBlockStyle = Watched({
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    pos = defPopupBlockPos
})

local function popupBlock() {
  local children = []
  foreach(idx, p in popups.value) {
    local popup = p
    local prevVisIdx = popup.visibleIdx.value
    local curVisIdx = popups.value.len() - idx
    if (prevVisIdx != curVisIdx) {
      local prefix = curVisIdx > prevVisIdx ? "popupMoveTop" : "popupMoveBottom"
      anim_start(prefix + popup.id)
    }

    local style = styles?[popup.styleName] ?? POPUP_STYLE
     if (prevVisIdx == -1)
       sound_play(style.sound)

    children.append({
      size = SIZE_TO_CONTENT

      children = textButton(popup.text, @() popup.click(), {
        margin = 0
        textParams = {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [popupWidth, SIZE_TO_CONTENT]
          font = Fonts.medium_text
        }
        key = $"popup_block_{popup.uid}"
        animations = [
          { prop=AnimProp.fillColor, from=style.animColor, to=BtnBgNormal, easing=OutCubic, duration=0.5, play=true }
        ]
      })

      key = $"popup_{popup.uid}"
      transform = {}
      animations = [
        { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.5, play=true, easing=OutCubic }
        { prop=AnimProp.translate, from=[0,100], to=[0, 0], duration=0.3, trigger = $"popupMoveTop{popup.id}", play = true, easing=OutCubic }
        { prop=AnimProp.translate, from=[0,-100], to=[0, 0], duration=0.3, trigger = $"popupMoveBottom{popup.id}", easing=OutCubic }
      ]

      behavior = Behaviors.RecalcHandler
      onRecalcLayout = @(initial) popup.visibleIdx(curVisIdx)
    })
  }
  local {hplace, vplace, pos = defPopupBlockPos} = popupBlockStyle.value
  return {
    watch = [popups, safeAreaBorders, popupBlockStyle]
    pos = pos
    size = SIZE_TO_CONTENT
    hplace = hplace
    vplace = vplace
    flow = FLOW_VERTICAL
    children = children
  }
}

return {popupBlock, popupBlockStyle, defPopupBlockPos}
 