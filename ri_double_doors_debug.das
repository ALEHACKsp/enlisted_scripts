require ecs
require game.es.events
require math.base
require math.color
require RendInst
require DagorMath
require DagorConsole
require DagorDebug3D
require CollRes


[console_cmd (name="double_doors_debug")]
def debug_double_doors(draw_double_doors : bool = true)
  let tmpl = "double_doors_debug"
  ecs::createTemplate(tmpl, "", "", "", false) <| $(var cmp : ecs::ComponentsMap)
    set(cmp, "draw_double_doors", false)
  ecs::query() <| $[es] (eid : EntityId; camera_dot_active : bool)
    if camera_dot_active
      addSubTemplate(eid, tmpl) <| $ (var init)
        set(init, "draw_double_doors", draw_double_doors)


[es (tag=render, tag=dev, no_order)]
def debug_double_doors_es(evt : UpdateStageInfoRenderDebug; camera_dot_active, draw_double_doors : bool; transform : float3x4)
  if camera_dot_active && draw_double_doors
    begin_draw_cached_debug_lines(true, true, false)

    let camTm = transform
    ecs::query() <| $ [es] (eid, pair_door_dot_eid : EntityId; ri_extra : RiExtraComponent; transform : float3x4)
      if !pair_door_dot_eid || length_sq(camTm[3] - transform[3]) > square(100.0)
        return

      let riType = handle_to_ri_type(ri_extra.handle)
      let collres = get_ri_gen_extra_collres(int(riType))
      if collres == null
        return

      var box = collres.vFullBBox
      let scale = 4.0
      if box.bmin.x < box.bmin.z
        box.bmin.x *= scale
      else
        box.bmin.z *= scale
      if box.bmax.x < box.bmax.z
        box.bmax.x *= scale
      else
        box.bmax.z *= scale

      var seed = int(uint(eid) < uint(pair_door_dot_eid) ? uint(eid) : uint(pair_door_dot_eid))
      let color = rnd_color(seed)

      set_cached_debug_lines_wtm(transform);
      draw_cached_debug_box(BBox3(box), color)

    end_draw_cached_debug_lines()
