local {user_points} = require("ui/hud/state/user_points.nut")

local pinSz = [sh(1.2), sh(1.7)]
local images = {
  main_user_point = ::Picture("!ui/skin#map_pin.svg:{0}:{1}".subst(pinSz[0].tointeger(),pinSz[1].tointeger()))
  enemy_user_point = ::Picture("!ui/skin#unit_inner.svg:{0}:{1}".subst(pinSz[0].tointeger(),pinSz[1].tointeger()))
}

local function makeUserPoint(eid, data) {

  local {byLocalPlayer=false} = data
  local dataType = data.type
  local color = dataType == "enemy_user_point"
    ? Color(250,50,0,250)
    : byLocalPlayer
        ? Color(250,250,50,250)
        : Color(180,180,250,250)
  local pin = {
      size = pinSz
      rendObj = ROBJ_IMAGE
      color = color
      pos = [0, -pinSz[1] * 0.5]
      image = images?[dataType]
  }

  return {
    size = [hdpx(12), hdpx(12)]

    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    transform = {}

    data = {
      eid = eid
      clampToBorder = true
    }

    children = pin
  }
}

// map_size must be in pixels
local userPoints = Computed(function(){
  local components = []
  foreach (eid, data in user_points.value) {
    if (data?.type == "main_user_point" || data?.type == "enemy_user_point") {
      components.append(makeUserPoint(eid, data))
    }
  }

  return components
})

return userPoints
 