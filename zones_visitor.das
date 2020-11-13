require ecs
require zones
require game.es.events
require ecs.common

[es (tag=server, after=after_net_phys_sync)]
def zones_visitor_update_es(info : UpdateStageInfoAct;
                            eid : EntityId;
                            var zones_visitor_dot_zonesIn : EidList;
                            zones_visitor_dot_triggerTag : string;
                            transform : float3x4;
                            isAlive : bool = true)
  if ! isAlive
    leave_zones_if(eid, zones_visitor_dot_zonesIn) <| $ (zoneEid : EntityId)
      return !(get_bool(zoneEid, "zone.keepDead") ?? false)
    return

  get_active_zones_on_pos(transform[3]) <| $ (newZones)
    leave_zones_if(eid, zones_visitor_dot_zonesIn) <| $ (oldZoneEid : EntityId)
      return !(has_value(newZones, oldZoneEid) && has(oldZoneEid, zones_visitor_dot_triggerTag))
    for zoneEid in newZones
      if has(zoneEid, zones_visitor_dot_triggerTag) && !has_value(zones_visitor_dot_zonesIn, zoneEid)
        push_back(zones_visitor_dot_zonesIn, zoneEid)
        sendEvent(zoneEid, [[EventZoneEnter visitorEid=eid]])

def leave_zones_if(eid : EntityId; var zones_in : EidList ; condition)
  var zoneIdx = 0
  while zoneIdx < length(zones_in)
    let zoneEid = zones_in[zoneIdx]
    if invoke(condition, zoneEid)
      sendEvent(zoneEid, [[EventZoneLeave visitorEid=eid]])
      erase(zones_in, zoneIdx)
    else
      zoneIdx++

[es (tag=server, on_event=EventEntityDestroyed)]
def zones_visitor_destroyed_es(evt : Event; eid : EntityId;
                               zones_visitor_dot_zonesIn : EidList)
  for zoneEid in zones_visitor_dot_zonesIn
    sendEvent(zoneEid, [[EventZoneLeave visitorEid=eid]])

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def zones_visitor_init_last_trigger_tag(evt: Event; zones_visitor_dot_triggerTag: string;
                                        var zones_visitor_dot_lastTriggerTag : das_string)
  zones_visitor_dot_lastTriggerTag := zones_visitor_dot_triggerTag

[es (tag=server, track=isInVehicle, on_event=(EventEntityCreated, EventComponentsAppear), after=zones_visitor_init_last_trigger_tag)]
def zones_visitor_vehicle_overload_trigger_tag_es(evt : Event;
                                                  isInVehicle : bool;
                                                  human_anim_dot_vehicleSelected : EntityId;
                                                  var zones_visitor_dot_triggerTag : das_string;
                                                  var zones_visitor_dot_lastTriggerTag : das_string)
  if !isInVehicle
    zones_visitor_dot_triggerTag := zones_visitor_dot_lastTriggerTag
  else // apply vehicle's trigger tag to visitor (i.e. human)
    var visitorTriggerTag & = zones_visitor_dot_triggerTag
    ecs::query(human_anim_dot_vehicleSelected) <| $ [es (REQUIRE=overloadZonesVisitorTriggerTag)] (zones_visitor_dot_triggerTag : string)
      zones_visitor_dot_lastTriggerTag := visitorTriggerTag
      visitorTriggerTag := zones_visitor_dot_triggerTag
