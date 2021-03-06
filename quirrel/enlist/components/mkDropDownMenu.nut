local fa = require("daRg/components/fontawesome.map.nut")
local fontIconButton = require("enlist/components/fontIconButton.nut")
local modalPopupWnd = require("enlist/components/modalPopupWnd.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local textButton = require("enlist/components/textButton.nut")
local {ModalBgTint} = require("ui/style/colors.nut")
local JB = require("ui/control/gui_buttons.nut")

local defSize = [hdpx(45)*0.75, hdpx(45)]
local function fabtn(icon, onClick=null, hotkeys=null, size = defSize, skipDirPadNav=true){
  local group = ::ElemGroup()
  local btn = type(icon)=="string"
          ? fontIconButton(fa[icon], {
              size = size
              onClick = onClick
              hotkeys = hotkeys
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              skipDirPadNav = skipDirPadNav
              group
            })
          : icon
  return {
    size = SIZE_TO_CONTENT
    behavior = Behaviors.Button
    group = group
    onClick = onClick
    skipDirPadNav
    children = btn
    padding = [0, sh(1)]
  }
}

local popupBg = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = ModalBgTint
}

const WND_UID = "main_menu_header_buttons"
local close = @() modalPopupWnd.remove(WND_UID)

local function closeWithCb(cb) {
  cb()
  modalPopupWnd.remove("main_menu_header_buttons")
}

local mkButton = @(btn, needMoveCursor) btn != null
  ? textButton.Flat(btn.name, @() closeWithCb(btn.cb), {
      size = [flex(), SIZE_TO_CONTENT]
      minWidth = SIZE_TO_CONTENT
      margin = 0
    }.__update(needMoveCursor ? {
        behavior = [Behaviors.Button, Behaviors.RecalcHandler]
        key = "selected_menu_elem"
        function onRecalcLayout(initial) {
          if (initial)
            ::move_mouse_cursor("selected_menu_elem", false)
        }
      } : {}))
  : {
      rendObj = ROBJ_SOLID
      size = [flex(), hdpx(1)]
      color = Color(50,50,50)
    }


local mkMenuButtons = @(buttons) @(){
  watch = [buttons, isGamepad]
  rendObj = ROBJ_BOX
  fillColor = Color(0,0,0)
  borderRadius = ::hdpx(4)
  borderWidth = 0
  flow = FLOW_VERTICAL
  children = buttons.value.map(@(btn, idx) mkButton(btn, isGamepad.value && idx == 0))
}

local mkDropMenuBtn = ::kwarg(function (buttons, size = defSize, makeMenuBtn = null, hotkeyOpen = "^J:Start | Esc", skipDirPadNav = true) {
  local menuButtonsUi = mkMenuButtons(buttons)
  makeMenuBtn = makeMenuBtn ?? @(openMenu) fabtn("list-ul", openMenu, [[hotkeyOpen, {description = {skip = true}} ]], size, skipDirPadNav)
  local function openMenu(event) {
    local {targetRect} = event
    modalPopupWnd.add([targetRect.r, targetRect.b], {
      uid = WND_UID
      padding = 0
      children = menuButtonsUi
      popupOffset = hdpx(5)
      popupHalign = ALIGN_RIGHT
      popupBg = popupBg
      hotkeys = [["^J:Start | {0} | Esc".subst(JB.B), { action = close, description = ::loc("Cancel") }]]
    })
  }
  return makeMenuBtn(openMenu)
})

return {
  mkDropMenuBtn
} 