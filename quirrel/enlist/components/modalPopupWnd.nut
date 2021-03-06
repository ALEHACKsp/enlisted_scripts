local JB = require("ui/control/gui_buttons.nut")
local modalWindows = require("daRg/components/modalWindows.nut")
local colors = require("ui/style/colors.nut")
local viewConst = require("enlist/viewConst.nut")
local {safeAreaBorders} = require("enlist/options/safeAreaState.nut")

local POPUP_PARAMS = {
  uid = null //when not set, will be generated
  popupFlow = FLOW_VERTICAL //how popup need to flow against target point
  popupOffset = 0 //popup offset from coords in popup flow direction
  popupHalign = ALIGN_CENTER
  popupValign = ALIGN_CENTER
  children = null
  hotkeys = null
  watch = null //!!FIX ME: this watch to update popup need only because of position reclac bug after child update.
               //remove it after bug will be fixed.

  rendObj = ROBJ_BOX
  borderWidth = 0
  borderRadius = hdpx(4)
  fillColor = colors.BtnBgNormal
  padding = viewConst.gap
  popupBg = {}
  moveDuraton = 0.3
}

local remove = @(uid) modalWindows.remove(uid)

local function calcOffsets(rectOrPos, popupFlow, popupOffset, popupHalign, popupValign) {
  local isArray = typeof rectOrPos == "array"
  ::assert(isArray || (("l" in rectOrPos) && ("b" in rectOrPos)))
  local res = {
    pos = isArray ? rectOrPos : [rectOrPos.l, rectOrPos.t]
    halign = popupHalign
    valign = popupValign
  }

  local size = isArray ? [0, 0] : [rectOrPos.r - rectOrPos.l, rectOrPos.b - rectOrPos.t]

  if (popupFlow == FLOW_VERTICAL) {
    if (res.valign == ALIGN_CENTER)
      res.valign = (res.pos[1] > sh(100) - res.pos[1] - size[1]) ? ALIGN_BOTTOM : ALIGN_TOP
    res.pos[1] += res.valign == ALIGN_BOTTOM ? -popupOffset : popupOffset + size[1]

    res.pos[0] += res.halign == ALIGN_CENTER ? size[0] / 2
      : res.halign == ALIGN_RIGHT ? size[0]
      : 0
  }
  else {
    if (res.halign == ALIGN_CENTER)
      res.halign = (res.pos[0] > sw(100) - res.pos[0] - size[0]) ? ALIGN_RIGHT : ALIGN_LEFT
    res.pos[0] += res.halign == ALIGN_RIGHT ? -popupOffset : popupOffset + size[0]

    res.pos[1] += res.valign == ALIGN_CENTER ? size[1] / 2
      : res.valign == ALIGN_BOTTOM ? size[1]
      : 0
  }

  return res
}

local translateAnimation = @(flow, halign, valign, duration)
  { prop = AnimProp.translate, duration = duration, play = true, easing = OutCubic
    from = (flow == FLOW_VERTICAL && valign == ALIGN_BOTTOM) ? [0, 50]
      : (flow == FLOW_VERTICAL && valign == ALIGN_TOP) ? [0, -50]
      : (flow == FLOW_HORIZONTAL && halign == ALIGN_RIGHT) ? [50, 0]
      : (flow == FLOW_HORIZONTAL && halign == ALIGN_LEFT) ? [-50, 0]
      : [0, 0]
    to = [0,0],
  }


local lastPopupIdx = 0
local function add(rectOrPos, popup) {
  popup = POPUP_PARAMS.__merge(popup)
  popup.uid = popup?.uid ?? $"modal_popup_{lastPopupIdx++}"
  popup.hotkeys = popup.hotkeys ?? [["^{0} | Esc".subst(JB.B), { action = @() remove(popup.uid), description = ::loc("Cancel") }]]

  local offsets = calcOffsets(rectOrPos, popup.popupFlow, popup.popupOffset, popup.popupHalign, popup.popupValign)
  modalWindows.add(popup.popupBg.__merge({
    key = popup.uid
    children = {
      key = $"__place_{popup.uid}"
      size = [0, 0]
      pos = offsets.pos
      halign = offsets.halign
      valign = offsets.valign

      children = {
        size = SIZE_TO_CONTENT
        transform = {}
        safeAreaMargin = safeAreaBorders.value
        behavior = Behaviors.BoundToArea

        children = {
          size = SIZE_TO_CONTENT
          key = $"__anim_{popup.uid}"
          children = @() popup

          transform = {}
          animations = [
            translateAnimation(popup.popupFlow, offsets.halign, offsets.valign, popup.moveDuraton)
          ]
        }
      }
    }
  }))
  return popup.uid
}

return {
  add = add
  remove = remove

  POPUP_PARAMS = POPUP_PARAMS
} 