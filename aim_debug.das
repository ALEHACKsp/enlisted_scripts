require ecs
require ecs.common
require app
require CollRes
require DagorConsole
require Dacoll
require DagorMath
require DagorDebug3D
require GridCollision
require EnlistedWeapon
require PhysMat

[console_cmd(name="aim.ruler")]
def draw_ruler()
  let found = find_query() <| $[es(REQUIRE=aimRulerDebug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !found
    createEntity("aim_ruler_debug")

[private, generic]
def trace_grid(pos, dir : float3; var len : float&; t : GridType)
  var res = INVALID_ENTITY_ID
  trace_grid_objects(pos, dir, len, t) <| $(intersections:array<IntersectedEntity>#)
    for it in intersections
      if it.t < len
        len = it.t
        res = it.eid
  return res

[es (tag=(render,dev), no_order, REQUIRE=aimRulerDebug)]
def draw_ruler_es(evt : UpdateStageInfoRenderDebug)
  find_query() <| $[es(REQUIRE=hero)](eid : EntityId)
    var aimTm: float3x4
    if !human_weap_get_aim_tm(eid, get_sync_time(), aimTm)
      return true
    let traceDir = aimTm[0]
    let tracePos = aimTm[3]
    var len = 4000f
    var norm : float3
    var color = E3DCOLOR(0xFFFFFFFF)
    var matId = PHYSMAT_INVALID
    var riDesc : RendInstDesc
    if traceray_normalized(tracePos, traceDir, len, matId, norm, ETF_ALL, riDesc, -1)
      color = E3DCOLOR(0xFF00FF00)
    var desc = "{len}m"
    let defaultTarget = trace_grid(tracePos, traceDir, len, GridType GT_DEFAULT)
    let lootTarget = trace_grid(tracePos, traceDir, len, GridType GT_LOOT)
    let gunTarget = trace_grid(tracePos, traceDir, len, GridType GT_STATIONARY_GUNS)
    let targetEid = !!gunTarget ? gunTarget : !!lootTarget ? lootTarget : defaultTarget
    if !targetEid
      if matId >= 0
        let mat & = get_material(matId)
        desc += " mat {matId} <{mat.name}>"
    else
      color = E3DCOLOR(0xFF00FF00)
      query(targetEid) <| $ [es] (possessedByPlr : EntityId?; transform : float3x4; collres: CollisionResource; material : string = "default")
        var t = 4000f
        if collres_traceray(collres, transform, aimTm[3], aimTm[0], t, norm, matId)
          let mat & = get_material(matId)
          desc += " pmat {matId} <{mat.name}>"
        desc += " mat {get_material_id(material)} <{material}>"
        if possessedByPlr != null
          desc += " plr <{get_string(*possessedByPlr, "name", "")}>"
      desc += " {targetEid} <{getEntityTemplateName(targetEid)}>"
    let pos = tracePos + traceDir * len
    draw_debug_line_buffered(tracePos, pos, color, 5)
    add_debug_text_mark(pos, desc, -1, 0., color)
    return true