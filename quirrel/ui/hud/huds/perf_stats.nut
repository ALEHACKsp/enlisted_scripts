local warnings = require("ui/hud/state/perf_stats_es.nut").warnings
local {horPadding, verPadding} = require("globals/safeArea.nut")
local cursors = require("ui/style/cursors.nut")
local picSz = sh(3.3)
local {hudIsInteractive} = require("ui/hud/state/interactive_state.nut")

local function pic(name) {
  return ::Picture("ui/skin#qos/{0}.svg:{1}:{1}:K".subst(name, picSz.tointeger()))
}

local icons = {
  ["ui_perf_stats.server_tick_warn"] = {pic = pic("server_perfomance"), loc="hud/server_tick_warn_tip"},
  ["ui_perf_stats.low_fps_warn"] = {pic = pic("low_fps"), loc="hud/low_fps_warn_tip"},
  ["ui_perf_stats.latency_warn"] = {pic = pic("high_latency"), loc="hud/latency_warn_tip"},
  ["ui_perf_stats.latency_variation_warn"] = {pic = pic("latency_variation"), loc ="hud/latency_variation_warn_tip"},
  ["ui_perf_stats.packet_loss_warn"] = {pic = pic("packet_loss"), loc="hud/packet_loss_warn_tip"},
}

local colorMedium = Color(160, 120, 0, 160)
local colorHigh = Color(200, 50, 0, 160)
local debugWarnings = ::Watched(false)
local function mkidx() {
  local i = 0
  return @() i++
}
local cWarnings = ::Computed(function() {
  local idx = mkidx()
  return debugWarnings.value ? icons.map(@(v,i) 1+(idx()%2)) : clone warnings.value
})
console.register_command(@() debugWarnings(!debugWarnings.value),"ui.debug_perf_stats")

local function root() {
  local children = []

  foreach (key, val in cWarnings.value) {
    if (val > 0) {
      local hint = ::loc(icons[key]["loc"], "")
      local onHover = @(on) cursors.tooltip.state(on ? hint : null)
      children.append({
        key = key
        size = [picSz, picSz]
        image = icons[key]["pic"]
        behavior = hudIsInteractive.value ? Behaviors.Button : null
        skipDirPadNav = true
        onHover = onHover
        rendObj = ROBJ_IMAGE
        color = (val==2) ? colorHigh : colorMedium
      })
    }
  }

  return {
    watch = [cWarnings, verPadding, horPadding, hudIsInteractive]
    size = SIZE_TO_CONTENT
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    flow = FLOW_HORIZONTAL
    children = children
    margin = [max(verPadding.value/2.0,sh(0.4)), max(horPadding.value/1.2,sh(0.4))]
  }
}

return root
 