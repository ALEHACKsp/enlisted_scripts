local dagorMath = require("dagor.math")
local sqmath = require("std/math.nut")
//local cq = require("globals/common_queries.nut")

local function onStartHighlight(evt, eid, comp) {
  if (comp["outline.enabled"])
    return
  comp["outline.enabled"] = true
  local setColor = sqmath.color2uint(255, 45, 45, 255) //get from UI components
  comp["outline.color"] = dagorMath.E3DCOLOR(setColor)
  local onTimer
  local timeout = 200.0
/*
  local avatarPos = ::ecs.get_comp_val(cq.get_controlled_hero(), "transform")?.getcol?(3)
  if (avatarPos != null) {
    local lenSq = (comp.transform.getcol(3) - avatarPos).lengthSq()
    local rangeDistSq = [15*15,300*300]
    timeout = sqmath.lerp(rangeDistSq[0], rangeDistSq[1], 90, 200, ::clamp(lenSq, rangeDistSq[0],rangeDistSq[1]))
  }
*/
  onTimer = function(){
    if (::ecs.g_entity_mgr.doesEntityExist(eid)) {
      local newColor = ::ecs.get_comp_val(eid, "outline.color")
      if (newColor?.u == dagorMath.E3DCOLOR(setColor).u)//just to be sure that it is the color we set, not some else
        ::ecs.set_comp_val(eid, "outline.enabled", false)
    }
    ::ecs.clear_callback_timer(onTimer)
  }
  ::ecs.set_callback_timer(onTimer, timeout, false)
}

local comps = {
  comps_rw = [
    ["outline.enabled", ::ecs.TYPE_BOOL],
    ["outline.color", ::ecs.TYPE_COLOR]
  //  only loot somehow
  ]
  comps_ro = [["transform", ::ecs.TYPE_MATRIX]]
}
::ecs.register_es("team_item_highlighter_es", {
  [::ecs.sqEvents.EventTeamItemHint] = onStartHighlight
}, comps, {tags  = "render"})
 