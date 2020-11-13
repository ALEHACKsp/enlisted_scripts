require ecs
require EnlistedHuman
require HumanPhys
require Dacoll

[es (tag=server, no_order)]
def stop_burning_underwater(info: UpdateStageInfoAct;
                            human_net_phys : HumanActor;
                            transform: float3x4;
                            burning_dot_extinguishWaterLevelStand : float;
                            burning_dot_extinguishWaterLevelCrouch : float;
                            burning_dot_extinguishWaterLevelCrawl : float;
                            var burning_dot_underwaterNextCheckTime : float&;
                            var burning_dot_isBurning : bool&;
                            burning_dot_underwaterCheckPeriod : float = 1.0)
  if !burning_dot_isBurning
    return
  if info.curTime < burning_dot_underwaterNextCheckTime
    return
  burning_dot_underwaterNextCheckTime = info.curTime + burning_dot_underwaterCheckPeriod

  let phys& = human_net_phys.phys
  let state& = phys.currentState

  var waterLevel = 0.f;
  let pos = transform[3]
  let posWithOffset = pos - state.posOffset
  if traceht_water(posWithOffset, waterLevel)
    waterLevel -= (pos.y - state.posOffset.y);

  var posHeight = burning_dot_extinguishWaterLevelStand
  if state.height < -0.5
    posHeight = burning_dot_extinguishWaterLevelCrawl
  elif state.height < 0.5
    posHeight = burning_dot_extinguishWaterLevelCrouch

  if waterLevel > posHeight
    burning_dot_isBurning = false