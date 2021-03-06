local contextCommandState = make_persists(persist, {
  orderType = Watched(0)
  orderUseEntity = Watched(INVALID_ENTITY_ID)
})

local function updateContextCommand(evt, eid, comp) {
  contextCommandState.orderType(comp["human_context_command.orderType"])
  contextCommandState.orderUseEntity(comp["human_context_command.orderUseEntity"])
}

::ecs.register_es("human_context_command_state_es",
  {
    [["onInit", "onChange"]] = updateContextCommand
  },
  {
    comps_rq = ["human_context_command_input"]
    comps_track = [
      ["human_context_command.orderType", ::ecs.TYPE_INT],
      ["human_context_command.orderUseEntity", ::ecs.TYPE_EID],
    ]
  },
  { tags="gameClient" }
)

return contextCommandState
 