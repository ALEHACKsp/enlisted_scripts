require ecs
require zones
require net
require game.es.events
require ecs.common
require strings

[es(tag=server, on_event=EventComponentChanged, track=isAlive)]
def capturer_died_es_event_handler(evt : Event; eid : EntityId; isAlive : bool;
                                   var capturer_dot_capZonesIn : EidList;
                                   var capturer_dot_capZonesInBlocked : EidList)
  if ! isAlive
    leave_capzones_if(eid, capturer_dot_capZonesIn) <| $ (zoneEid : EntityId)
      return !(get_bool(zoneEid, "zone.keepDead") ?? false)
    clear(capturer_dot_capZonesInBlocked)

[es (tag=server, after=after_net_phys_sync)]
def capturer_es(info : UpdateStageInfoAct;
                eid : EntityId;
                capturer_dot_updatePeriod : float;
            var capturer_dot_nextUpdateAt : float&;
                var capturer_dot_capZonesIn : EidList;
                var capturer_dot_capZonesInBlocked : EidList;
                zones_visitor_dot_triggerTag : string;
                transform : float3x4;
                isAlive : bool = true;
                isDowned : bool = false;
                isInVehicle  : bool = false)
  if info.curTime < capturer_dot_nextUpdateAt || !isAlive
    return
  let updateTimeOveflow = info.curTime - capturer_dot_nextUpdateAt
  if updateTimeOveflow < capturer_dot_updatePeriod
    capturer_dot_nextUpdateAt += capturer_dot_updatePeriod
  else // either initial update, huge dt or small interval
    capturer_dot_nextUpdateAt = info.curTime + capturer_dot_updatePeriod * eid_unit(eid)

  get_active_capzones_on_pos(transform[3], zones_visitor_dot_triggerTag) <| $ (newZones)
    var oldZoneIdx = 0
    while oldZoneIdx < length(capturer_dot_capZonesIn)
      let oldZoneEid = capturer_dot_capZonesIn[oldZoneIdx]
      if has_value(newZones, oldZoneEid)
        oldZoneIdx++
      else
        sendEvent(oldZoneEid, [[EventCapZoneLeave visitorEid=eid]])
        erase(capturer_dot_capZonesIn, oldZoneIdx)
        let blockedIdx = find_index(capturer_dot_capZonesInBlocked, oldZoneEid)
        if blockedIdx >= 0
          erase(capturer_dot_capZonesInBlocked, blockedIdx)

    for zoneEid in newZones
      let zonesInIdx = find_index(capturer_dot_capZonesIn, zoneEid)
      let newZone = zonesInIdx < 0

      var blockedText = ""
      if isDowned && has(zoneEid, "zone.excludeDowned")
        blockedText = "capture/BlockedCaptureDowned"
      elif isInVehicle && !(get_bool(zoneEid, "capzone.canCaptureOnVehicle") ?? true)
        blockedText = "capture/BlockedCaptureVehicle"

      if !empty(blockedText)
        if !newZone
          sendEvent(zoneEid, [[EventCapZoneLeave visitorEid=eid]])
          erase(capturer_dot_capZonesIn, zonesInIdx)
        if !has_value(capturer_dot_capZonesInBlocked, zoneEid)
          sendEvent(eid, [[CmdHeroLogEvent event="zone_capture_blocked_log", text=blockedText]])
          push_back(capturer_dot_capZonesInBlocked, zoneEid)
        continue

      if newZone
        let blockedIdx = find_index(capturer_dot_capZonesInBlocked, zoneEid)
        if blockedIdx >= 0
          erase(capturer_dot_capZonesInBlocked, blockedIdx)
        push_back(capturer_dot_capZonesIn, zoneEid)
        sendEvent(zoneEid, [[EventCapZoneEnter visitorEid=eid]])

def leave_capzones_if(eid : EntityId; var zones_in : EidList ; condition)
  var zoneIdx = 0
  while zoneIdx < length(zones_in)
    let zoneEid = zones_in[zoneIdx]
    if invoke(condition, zoneEid)
      sendEvent(zoneEid, [[EventCapZoneLeave visitorEid=eid]])
      erase(zones_in, zoneIdx)
    else
      zoneIdx++

[es (tag=server, on_event=EventEntityDestroyed)]
def capturer_destroyed_es(evt : Event; eid : EntityId; capturer_dot_capZonesIn : EidList)
  for zoneEid in capturer_dot_capZonesIn
    sendEvent(zoneEid, [[EventCapZoneLeave visitorEid=eid]])
