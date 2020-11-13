require ecs
require DagorTime

[es(no_order)]
def benchmark_update_es(
    info : UpdateStageInfoAct; //wont correctly work with fixed timestamp, but it is strange to benchmark it
    var averageDt: float&;
    var prevMsec: int&;
    var frames: int&;
    var slowFrames: int&;
    var verySlowFrames: int&;
    var benchmark_active : bool)

  if !benchmark_active
    return

  let msec = get_time_msec()
  let dt = float(msec - prevMsec) * 0.001
  frames = frames+1
  if averageDt == 0.0
    averageDt = dt
  else
    averageDt = dt * 0.1 + averageDt * 0.9

  if dt > averageDt * 2.5 && frames > 50
    slowFrames = slowFrames+1
  if dt > averageDt * 5.0
    verySlowFrames = verySlowFrames
  prevMsec = msec
