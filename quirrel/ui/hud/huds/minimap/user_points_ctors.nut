local {mkPointMarkerCtor} = require("components/minimap_markers_components.nut")

local markSz = [sh(2), sh(2.6)].map(@(v) v.tointeger())
local enMarkSz = [sh(0.9), sh(1.4)].map(@(v) v.tointeger())

local main_user_mark = ::Picture("!ui/skin#map_pin.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))
local enemy_user_mark = ::Picture("!ui/skin#unit_inner.svg:{0}:{1}:K".subst(enMarkSz[0],enMarkSz[1]))
local user_points_ctors = {
  main_user_point = mkPointMarkerCtor({
    image = main_user_mark,
    colors = {myHover = Color(250,250,180,250), myDef = Color(250,250,50,250), foreignHover = Color(220,220,250,250), foreignDef = Color(180,180,250,250)}
  })

  enemy_user_point = mkPointMarkerCtor({
    image = enemy_user_mark,
    colors = {myHover = Color(250,200,200,250), myDef = Color(250,50,50,250), foreignHover = Color(220,180,180,250), foreignDef = Color(200,50,50,250)}
    size = enMarkSz
  })

  item_user_point = mkPointMarkerCtor({
    image = enemy_user_mark,
    colors = {myHover = Color(250,250,180,250), myDef = Color(250,250,50,250), foreignHover = Color(220,220,250,250), foreignDef = Color(180,180,250,250)}
    size = [sh(0.75), sh(0.75)]
  })
}

local mkUserPoints = @(ctors, state) Computed(function(){
  local up = state.value
  return {function ctor(p) {
    local res = []
    foreach(eid, info in up)
      res.append(ctors?[info.type](eid, info, p))
    return res
  }}
})

return {
  user_points_ctors = user_points_ctors
  mkUserPoints = mkUserPoints
} 