local {trackPlayerStart = null} = require("demo_track_player.nut")
if (trackPlayerStart==null)
  return
local {EventLevelLoaded} = require("gameevents")
local {argv} = require("dagor.system")
local {get_time_msec} = require("dagor.time")
local io = require("io")
local string = require("string")
local platform = require("globals/platform.nut")
local { exit_game } = require("app")


local benchmarkParamsQuery = ::ecs.SqQuery("benchmarkParamsQuery", {comps_rw=[["benchmark_runs", ::ecs.TYPE_INT], ["benchmark_name", ::ecs.TYPE_STRING]]})

local setBParam = @(compName, commandlinearg, transform = @(v) v) function () {
  local set = argv
    .filter(@(a) a && string.startswith(a, $"{commandlinearg}="))
    .map(@(a) transform(string.split(a, "=")[1]))?[0]
  if (set!=null)
    benchmarkParamsQuery.perform(function(eid, comp) {
      ::log(compName, set)
      comp[compName] = set
    })
}
local setRuns = setBParam("benchmark_runs", "benchmark_passes", @(v) v.tointeger())
local setName = setBParam("benchmark_name", "benchmark_name")

local benchStatsComps = [
  ["averageDt", ::ecs.TYPE_FLOAT],
  ["prevMsec", ::ecs.TYPE_INT],
  ["firstMsec", ::ecs.TYPE_INT],
  ["frames", ::ecs.TYPE_INT],
  ["slowFrames", ::ecs.TYPE_INT],
  ["verySlowFrames", ::ecs.TYPE_INT],
  ["currentRun", ::ecs.TYPE_INT],
  ["benchmark_runs", ::ecs.TYPE_INT],
  ["benchmark_name", ::ecs.TYPE_STRING],
]

local benchStatsQuery = ::ecs.SqQuery("benchStatsQuery", {comps_rw=benchStatsComps, comps_ro=[["benchmark_name",::ecs.TYPE_STRING, "benchmark_runs"]]})

local function saveAndResetStats(){

  benchStatsQuery.perform(function(eid, comps){

    local benchmarkName = comps.benchmark_name
    if (benchmarkName != "" && comps.currentRun > 0) {
      local stats = benchStatsQuery.perform(@(eid, comp) clone comp)
      local file_name = $"benchmark.{benchmarkName}.{stats.currentRun}.txt"
      local file_path = file_name
      if (platform.is_ps4)
        file_path = $"/hostapp/{file_name}"
      else if (platform.is_nswitch)
        file_path = $"save:/{file_name}"
      local f = io.file(file_path, "wt")
      local {slowFrames, frames, prevMsec, firstMsec, verySlowFrames} = stats
      frames = frames > 0 ? frames : 1
      prevMsec = prevMsec > firstMsec ? prevMsec : firstMsec+1
      local res = "\n".concat(
        $"avg_fps={1000.0 * frames / (prevMsec - firstMsec)}",
        $"score={frames}",
        $"slow_frames_pct={100.0 * slowFrames / frames}",
        $"very_slow_frames_pct={100.0 * verySlowFrames / frames}",
        $"RawStats: frames={frames}, slowFrames={slowFrames}, verySlowFrames={slowFrames}, timeTakenMs={prevMsec - firstMsec}, timeStartedMs={firstMsec}, timeEndMs={prevMsec}",
        "\n"
      )
      f.writestring(res)
      f.close()
    }
    foreach(compName, _ in comps){
      if (compName == "benchmark_name" || compName == "benchmark_runs")
        continue
      if (compName == "currentRun")
        comps.currentRun++
      else if (compName == "averageDt")
        comps[compName] = 0.0
      else if (compName == "firstMsec")
        comps[compName] = get_time_msec()
      else
        comps[compName] = 0
    if (comps.currentRun > comps.benchmark_runs)
      exit_game()
    }
  })
}

local activeBenchmarkQuery = ::ecs.SqQuery("activateBenchmarkQuery", {comps_rw=[["benchmark_active", ::ecs.TYPE_BOOL]]})
local activateBenchmark = @() activeBenchmarkQuery.perform(@(_, comp) comp.benchmark_active=true)

::ecs.register_es("benchmark_activate_es",
  { [EventLevelLoaded] = function(eid, comp) {
      saveAndResetStats()
      setRuns()
      setName()
      comp.benchmark_active=true
      local tracks = comp.camera_tracks?.getAll() ?? []
      if (tracks.len() == 0)
        tracks.append({duration=10.0})
      tracks.append(saveAndResetStats) //this is bad. better to send event that track was finished and do all on it
      ::ecs.set_callback_timer(function() {
        activateBenchmark()
        trackPlayerStart(tracks, 0.1, 0.15)
      }, 1.0, false)
    }
  },
  { comps_rw = [
      ["benchmark_active",::ecs.TYPE_BOOL],
    ],
    comps_ro = [
      ["camera_tracks",::ecs.TYPE_ARRAY, []],
    ]

  },
  {tags="gameClient"}
)
 