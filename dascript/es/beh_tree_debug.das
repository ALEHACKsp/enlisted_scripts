require ecs
require ecs.common
require net
require app
require DagorConsole
require DagorDebug3D
require DagorMath
require EnlistedWalkerai
require BehNodes
require walkerai
require math
require math.base
require EnlistedHuman
require HumanPhys
require daslib/strings_boost
require game.es.server_debug

[private]
def toggle_bots_template(template_name : string; activate : bool)
  ecs::query() <| $[es(REQUIRE_NOT=hero)](eid : EntityId; beh_tree_dot_enabled : bool)
    if beh_tree_dot_enabled
      let templateName = getEntityTemplateName(eid)
      var newTemplate = remove_sub_template_name(templateName, template_name)
      if activate
        newTemplate = "{newTemplate}+{template_name}"
      print("ai: {templateName} -> {newTemplate}")
      remote_recreate_entity_from(eid, newTemplate)

[private]
def remove_sub_template_name(template_name : string; sub : string)
  let parts <- split(template_name, "+{sub}")
  return length(parts) == 0 ? template_name : join(parts, "")

[console_cmd(name="ai.legacy_ai")]
def activate_legacy_ai(activate : bool = true)
  toggle_bots_template("squad_member_procedular_ai", activate)

[console_cmd(name="ai.debug_server_bots")]
def server_debug_behaviour_tree(activate : bool = true)
  toggle_bots_template("squad_member_server_debug_ai", activate)

[es(tag=server, tag=dev, REQUIRE="beh_tree.server_debug", no_order)]
def sync_server_beh_tree_state(evt: UpdateStageInfoAct; walker_agent : EntityAgent; var beh_tree_dot_debugState : das_string)
  beh_tree_dot_debugState := beh_tree_current_name(walker_agent.tree, true)

[es(tag=gameClient, tag=dev, REQUIRE="beh_tree.server_debug", no_order)]
def draw_server_beh_tree_state(evt: UpdateStageInfoRenderDebug; transform : float3x4; beh_tree_dot_debugState : string)
  let pos = transform[3]
  add_debug_text_mark(pos, "ai: {beh_tree_dot_debugState}", -1, 0f, E3DCOLOR(0xFFFFFFFF))

[console_cmd(name="ai.beh_tree_enabled")]
def debug_beh_tree(beh_tree_enabled : bool = true)
  ecs::query() <| $[es(REQUIRE=walker_agent, REQUIRE_NOT=hero)](var human_net_phys : HumanActor; var beh_tree_dot_enabled : bool&)
    beh_tree_dot_enabled = beh_tree_enabled

    if !beh_tree_enabled
      human_control_state_set_walk_speed(human_net_phys.phys.producedCT, 0.f)
      human_control_state_set_neutral_ctrl(human_net_phys.phys.producedCT)

[console_cmd(name="ai.debug_bots", hint="ai.debug_bots (debug_beh_tree, log_ai = false, debug_dangers = false)")]
def debug_behaviour_tree(debug_beh_tree : bool; log_ai : bool = false; debug_dangers : bool = false)
  let tmpl = "debug_bot_temp_template"
  ecs::createTemplate(tmpl, "", "", "", false) <| $(var cmp : ecs::ComponentsMap)
    set(cmp, "beh_tree.debug", false)
    new_ecs_array() <| $(var arr : Array)
      set(cmp, "beh_tree.debugLog", arr)
    set(cmp, "entity_danger.debug", false)
    set(cmp, "beh_tree.showDebugLog", false)
  ecs::query() <| $[es](eid : EntityId; beh_tree_dot_enabled : bool)
    if !beh_tree_dot_enabled
      return
    addSubTemplate(eid, tmpl) <| $(var init)
      set(init, "beh_tree.debug", debug_beh_tree)
      set(init, "entity_danger.debug", debug_dangers)
      set(init, "beh_tree.showDebugLog", log_ai)

[console_cmd(name="ai.debug_obstacles")]
def debug_obstacles(draw_obstacles : bool = true)
  let tmpl = "debug_obstacles_temp_template"
  ecs::createTemplate(tmpl, "", "", "", false) <| $(var cmp : ecs::ComponentsMap)
    set(cmp, "beh_tree.drawObstacles", false)
  ecs::query() <| $[es(REQUIRE=walker_agent)](eid : EntityId; beh_tree_dot_enabled : bool)
    if beh_tree_dot_enabled
      addSubTemplate(eid, tmpl) <| $(var init)
        set(init, "beh_tree.drawObstacles", draw_obstacles)

