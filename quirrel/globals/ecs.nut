                                                                                     

                                                           
                             
                                                       
                                                          
    
local { has_network } = require("net")
local { logerr } = require("dagor.debug")
local { get_game_name } = require("app")

global const INVALID_ENTITY_ID = 0//::ecs.INVALID_ENTITY_ID
local unicastSqEvents = {}
//local broadcastNativeEvents = ["onUpdate", ::ecs.EventComponentChanged, ::ecs.EventComponentsAppear, ::ecs.EventComponentsDisappear, ::ecs.EventEntityCreated, ::ecs.EventEntityDestroyed]

local sqEvents = {}
local event = {}
const VERBOSE_PRINT = false //::getroottable()?.__is_stub__
local verbose_print = VERBOSE_PRINT ? @(val) ::print(val) : @(val) null

local function register_event(name, eventType, structure=null){

  ::assert(::ecs.EVCAST_UNICAST == eventType || ::ecs.EVCAST_BROADCAST == eventType,
            "eventType should be ::ecs.EVCAST_UNICAST || ::ecs.EVCAST_BROADCAST")
  verbose_print($"registering sq event {name}; ")
  ::assert (::type(name) =="string", "event name should be string")
  ::assert(!(name in sqEvents), @() $"event: '{name}' already registered!")
  sqEvents[name] <- name
  local eventRegisteredName = ::ecs.register_sq_event(name, structure!=null, eventType)
  event[name] <- function(payload=null){
//  todo - add type checking
    if (structure == null) {
      ::assert (payload == null)
      return ::ecs.SQEvent(eventRegisteredName)
    }
    ::assert (payload != null)
    return ::ecs.SQEvent(eventRegisteredName, payload)
  }
}

local function mkEsFuncNamed(esname, func) {
  ::assert(["function", "instance", "table"].indexof(::type(func)) != null, $"esHandler can be only function or callable, for ES '{esname}', got type: {::type(func)}")
  local infos = func?.getfuncinfos?()
  ::assert(infos!=null, "esHandler can be only function or callable, ES:{0}".subst(esname))
  local len = infos.parameters.len()
  ::assert (len < 5 && len > 2,
    $"ES function should have at least 2 params - eid, comp, or 3 - evt, eid, comp. function name:{infos?.name}, argnum:{" ".join(infos?.parameters ?? [])}, arguments:{len}, es name:{esname}")
  if (len==4)
    return func
  else
    return function(evt, eid, comp) {func(eid, comp)}
}

local function gatherComponentNames(component_list){
  local res = []
  foreach (component in component_list){
    if (::type(component) =="string")
      res.append(component)
    else
      res.append(component[0])
  }
  return res
}

const INTERNAL_REGISTER_ECS = "___register_entity_system_internal___"
if (INTERNAL_REGISTER_ECS not in ::ecs) {
  ::ecs[INTERNAL_REGISTER_ECS] <- ::ecs.register_entity_system
  ::ecs.register_entity_system = @(name, events, comps, params) ::assert(false, "register_entity_system considered unsafe. use ecs.register_es instead")
}

local ecs_register_entity_system = ::ecs[INTERNAL_REGISTER_ECS]

