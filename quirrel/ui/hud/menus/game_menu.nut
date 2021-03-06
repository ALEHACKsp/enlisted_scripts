local colors = require("ui/style/colors.nut")
local cursors = require("ui/style/cursors.nut")
local gamepadImgByKey = require("ui/components/gamepadImgByKey.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local JB = require("ui/control/gui_buttons.nut")
local {btnExitGame, btnResume, btnBindKeys, btnOptions} = require("game_menu_items.nut")
local menuCurrentItem = Watched(0)
local menuItems = Watched([btnResume, btnOptions, btnBindKeys, btnExitGame])

local showGameMenu = persist("showGameMenu", @() Watched(false))

local function closeMenu() {
  showGameMenu.update(false)
}

showGameMenu.subscribe(function(new_val) {
  if (new_val)
    menuCurrentItem(0)
})


local function callHandler(item) {
  closeMenu()
  item?.action()
}


local height = calc_comp_size({rendObj=ROBJ_DTEXT font = Fonts.medium_text text = "A"})[1]

local function makeMenuItem(idx, data) {
  local stateFlags = Watched(0)
  local isCur = (idx==menuCurrentItem.value)
  local imgA = gamepadImgByKey.mkImageCompByDargKey(JB.A, {
    height = height
    vplace = ALIGN_CENTER
    pos = [-sh(3.5), 0]
    transform = {
      scale = isCur ? [1,1] : [0,1]
      pivot = [0.7,0.5]
    }
    opacity = isCur ? 1: 0
    transitions = [
      { prop=AnimProp.translate, duration = 0.3, easing = InOutCubic }
      { prop=AnimProp.opacity, duration = 0.3, easing = InOutCubic }
      { prop=AnimProp.scale, duration = 0.4, easing = InOutCubic }
    ]
    animations = [
      { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.25, play=true, easing=InOutCubic}
    ]
  })

  return function() {
    local color = isCur ? colors.TextHighlight
                : (stateFlags.value & S_HOVER) ? colors.TextHover
                : colors.TextDefault

    return {
      key = data
      rendObj = ROBJ_DTEXT
      font = Fonts.huge_text
      text = data.text
      behavior = [Behaviors.Button, Behaviors.RecalcHandler]
      sound = {
        click  = "ui/button_click"
        hover  = "ui/menu_highlight"
        active = "ui/button_action"
      }

      function onRecalcLayout(initial) {
        if (initial && isCur)
          ::move_mouse_cursor(data, false)
      }

      watch = [stateFlags, isGamepad]
      color = color
      transitions = [
        { prop=AnimProp.translate, duration = 0.3, easing = InOutCubic }
      ]
      transform = {
        translate = [isCur ? -sh(0.5) : -0, 0]
      }

      fontFx = isCur ? FFT_GLOW : FFT_NONE
      fontFxColor = colors.TextDefault
      fontFxFactor = 48
      children = isGamepad.value ? imgA : null
      margin = [sh(2), sh(8)]
      onClick = @() callHandler(data)
      onElemState = @(sf) stateFlags.update(sf)
      onHover = function(on) {if (on) menuCurrentItem(idx)}

      cursorNavAnchor = [::elemh(80), ::elemh(90)]
    }
  }
}

local skip ={skip=true}
local function gameMenu() {
  local menuItemsVal = menuItems.value.filter(@(item) item!=null && (item?.isAvailable ?? @() true)())

  local function goToNext(d) {
    local nextIdx = (menuCurrentItem.value + d + menuItemsVal.len()) % menuItemsVal.len()
    menuCurrentItem.update(nextIdx)
    ::move_mouse_cursor(menuItemsVal[nextIdx])
  }

  local activateCurrent = @() callHandler(menuItemsVal?[menuCurrentItem.value])
  local children = menuItemsVal.map(@(data, idx) makeMenuItem(idx, data))

  local menu = {
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    pos = [sh(14), sh(30)]

    hotkeys = [
      ["@HUD.GameMenu", {action=closeMenu description=skip}],
      ["^{0} | J:Start".subst(JB.B), {action=closeMenu description=::loc("Back")}],
      ["^{0} | Enter | Space".subst(JB.A), {action=activateCurrent description=skip}],
      ["^Up | J:D.Up", {action =@() goToNext(-1) description = skip}],
      ["^Down | J:D.Down", {action =@() goToNext(1) description= skip}],
    ]

    children = children

    transform = {}
    animations = [
      { prop=AnimProp.translate, from=[-sh(10),0], to=[0, 0], duration=0.2, play=true, easing=OutCubic}
    ]
  }

  local root = {
    key = "gameMenu"
    size = [sw(100), sh(100)]
    cursor = cursors.normal

    children = [
      {
        size = [sw(120), sh(100)]
        stopHotkeys = true
        stopMouse = true
        rendObj = ROBJ_WORLD_BLUR_PANEL
        color = Color(130,130,130)
      }
      menu
    ]
    watch = [menuCurrentItem, menuItems]

    transform = {
      pivot = [0.5, 0.25]
    }
    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
      //{ prop=AnimProp.scale, from=[1,1], to=[3, 1.5], duration=0.2, playFadeOut=true, easing=InOutCubic}
      { prop=AnimProp.translate, from=[0,0], to=[-sh(10),0], duration=0.2, playFadeOut=true, easing=InOutCubic}
    ]
    sound = {
      attach="ui/menu_enter"
      detach="ui/menu_exit"
    }

    hooks = HOOK_ATTACH
    actionSet = "StopInput"
  }

  return root
}


return {
  gameMenu = gameMenu
  menuCurrentItem = menuCurrentItem
  menuItems = menuItems
  showGameMenu = showGameMenu
}
 