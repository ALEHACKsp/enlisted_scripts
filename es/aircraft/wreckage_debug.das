require ecs
require dm
require DagorConsole
require game.es.events

[console_cmd (name="plane_wreckage.create_all")]
def plane_wreckage_create_all()
  ecs::query() <| $[es (REQUIRE=plane_wreckage)](eid: EntityId)
    destroyEntity(eid)

  ecs::query() <| $[es (REQUIRE=airplane, REQUIRE_NOT=plane_wreckage)](eid: EntityId;
                                                                       damage_model: DamageModel;
                                                                       var plane_wreckage_dot_createdByTemplates: ecs::BoolList;
                                                                       var plane_cutting_dot_cutting: bool&;
                                                                       var plane_cutting_dot_largePartsCut: ecs::BoolList)
    for wreckageCreated in plane_wreckage_dot_createdByTemplates
      wreckageCreated = false

    plane_cutting_dot_cutting = false

    for largePartCut in plane_cutting_dot_largePartsCut
      largePartCut = false

    let tailPartNo = find_part_id_by_name(damage_model, "tail_dm")
    sendEventImmediate(eid, [[EventCutPart offender=INVALID_ENTITY_ID, partNo=tailPartNo]])

    let wingLPartNo = find_part_id_by_name(damage_model, "wing_l_dm")
    sendEventImmediate(eid, [[EventCutPart offender=INVALID_ENTITY_ID, partNo=wingLPartNo]])

    let wingRPartNo = find_part_id_by_name(damage_model, "wing_r_dm")
    sendEventImmediate(eid, [[EventCutPart offender=INVALID_ENTITY_ID, partNo=wingRPartNo]])