[es(tag=dev, tag=render, no_order)]
def debug_obstacles_render(evt : UpdateStageInfoRenderDebug; walker_agent : EntityAgent; beh_tree_dot_drawObstacles : bool)
  if !beh_tree_dot_drawObstacles
    return
  let offset = float3(0., 0.2, 0.)
  let live = 200
  for obstacle in walker_agent.obstacles
    let convex = length(obstacle.segments) > 2
    if convex
      draw_debug_sphere_buffered(obstacle.center, 1.0, E3DCOLOR(0xFFFF0000), 12, live)
    for seg in obstacle.segments
      let start = seg.start + offset
      let end = seg.end + offset
      if length_sq(seg.dir) > 1e-5
        let dir = normalize(end - start)
        let swap = convex && dot(seg.dir, dir) < 0f
        let st = swap ? end - dir * 0.2 : start + dir * 0.2
        let en = swap ? start + dir * 0.2 : end - dir * 0.2
        draw_debug_sphere_buffered(st, 0.1, E3DCOLOR(0xFFFF0000), 12, live)
        draw_debug_sphere_buffered(en, 0.1, E3DCOLOR(0xFF00FF00), 12, live)
      draw_debug_line_buffered(start, end, E3DCOLOR(0xFFFF0000), live)

[es(tag=dev, tag=render, no_order)]
def entity_dangers_debug(evt : UpdateStageInfoRenderDebug; eid : EntityId; agent_dangers : AgentDangers; transform : float3x4; entity_danger_dot_debug : bool)
  if !entity_danger_dot_debug || length(agent_dangers.dangers) == 0
    return
  let index = uint(eid)
  let idx1 = index & 7u
  let idx2 = (index >> 3u) & 3u
  let idx3 = (index >> 5u) & 3u
  let offset = float3(0f, float(idx1 + 1u) * 0.2, 0f)
  let color = E3DCOLOR(uint4(idx1 << 5u, idx2 << 6u, idx3 << 6u, 255u))
  let agentPos = transform[3] + offset
  draw_debug_sphere_buffered(agentPos, 0.2, color, 6, 20)
  let atTime = get_sync_time()
  for danger in agent_dangers.dangers
    if !danger.traceable
      continue
    let tm = get_TMatrix(danger.eid, "transform")
    if tm == null
      continue
    let pos = (*tm)[3] + offset
    var dir = agentPos - pos
    let lenSq = length_sq(dir)
    let str = "{danger.traceable?"* ":""}{danger.dangerMeter} noise {danger.noiseMeter} " + (danger.lastTime > 0f ? "{danger.lastTime}" : "{atTime - danger.lastTraceTime}")
    if lenSq > 4f
      let len = sqrt(lenSq)
      dir = dir * safeinv(len)
      let from = agentPos - dir * (len - 1.f)
      let to = pos + dir * (len - 0.7f)
      add_debug_text_mark(from, str, -1, 0f, color)
      add_debug_text_mark(to, str, -1, 0f, color)
    else
      let markPos = (pos + agentPos) * 0.5
      add_debug_text_mark(markPos, str, -1, 0f, color)

    if danger.lastTraceTime > 0f && atTime - danger.lastTraceTime < 0.2f
      draw_cached_debug_line(agentPos, pos, E3DCOLOR(0xFFFF0000))
    else
      draw_cached_debug_line(agentPos, pos, color)

[console_cmd(name="ai.kill")]
def kill_bots(num : int = 1)
  var count = 0
  ecs::find_query() <| $[es](beh_tree_dot_enabled : bool; var hitpoints_dot_hp: float&; hitpoints_dot_deathHpThreshold: float)
    if beh_tree_dot_enabled
      hitpoints_dot_hp = hitpoints_dot_deathHpThreshold
      ++count
    return count >= num

[es(tag=dev, after=walker_agent_es)]
def walker_agent_update_reaction(act : UpdateStageInfoAct; eid : EntityId;
                                 beh_tree_dot_showDebugLog : bool; walker_agent : EntityAgent;
                                 var beh_tree_dot_debugLog : Array&; beh_tree_dot_debugLogSize : int = 5)
  if !beh_tree_dot_showDebugLog || beh_tree_dot_debugLogSize <= 0
    return
  if walker_agent.tree.changeNodeReason != null
    let name = walker_agent.tree.changeNodeReason |> beh_node_hierarchy_name(true)
    beh_tree_dot_debugLog |> push_back("{act.curTime} {eid} {name}")
  if walker_agent.tree.resetReason != null
    let name = walker_agent.tree.resetReason |> beh_node_hierarchy_name(true)
    beh_tree_dot_debugLog |> push_back("{act.curTime} {eid} {name}")
  while length(beh_tree_dot_debugLog) > beh_tree_dot_debugLogSize
    beh_tree_dot_debugLog |> erase(0)

[es(tag=(dev, render), after=walker_agent_update_es)]
def walker_agent_debug_reaction(act : UpdateStageInfoRenderDebug; transform : float3x4;
                                beh_tree_dot_showDebugLog : bool; beh_tree_dot_debugLog : Array&)
  if !beh_tree_dot_showDebugLog
    return
  let pos = transform[3]
  var lineOffset = float(length(beh_tree_dot_debugLog))
  let color = E3DCOLOR(uint4(40, 40, 40, 160))
  for it in beh_tree_dot_debugLog
    add_debug_text_mark(pos, get_string(it, ""), -1, lineOffset, color)
    lineOffset -= 1f