local function register_es(name, onEvents={}, compsDesc={}, params = {}) {
  try{
    foreach (k, v in compsDesc)
      ::assert(["comps_ro","comps_rw","comps_rq","comps_no","comps_track"].indexof(k) != null, $"incorrect comps description, incorrect key: {k}, es name:{name}")
    local comps = compsDesc
    local remappedEvents = {}
    local mkEsFunc = @(func) mkEsFuncNamed(name, func)
    local remap = {
      onInit = [::ecs.EventEntityCreated, ::ecs.EventScriptReloaded, ::ecs.EventComponentsAppear],
      onChange = [::ecs.EventComponentChanged],
      onDestroy = [::ecs.EventEntityDestroyed, ::ecs.EventComponentsDisappear]
    }
    foreach (k, func in onEvents) {
      if (k in remap) {
        foreach (j in remap[k])
          remappedEvents[j] <- mkEsFunc(func)
      }
      else if (::type(k) == "array") {
        foreach (e in k) {
          if (e in remap) {
            foreach (j in remap[e])
              remappedEvents[j] <- mkEsFunc(func)
          }
          else
            remappedEvents[e] <- mkEsFunc(func)
        }
      }
      else
        remappedEvents[k] <- mkEsFunc(func)
    }
    ::assert(remappedEvents.len()>0, $"can't register ES '{name}' without any events")
    ::assert(!("OnUpdate" in remappedEvents), $"ES: {name}, OnUpdate is incorrect eventListener, should be onUpdate")
    foreach (k, v in remappedEvents) {
      ::assert(k in ::ecs.sqEvents || ["Timer","onUpdate"].indexof(k) != null || (::type(k) == "class"), $"unknown event {k}. Script events should be registered via ::ecs.register_event()")
    }
    local isChangedTracked = ::ecs.EventComponentChanged in remappedEvents
    local comps_track = comps?.comps_track ?? []
    ::assert((!isChangedTracked && comps_track.len()==0) || (isChangedTracked && comps_track.len()>0) || ((params?.track?.len() ?? 0) >0), "ecs registered for EventComponentChanged should have comps_track in components or CSV 'track' in params!")
    local comps_ro = [].extend(comps?.comps_ro ?? []).extend(comps_track)
    comps = clone comps
    if (comps_ro.len() > 0)
      comps.comps_ro <- comps_ro
    ::assert(!(comps_track.len()>0 && params?.track!=null), "es cannot be registered if both 'comp_tracks' in components and 'track' in params")
    if (comps_track.len()>0) {
      delete comps.comps_track
      params = (clone params).__merge({track=",".join(gatherComponentNames(comps_track))})
    }
    if ((comps?.comps_ro ?? []).filter(@(v) ::type(v)!="array").len()!=0)
     logerr($"{name} register error: all read only components should be specified with type")
    if ((comps?.comps_rw ?? []).filter(@(v) ::type(v)!="array").len()!=0)
      logerr($"{name} register error: all read only components should be specified with type")
    verbose_print($"registering {name};")
    ecs_register_entity_system(name, remappedEvents, comps, params)
    verbose_print($"ecs: {name} registered;")
    local comps_len = 0
    comps_len += comps?.comps_ro?.len != null ? comps.comps_ro.len() : 0
    comps_len += comps?.comps_rw?.len != null ? comps.comps_rw.len() : 0
    comps_len += comps?.comps_rq?.len != null ? comps.comps_rq.len() : 0
    if (comps_len == 0) {
      local unicastEvents = remappedEvents.filter(@(v, k) k in unicastSqEvents ) //do not enumerate native events
      ::assert(unicastEvents.len() == 0, $"es {name} registered for unicast events without any components!")
      verbose_print($"ecs: '{name}' is registered for performing queries, as it has zero required components; ")
    }
    if ("onUpdate" in remappedEvents) {
      ::assert("before" in params || "after" in params, @() $"{name} need syncpoints ('before' and/or 'after' in params)")
    }
    local comps_ro_optional_num = comps_ro.filter(@(v) ::type(v)=="array" && v.len() > 2).len()
    local comps_rw = comps?.comps_rw ?? []
    ::assert(
      comps_len == 0 || !(comps_ro_optional_num == comps_ro.len() && ((comps_rw.len() ?? 0) + (comps?.comps_rq.len() ?? 0))==0),
      @() $"es {name} registered with all optional components"
    )
    ::assert(
      comps_rw.filter(@(v) ::type(v) != "array" || v.len()==1).len()==0
      $"es {name} registered with rw components without type specified. should be [<name>:string, <type>:type]"
    )
    ::assert(
      comps_rw.filter(@(v) v.len()>2).len()==0
      $"es {name} registered with rw components with specified default value"
    )
    ::assert(
      comps_rw.indexof("eid")==null, "eid can't be writable component"
    )
    ::assert(
      comps?.comps_no.indexof("eid")==null, "eid can't be set as 'no' component"
    )
  }
  catch (e){
    logerr(": ".concat($"error in '{name}'", e))
  }
}

local function update_component(eid, component_name) {
  console.command($"ecs.update_component {eid} {component_name}")
}


local function makeTemplate(params={}){
  local addTemplates = params?.addTemplates ?? []
  local removeTemplates = [].extend(params?.removeTemplates ?? []).extend(addTemplates)
  local baseTemplates = params?.baseTemplate.split("+") ?? []
  return "+".join(
            baseTemplates
            .filter(@(v) removeTemplates.indexof(v) == null)
            .extend(addTemplates)
          )
}

