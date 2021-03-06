local colors = require("ui/style/colors.nut")
local gamepadImgByKey = require("ui/components/gamepadImgByKey.nut")
local active_controls = require("ui/control/active_controls.nut")
local modalPopupWnd = require("enlist/components/modalPopupWnd.nut")
local JB = require("ui/control/gui_buttons.nut")


local function listItem(text, action) {
  local group = ::ElemGroup()
  local stateFlags = ::Watched(0)
  local height = ::calc_comp_size({rendObj = ROBJ_DTEXT text="A"})[1]
  local activeBtn = gamepadImgByKey.mkImageCompByDargKey(JB.A,
    { height = height, hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER})
  return function() {
    local sf = stateFlags.value
    local hover = sf & S_HOVER
    return {
      behavior = [Behaviors.Button]
      clipChildren=true
      rendObj = ROBJ_SOLID
      color = hover ? colors.BtnBgHover : colors.BtnBgNormal
      size = [flex(), SIZE_TO_CONTENT]
      group = group
      watch = [stateFlags, active_controls.isGamepad]
      padding = sh(0.5)
      onClick = action
      onElemState = @(nsf) stateFlags.update(nsf)

      sound = {
        click  = "ui/button_click"
        hover  = "ui/menu_highlight"
        active = "ui/button_action"
      }

      children = [
        {
          rendObj = ROBJ_DTEXT
          behavior = [Behaviors.Marquee]
          scrollOnHover=true
          size=[flex(),SIZE_TO_CONTENT]
          speed = hdpx(100)
          text = text
          group = group
          color = (stateFlags.value & S_HOVER) ? colors.BtnTextHover : colors.BtnTextNormal
        }
        active_controls.isGamepad.value && hover ? activeBtn : null
      ]
    }
  }
}

local menu = @(width, actions, uid) {
  size = [width, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = actions.map(@(item) listItem(item.text,
    function () {
      item.action()
      modalPopupWnd.remove(uid)
    }))
}

local uidCounter = 0
return function(x, y, width, actions) {
  uidCounter++
  local uid = $"contextMenu{uidCounter}"
  return modalPopupWnd.add([x, y], {
    uid = uid
    popupHalign = ALIGN_LEFT
    popupValign = y > sh(75) ? ALIGN_BOTTOM : ALIGN_TOP
    popupFlow = FLOW_VERTICAL
    moveDuraton = min(0.12 + 0.03 * actions.len(), 0.3) //0.3 sec opening is too slow for small menus

    children = menu(width, actions, uid)
  })
}
 