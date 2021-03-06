local { localPlayerEid, localPlayerTeam } = require("ui/hud/state/local_player.nut")
local { TEAM_UNASSIGNED } = require("team")

local user_points = Watched({})

::ecs.register_es("user_points_ui_es",
  {[["onInit", "onChange"]] = function(evt, eid, comp){
      user_points.update(function(v) {
        if (comp.team != TEAM_UNASSIGNED && comp.team != localPlayerTeam.value)
          return

        local target = comp["target"]
        local image = ::ecs.get_comp_val(target, "building_menu.image", "building_wall")
        local res = {type = comp["hud_marker.type"], image = image, visible_distance = comp["hud_marker.visible_distance"]}
        if (comp["userPointOwner"]!=INVALID_ENTITY_ID)
          res.byLocalPlayer <- comp["userPointOwner"]  == localPlayerEid.value
        v[eid] <- res
      })
    },
    function onDestroy(evt, eid, comp){
      if (eid in user_points.value)
        delete user_points[eid]
    }
  },
  {
    comps_ro = [
      ["userPointOwner", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["team", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["target", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["hud_marker.visible_distance", ::ecs.TYPE_FLOAT, null]
    ],
    comps_track = [["hud_marker.type", ::ecs.TYPE_STRING]]
  }
)

return {
  user_points = user_points
} 