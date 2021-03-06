local dagor_sys = require("dagor.system")

local function registerScriptProfiler(prefix) {
  if (dagor_sys.DBGLEVEL > 0) {
    local profiler = require("dagor.profiler")
    local profiler_reset = profiler.reset_values
    local profiler_dump = profiler.dump
    local profiler_get_total_time = profiler.get_total_time
    local isProfileOn = persist("isProfileOn", @() Watched(false))
    local isSpikesProfileOn = persist("isSpikesProfileOn", @() Watched(false))
    local spikesThresholdMs = persist("spikesThresholdMs", @() Watched(10))

    local function toggleProfiler(newVal = null) {
      local ret
      if (newVal == isProfileOn.value)
        ret = "already"
      isProfileOn(!isProfileOn.value)
      if (isProfileOn.value)
        ret = "on"
      else
        ret = "off"
      if (ret=="on"){
        console_print(ret)
        profiler.start()
        return ret
      }
      if (ret=="off"){
        profiler.stop()
      }
      console_print(ret)
      return ret
    }
    local function profileSpikes(){
      if (profiler_get_total_time() > spikesThresholdMs.value*1000)
        profiler_dump()
      profiler_reset()
    }
    local function toggleSpikesProfiler(){
      isSpikesProfileOn(!isSpikesProfileOn.value)
      if (isSpikesProfileOn.value){
        console_print("starting spikes profiler with threshold {0}ms".subst(spikesThresholdMs.value))
        ::gui_scene.clearTimer(profileSpikes)
        profiler_reset()
        profiler.start()
        ::gui_scene.setInterval(0.005, profileSpikes)
      }
      else{
        console_print("stopping spikes profiler")
        ::gui_scene.clearTimer(profileSpikes)
      }
    }
    local function setSpikesThreshold(val){
      spikesThresholdMs(val.tofloat())
      console_print("set spikes threshold to {0} ms".subst(spikesThresholdMs.value))
    }
    console.register_command(@() toggleProfiler(true), $"{prefix}.profiler.start")
    console.register_command(@() toggleProfiler(false), $"{prefix}.profiler.stop")
    console.register_command(@() toggleProfiler(null), $"{prefix}.profiler.toggle")
    console.register_command(toggleSpikesProfiler, $"{prefix}.profiler.spikes")
    console.register_command(setSpikesThreshold, $"{prefix}.profiler.spikesMsValue")
    console.register_command(@(threshold) profiler.detect_slow_calls(threshold), $"{prefix}.profiler.detect_slow_calls")
  }
}

return registerScriptProfiler
 