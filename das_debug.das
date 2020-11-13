require ecs
require DagorConsole
require vehicle

[console_cmd(name="das.throw_exception")]
def das_throw_exception()
  query() <| $[es] (var vehicle_seats_limited_visibility : ecs::IntList)
    debug("throw exception now")
    vehicle_seats_limited_visibility[1000] = 1

[console_cmd(name="das.throw_exception_no_aot"), no_aot]
def das_throw_exception_no_aot()
  query() <| $[es] (var vehicle_seats_limited_visibility : ecs::IntList)
    debug("throw exception now")
    vehicle_seats_limited_visibility[1000] = 1

[console_cmd(name="das.throw_endless_exception")]
def das_start_endless_exception()
  let tmpl = "endless_exception_template"
  ecs::createTemplate(tmpl, "", "", "", false) <| $(var cmp : ecs::ComponentsMap)
    set(cmp, "endless_exception", true)
  query() <| $[es(REQUIRE=vehicle_seats_limited_visibility)] (eid : EntityId)
    addSubTemplate(eid, tmpl)

[es(no_order)]
def endless_exception_update(evt : UpdateStageInfoAct; var vehicle_seats_limited_visibility : ecs::IntList; endless_exception : bool)
  if (endless_exception)
    debug("throw exception now")
    vehicle_seats_limited_visibility[1000] = 1
