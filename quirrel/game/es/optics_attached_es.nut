local weapon_slots = require("globals/weapon_slots.nut")

local slotToCompId = {
  [weapon_slots.EWS_PRIMARY] = "human_weap.primaryOpticsAttached",
  [weapon_slots.EWS_SECONDARY] = "human_weap.secondaryOpticsAttached",
}

local function updateOptics(evt, eid, comp) {
  foreach(slot, compId in slotToCompId) {
    local weapEid = comp["human_weap.gunMods"]?[slot] ?? INVALID_ENTITY_ID
    comp[compId] = weapEid == INVALID_ENTITY_ID ? false
      : ::ecs.get_comp_val(weapEid, "gunmod.zoomFactor", 0) > 0
  }
}

::ecs.register_es("optics_created_es",
  {
    onInit = @(evt, eid, comp) ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.CmdUpdateOptics())
  },
  { comps_rq = ["gunmod.zoomFactor"] })

::ecs.register_es("optics_attached_es",
  {
    [::ecs.EventComponentChanged] = updateOptics,
    [::ecs.EventEntityCreated] = updateOptics,
    [::ecs.sqEvents.CmdUpdateOptics] = updateOptics,
  },
  {
    comps_rw = [
      ["human_weap.primaryOpticsAttached", ::ecs.TYPE_BOOL],
      ["human_weap.secondaryOpticsAttached", ::ecs.TYPE_BOOL]
    ]
    comps_track = [["human_weap.gunMods", ::ecs.TYPE_EID_LIST]]
  }
) 