local recreateEntityWithTemplates = ::kwarg(function(eid=INVALID_ENTITY_ID, removeTemplates=[], addTemplates=[], comps={}, callback=null){
  removeTemplates = [].extend(removeTemplates).extend(addTemplates)
  if (eid == INVALID_ENTITY_ID || !::ecs.g_entity_mgr.doesEntityExist(eid))
    return
  local curTemplate = ::ecs.g_entity_mgr.getEntityFutureTemplateName(eid)
  // curTemplate is null when destroyEntity() is called right before recreateEntityWithTemplates
  // In such case doesEntityExist() still true
  if (curTemplate == null)
    return
  local newTemplatesName = makeTemplate({baseTemplate=curTemplate, addTemplates=addTemplates, removeTemplates = removeTemplates})
  if (newTemplatesName != curTemplate)
    ::ecs.g_entity_mgr.reCreateEntityFrom(eid, newTemplatesName, comps, callback)
})

local _get_msgSink = ::ecs.SqQuery("_get_msgSink", {comps_rq = ["msg_sink"]})
local function _get_msg_sink_eid(){
  return _get_msgSink.perform(@(eid, comp) eid) ?? INVALID_ENTITY_ID
}

local function client_send_event(eid, evt){
  if (has_network())
    return ::ecs.client_request_unicast_net_sqevent(eid, evt)
  else
    return ::ecs.g_entity_mgr.sendEvent(eid, evt)
}

local function client_broadcast_event(evt){
  if (has_network())
    return ::ecs.client_request_broadcast_net_sqevent(evt)
  else
    return ::ecs.g_entity_mgr.broadcastEvent(evt)
}

local function client_msg_sink(evt) {
  return client_send_event(_get_msg_sink_eid(), evt)
}

local function server_broadcast_event(evt, connids=null){
  if (has_network()){
    if (connids && connids.len()>0)
      ::ecs.server_broadcast_net_sqevent(evt, connids)
    else
      ::ecs.server_broadcast_net_sqevent(evt)
  }
  else
    ::ecs.g_entity_mgr.broadcastEvent(evt)
}

local function server_send_event(eid, evt, connids=null){
  if (has_network()){
    if (connids && connids.len()>0)
      ::ecs.server_send_net_sqevent(eid, evt, connids)
    else
      ::ecs.server_send_net_sqevent(eid, evt)
  }
  else
    ::ecs.g_entity_mgr.sendEvent(eid, evt)
}

local function server_msg_sink(evt, connids=null) {
  server_send_event(_get_msg_sink_eid(), evt, connids)
}

local function query_map(query, func, filter_str = null){
  ::assert(query instanceof ::ecs.SqQuery, "need SqQuery instance as first argument")
  ::assert(filter_str == null  || ::type(filter_str) == "string", "filter string should be string or null")
  local res = []
  if (filter_str != null)
    query.perform(function(eid, comp) {res.append(func(eid, comp))}, filter_str)
  else
    query.perform(function(eid, comp) {res.append(func(eid, comp))})
  return res
}

local function list2array(list){
  local res = []
  foreach (v in list){
    res.append(v)
  }
  return res
}

local function set_array2list(_array, list){
  list.clear()
  foreach (v in _array)
    list.append(v)
  return list
}

::ecs.__update({
  register_event
  register_es
  recreateEntityWithTemplates
  makeTemplate
  update_component
  sqEvents
  event

  client_msg_sink
  client_send_event
  client_broadcast_event

  server_msg_sink
  server_send_event
  server_broadcast_event

  query_map

  map_list2array = @(list,func) list2array(list).map(func)
  array2list = set_array2list
  list2array
})

local mkRegisterEventByMap = @(eventType) function(payload, eventName){
  if (payload == null)
    ::ecs.register_event(eventName, eventType)
  else
    ::ecs.register_event(eventName, eventType, payload)
}
local registerUnicastEvents = mkRegisterEventByMap(::ecs.EVCAST_UNICAST)
local registerBroadcastEvents = mkRegisterEventByMap(::ecs.EVCAST_BROADCAST)
//this is done here only to have all events in all VMs
local commonEvents = require("register_sqevents.nut")
local gameEvents = require_optional($"{get_game_name()}/globals/register_sqevents.nut") ?? {}
local events = {
  unicastEvents={}.__update(commonEvents?.unicastEvents ?? {}).__update(gameEvents?.unicastEvents ?? {})
  broadcastEvents = {}.__update(commonEvents?.broadcastEvents ?? {}).__update(gameEvents?.broadcastEvents ?? {})
}
events.unicastEvents.each(registerUnicastEvents)
events.broadcastEvents.each(registerBroadcastEvents)
unicastSqEvents.clear()
unicastSqEvents.__update(events.unicastEvents)
//broadcastSqEvents.__update(events.broadcastEvents)//for type check in register es
 