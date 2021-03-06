local spawn_zones = Watched({})

::ecs.register_es("spawn_zones_markers",
  {
    [["onInit"]] = function(eid,comp){
      local isCustom = ::ecs.get_comp_val(eid, "autoRespawnSelector", null) == null
      spawn_zones(@(v) v[eid] <- {iconType = comp.respawnIconType, selectedGroup = comp.selectedGroup, forTeam = comp.team, isCustom = isCustom})
    }

    function onDestroy(eid, comp){
      if (eid in spawn_zones.value)
        spawn_zones.update(@(v) delete v[eid])
    }
  },
  {
    comps_ro = [
      ["respawnIconType", ::ecs.TYPE_STRING],
      ["selectedGroup", ::ecs.TYPE_INT],
      ["team", ::ecs.TYPE_INT]
    ]
  }
)

return {spawn_zone_markers = spawn_zones} 