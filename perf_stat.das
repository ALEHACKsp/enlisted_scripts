require ecs
require DagorTime
require DagorConsole
require DagorSystem
require DagorDebug3D

let
  FPS_UPDATE_PERIOD_MSEC = 200

struct PerfStat
  mean: float
  mode: float
  median: float
  minFps: int
  maxFps: int
  rangeFps: int

def process_stat(perf_stat_dot_data: IntList; var arr: array<int2>)
  var mean  = 0.f
  var totalCount = 0.f
  var mode = 0.f
  var maxCnt = 0
  var minFps = 10000
  var maxFps = 0
  for fps in iter_range(perf_stat_dot_data)
    let cnt = perf_stat_dot_data[fps]
    if cnt > 0
      push(arr, int2(fps, cnt))

      minFps = min(minFps, fps)
      maxFps = max(maxFps, fps)

      mean += float(cnt * fps)
      totalCount += float(cnt)
      if cnt > maxCnt
        maxCnt = cnt
        mode = float(fps)

  if totalCount <= 0.f
    return <- [[PerfStat]]

  sort(arr) <| $(a: int2; b: int2) { return a.y > b.y; }

  var median = int2()

  let medianIndex = float(length(arr) + 1) / 2.f
  var sum = 0.f
  for i in iter_range(arr)
    sum += float(arr[i].y)
    if sum >= medianIndex
      median = arr[i]
      break

  return <- [[PerfStat mean=mean/totalCount, mode=mode, median=float(median.x), minFps=minFps, maxFps=maxFps, rangeFps=maxFps-minFps]]

[console_cmd(name="perf_stat.draw")]
def perf_stat_draw()
  query() <| $[es](var perf_stat_dot_draw: bool&)
    perf_stat_dot_draw = !perf_stat_dot_draw

[console_cmd(name="perf_stat.reset")]
def perf_stat_reset()
  query() <| $[es](var perf_stat_dot_data: IntList)
    clear(perf_stat_dot_data)

[es (tag=gameClient, no_order)]
def client_perf_stat_es(info: UpdateStageInfoAct;
                        var perf_stat_dot_data: IntList;
                        var perf_stat_dot_lastFpsTimeMsec: int&;
                        var perf_stat_dot_lastFpsFrameNo: int&;
                        var perf_stat_dot_lastAverageFps: float&)
  let currentTimeMsec = get_time_msec()
  if currentTimeMsec <= perf_stat_dot_lastFpsTimeMsec + FPS_UPDATE_PERIOD_MSEC
    return

  let frameNo = int(get_dagor_frame_no())

  perf_stat_dot_lastAverageFps = 1000.f * float(frameNo - perf_stat_dot_lastFpsFrameNo) / (float(currentTimeMsec - perf_stat_dot_lastFpsTimeMsec) + 0.001f)

  perf_stat_dot_lastFpsTimeMsec = currentTimeMsec
  perf_stat_dot_lastFpsFrameNo  = int(frameNo)

  let fps = int(perf_stat_dot_lastAverageFps)
  if length(perf_stat_dot_data) <= fps
    resize(perf_stat_dot_data, fps + 1)
  perf_stat_dot_data[fps]++

[es (tag=gameClient, no_order)]
def client_perf_stat_draw_es(info: UpdateStageInfoRenderDebug; perf_stat_dot_data: IntList; perf_stat_dot_draw: bool)
  if !perf_stat_dot_draw
    return
  var arr: array<int2>
  let stat = process_stat(perf_stat_dot_data, arr)
  add_debug_text_mark_screen(50.f, 50.f, "Mean: {int(stat.mean)}", -1, 0.f, E3DCOLOR(0xffffffff))
  add_debug_text_mark_screen(50.f, 50.f, "Mode: {stat.mode}",      -1, 1.5f * 1.f, E3DCOLOR(0xffffffff))
  add_debug_text_mark_screen(50.f, 50.f, "Median: {stat.median}",  -1, 1.5f * 2.f, E3DCOLOR(0xffffffff))
  add_debug_text_mark_screen(50.f, 50.f, "minFps: {stat.minFps}",  -1, 1.5f * 3.f, E3DCOLOR(0xffffffff))
  add_debug_text_mark_screen(50.f, 50.f, "maxFps: {stat.maxFps}",  -1, 1.5f * 4.f, E3DCOLOR(0xffffffff))
  add_debug_text_mark_screen(50.f, 50.f, "range: {stat.rangeFps}", -1, 1.5f * 5.f, E3DCOLOR(0xffffffff))

[es (tag=gameClient, on_event=EventEntityDestroyed)]
def client_perf_stat_log_es(evt: Event; perf_stat_dot_data: IntList)
  var arr: array<int2>
  let stat = process_stat(perf_stat_dot_data, arr)

  print(">>>> Perf stat (fps: frames count)")
  for i in iter_range(arr)
    let fps = arr[i].x
    let cnt = arr[i].y
    if cnt > 0
      print("{fps}: {cnt}")

  print("Mean: {stat.mean}")
  print("Mode: {stat.mode}")
  print("Median: {stat.median}")
  print("Min: {stat.minFps}")
  print("Max: {stat.maxFps}")
  print("Range: {stat.maxFps-stat.minFps}")