local respawn_markers = Watched({})
local is_engineer = Watched(false)

::ecs.register_es("ui_check_building_tool_gun_es",
  {
    [["onChange", "onInit"]] = function (evt, eid, comp) {
      local currentGunEid = comp["human_weap.currentGunEid"]
      local currentPreviewId = ::ecs.get_comp_val(currentGunEid, "currentPreviewId", null)
      if (currentPreviewId != null) {
        is_engineer(true)
        return
      }
      is_engineer(false)
    },
  },
  {
    comps_track = [["human_weap.currentGunEid", ::ecs.TYPE_EID]],
    comps_rq = ["hero"]
  }
)

local function deleteRespawnHudMarker(eid){
  if (eid in respawn_markers.value)
    respawn_markers.update(function(v) {
      delete v[eid]
    })
}

local function createRespawnMarker(eid, team, custom){
  respawn_markers.update(@(v) v[eid] <- {
    custom       = custom
    team         = team
  })
}

::ecs.register_es(
  "respawn_markers_es",
  {
    [["onInit"]] = function(ect, eid, comp){
        local isCustom = ::ecs.get_comp_val(eid, "autoRespawnSelector", null) == null
        createRespawnMarker(eid, comp.team, isCustom)
    }
    onDestroy = @(evt, eid, comp ) deleteRespawnHudMarker(eid)
  },
  {
    comps_rq = ["respawnIconType"]
    comps_ro = [["team", ::ecs.TYPE_INT]]
  }
)

::ecs.register_es(
  "respawn_previews_markers_es",
  {
    [["onInit"]] = function(ect, eid, comp){
        createRespawnMarker(eid, comp.previewTeam, true)
    }
    onDestroy = @(evt, eid, comp ) deleteRespawnHudMarker(eid)
  },
  {
    comps_rq = ["respawnObject", "builder_server_preview"]
    comps_ro = [["previewTeam", ::ecs.TYPE_INT]]
  }
)

return{
  respawn_markers = respawn_markers
  is_engineer = is_engineer
} 