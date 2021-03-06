local baseScrollbar = require("daRg/components/scrollbar.nut")
local {Interactive, Active, HoverItemBg} = require("ui/style/colors.nut")

local styling = {
  Knob = class {
    rendObj = ROBJ_SOLID
    colorCalc = @(sf) (sf & S_ACTIVE) ? Active
                    : ((sf & S_HOVER) ? HoverItemBg
                                      : Interactive)
    sound = { active = "ui/enlist/combobox_action" }
  }

  Bar = function(has_scroll) {
    if (has_scroll) {
      return class {
        rendObj = ROBJ_SOLID
        color = Color(40, 40, 40, 160)
        _width = sh(1)
        _height = sh(1)
        sound = { hover  = "ui/enlist/combobox_highlight" }
        skipDirPadNav = true
      }
    } else {
      return class {
        rendObj = null
        _width = sh(1)
        _height = sh(1)
        skipDirPadNav = true
      }
    }
  }

  ContentRoot = class {
    size = flex()
    skipDirPadNav = true
  }
}

local thinStyle = {
  Knob = class {
    rendObj = ROBJ_SOLID
    colorCalc = @(sf) Color(0, 0, 0, 0)
    hoverChild = @(sf){
      size = [hdpx(2), flex()]
      rendObj = ROBJ_SOLID
      hplace = ALIGN_RIGHT
      color = (sf & S_ACTIVE)  ? Color(255, 255, 255)
              : (sf & S_HOVER) ? Color(110, 120, 140, 80)
              : Color(110, 120, 140, 160)
    }
  }
  Bar = function(has_scroll) {
    if (!has_scroll)
      return class {
        _width = 0
        _height = 0
        skipDirPadNav = true
      }
    return class {
      rendObj = ROBJ_SOLID
      color = Color(0, 0, 0, 60)
      _width = hdpx(4)
      _height = sh(1)
      skipDirPadNav = true
    }
  }

  ContentRoot = class {
    size = flex()
    skipDirPadNav = true
  }
}


local function scrollbar(scroll_handler) {
  return baseScrollbar.scroll(scroll_handler, {styling=styling})
}


local function makeHorizScroll(content, options={}) {
  if (!("styling" in options))
    options.styling <- styling
  return baseScrollbar.makeHorizScroll(content, options)
}

local function makeVertScroll(content, options={}) {
  if (!("styling" in options))
    options.styling <- styling
  return baseScrollbar.makeVertScroll(content, options)
}


local export = class {
  scrollbar = scrollbar
  makeHorizScroll = makeHorizScroll
  makeVertScroll = makeVertScroll
  styling = styling
  thinStyle = thinStyle
}()

return export
 