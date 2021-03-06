local missionName = Watched()
local missionType = Watched()

::ecs.register_es("mission_params_ui_es",{
    function onInit(eid, comp){
      missionName(comp.mission_name != "" ? comp.mission_name : null)
      missionType(comp.mission_type != "" ? comp.mission_type : null)
    }
    function onDestroy(eid, comp){
      missionName(null)
      missionType(null)
    }
  },
  {comps_ro = [["mission_name", ::ecs.TYPE_STRING], ["mission_type", ::ecs.TYPE_STRING, ""]]}
)

return {missionName, missionType} 