require ecs
require app
require DagorMath
require GamePhys

struct TimeData
  aliveTime : float
  expanseStartTime : float
  expanseFullTime : float
  fadeStartTime : float
  totalTime : float

def occluder_cvt(timeData : TimeData; data : float3)
  with timeData
    if aliveTime < expanseStartTime
      return data[0]
    if aliveTime < expanseFullTime
      return cvt(aliveTime, expanseStartTime, expanseFullTime, data[0], data[1])
    return cvt(aliveTime, fadeStartTime, totalTime, data[1], data[2])


[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def smoke_occluder_init(evt : Event; var smoke_occluder_dot_createdAtTime : float&)
  smoke_occluder_dot_createdAtTime = get_sync_time()

[es (tag=server, no_order)]
def smoke_occluder_update(info : UpdateStageInfoAct;
                          transform : float3x4;
                          smoke_occluder_dot_windScale : float;
                          smoke_occluder_dot_createdAtTime : float;
                          smoke_occluder_dot_expanseStartTime : float;
                          smoke_occluder_dot_expanseFullTime : float;
                          smoke_occluder_dot_fadeStartTime : float;
                          smoke_occluder_dot_totalTime : float;
                          smoke_occluder_dot_upSpeed : float3;
                          smoke_occluder_dot_normalSpeed : float3;
                          smoke_occluder_dot_littleSphereRadius : float3;
                          smoke_occluder_dot_bigSphereRadius : float3;
                          var smoke_occluder_dot_littleSphere : float4&;
                          var smoke_occluder_dot_bigSphere : float4&)
  let aliveTime = smoke_occluder_dot_createdAtTime >= 0.0 ? info.curTime - smoke_occluder_dot_createdAtTime : 0.0
  let timeData = [[TimeData aliveTime=aliveTime, expanseStartTime=smoke_occluder_dot_expanseStartTime, expanseFullTime=smoke_occluder_dot_expanseFullTime,
                            fadeStartTime=smoke_occluder_dot_fadeStartTime, totalTime=smoke_occluder_dot_totalTime]]

  let upSpeed = occluder_cvt(timeData, smoke_occluder_dot_upSpeed)
  let wind = get_wind()
  let startSpeedNormal = occluder_cvt(timeData, smoke_occluder_dot_normalSpeed)
  let normalDir = transform[1]
  var velocity = normalDir * startSpeedNormal
  velocity.y += upSpeed
  velocity += wind * smoke_occluder_dot_windScale
  let startPos = transform[3] + normalDir * startSpeedNormal

  let bigSphereRadius = occluder_cvt(timeData, smoke_occluder_dot_bigSphereRadius)
  let littleSphereRadius = occluder_cvt(timeData, smoke_occluder_dot_littleSphereRadius)

  let posBig = startPos + velocity
  let posLittle = startPos + (velocity + normalDir*littleSphereRadius*0.5)*0.5
  smoke_occluder_dot_littleSphere = float4(posLittle.x, posLittle.y, posLittle.z, littleSphereRadius)
  smoke_occluder_dot_bigSphere = float4(posBig.x, posBig.y, posBig.z, bigSphereRadius)
