local warningsCompsTrack = [
  ["ui_perf_stats.server_tick_warn", 0],
  ["ui_perf_stats.low_fps_warn", 0],
  ["ui_perf_stats.latency_warn", 0],
  ["ui_perf_stats.latency_variation_warn", 0],
  ["ui_perf_stats.packet_loss_warn", 0],
]

local warnings = persist("warnings", @() Watched(warningsCompsTrack.totable()))

::ecs.register_es("script_perf_stats_es",
  {
    [["onChange", "onInit"]] = function(evt, eid, comp) {
      foreach (i in warningsCompsTrack)
        warnings.value[i[0]] <- comp[i[0]]
    }
  },
  {comps_track=warningsCompsTrack.map(@(v) [v[0], ::ecs.TYPE_INT])}
)


return {
  warnings = warnings
}
 