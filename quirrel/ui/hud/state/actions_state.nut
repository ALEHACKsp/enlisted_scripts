local useActionEid = Watched(INVALID_ENTITY_ID)
local useActionAvailable = Watched(false)
local lookAtEid = Watched(INVALID_ENTITY_ID)
local pickupItemEid = Watched(INVALID_ENTITY_ID)
local pickupItemName = Watched(null)

::ecs.register_es("hero_state_hud_state_ui_es", {
  [["onInit", "onChange"]] = function(eid,comp) {
    useActionEid(comp.useActionEid)
    useActionAvailable(comp.useActionAvailable)
    lookAtEid(comp.lookAtEid)
    pickupItemEid(comp.pickupItemEid)
    pickupItemName(comp.pickupItemName)
  }
  function onDestroy(eid,comp) {
    useActionEid(INVALID_ENTITY_ID)
    useActionAvailable(false)
    lookAtEid(INVALID_ENTITY_ID)
    pickupItemEid(INVALID_ENTITY_ID)
    pickupItemName(null)
  }
}, {
  comps_rq = ["watchedByPlr"]
  comps_track = [
    ["useActionEid", ::ecs.TYPE_EID],
    ["useActionAvailable", ::ecs.TYPE_INT],
    ["lookAtEid", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["pickupItemEid", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["pickupItemName", ::ecs.TYPE_STRING, null],
  ]
})

return {useActionAvailable, useActionEid, lookAtEid, pickupItemEid, pickupItemName}
 