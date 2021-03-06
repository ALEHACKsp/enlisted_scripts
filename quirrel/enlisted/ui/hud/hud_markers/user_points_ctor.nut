local { mkPointMarkerCtor } = require("ui/hud/huds/hud_markers/components/hud_markers_components.nut")

//!!!COLOR BELOW ARE CHECKED TO BE REASONABLE FOR COLORBLIND PPL
local myMainUserMarkColor = Color(250,250,50,250)
local forMainUserMarkColor = Color(180,180,250,250)
local forEnemyMarkColor = Color(255,115,83,250)
local myEnemyMarkColor = Color(200,50,50,250)
//!!!COLOR ABOVE ARE CHECKED TO BE REASONABLE FOR COLORBLIND PPL

local markSz = [sh(2), sh(2.6)].map(@(v) v.tointeger())
local tankSz = [sh(1.4), sh(1.4)].map(@(v) v.tointeger())

local main_user_mark = ::Picture("!ui/skin#map_pin.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))
local enemy_user_mark = ::Picture("!ui/skin#unit_inner.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))


local enemy_vehicle_user_mark = ::Picture("!ui/skin#tank_icon.svg:{0}:{1}:K".subst(tankSz[0], tankSz[1]))

local ctorByType = {
  main_user_point = mkPointMarkerCtor({
    image = main_user_mark
    colors = {myDef =  myMainUserMarkColor, foreignDef = forMainUserMarkColor}
  })

  enemy_user_point = mkPointMarkerCtor({
    image = enemy_user_mark
    colors = {myDef = myEnemyMarkColor , foreignDef = forEnemyMarkColor}
    yOffs = -1
    animations = [{ prop=AnimProp.color, from=myEnemyMarkColor, to=Color(255,200,200), duration=0.7, play=true, loop=true, easing=Blink }]
  })

  enemy_vehicle_user_point =  mkPointMarkerCtor({
    image = enemy_vehicle_user_mark
    colors = {myDef = myEnemyMarkColor , foreignDef = forEnemyMarkColor}
    yOffs = -1
  })
}

return {
  function user_point_ctor(eid, info) {
    return ctorByType?[info.type](eid, info)
  }
}
 