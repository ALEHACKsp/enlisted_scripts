require ecs
require math public
let
  INVALID_ENTITY_ID:EntityId = EntityId(INVALID_ENTITY_ID_VAL)
[generic]
def createEntity ( templ:string; subexpr:block<(var compInit:ComponentsInitializer):void>):EntityId
  return _builtin_create_entity(templ, subexpr)
[generic]
def createEntitySync ( templ:string; subexpr:block<(var compInit:ComponentsInitializer):void>):EntityId
  return _builtin_create_entity_sync(templ, subexpr)
[generic]
def reCreateEntityFrom ( eid:EntityId const; templ:string; subexpr:block<(var compInit:ComponentsInitializer):void>):EntityId
  return _builtin_recreate_entity(eid, templ, subexpr)
[generic]
def createEntity ( templ:string; callback:lambda<(id:EntityId):void>; subexpr:block<(var compInit:ComponentsInitializer):void> ):EntityId
  return _builtin_create_entity_lambda(templ, callback, subexpr)
[generic]
def reCreateEntityFrom ( eid:EntityId const; templ:string; callback:lambda<(id:EntityId):void>; subexpr:block<(var compInit:ComponentsInitializer):void> ):EntityId
  return _builtin_recreate_entity_lambda(eid, templ, callback, subexpr)
[generic]
def addSubTemplate ( eid:EntityId const; addname:string; subexpr:block<(var instAttrs:ComponentsInitializer):void>):bool
  return _builtin_add_sub_template(eid, addname, subexpr)
[generic]
def addSubTemplate ( eid:EntityId const; addname:string):bool
  return _builtin_add_sub_template(eid, addname) <| $ [unused_argument(init)](var init:Object) {}
[generic]
def removeSubTemplate ( eid:EntityId const; removename:string; subexpr:block<(var instAttrs:ComponentsInitializer):void>):bool
  return _builtin_remove_sub_template(eid, removename, subexpr)
[generic]
def removeSubTemplate ( eid:EntityId const; removename:string):bool
  return _builtin_remove_sub_template(eid, removename) <| $ [unused_argument(init)](var init:Object) {}
[generic]
def sendEvent ( eid:EntityId const; var evt)
  concept_assert(typeinfo(struct_has_annotation<cpp_event> evt) || typeinfo(struct_has_annotation<event> evt), "Event type should be struct with event or cpp_event annotations, and it is not <{typename(evt)}>")
  if (typeinfo(struct_has_annotation<cpp_event> evt) || typeinfo(struct_has_annotation<event> evt))
    let evt_name = typeinfo(struct_has_annotation<cpp_event> evt) ? typeinfo(undecorated_typename evt) : typeinfo(typename evt)
    evt.eventType = ecs_hash(evt_name)
    evt.eventSize = uint16(typeinfo(sizeof evt))
    evt.eventFlags = uint16(0)//should not be needed
    if !typeinfo(is_raw evt)
      _builtin_event_strdup(evt)
      evt.eventFlags = uint16(ecs::EVFLG_DESTROY)
    _builtin_send_blobevent(eid, evt, evt_name)

[generic]
def send_schemeless_event ( eid:EntityId const; name : string)
  send_schemeless_event(eid, name) <| $ [unused_argument(init)](var init: Object) {}

[generic]
def broadcast_schemeless_event ( eid:EntityId const; name : string)
  broadcast_schemeless_event(eid, name) <| $ [unused_argument(init)](var init: Object) {}

[generic]
def sendEventImmediate ( eid:EntityId const; var evt)
  concept_assert(typeinfo(struct_has_annotation<cpp_event> evt) || typeinfo(struct_has_annotation<event> evt), "Event type should be struct with event or cpp_event annotations, and it is not <{typename(evt)}>")
  if (typeinfo(struct_has_annotation<cpp_event> evt) || typeinfo(struct_has_annotation<event> evt))
    let evt_name = typeinfo(struct_has_annotation<cpp_event> evt) ? typeinfo(undecorated_typename evt) : typeinfo(typename evt)
    evt.eventType = ecs_hash(evt_name)
    evt.eventSize = uint16(typeinfo(sizeof evt))
    evt.eventFlags = uint16(0)//should not be needed
    if !typeinfo(is_raw evt)
      _builtin_event_strdup(evt)
      evt.eventFlags = uint16(ecs::EVFLG_DESTROY)
    _builtin_send_blobevent_immediate(eid, evt, evt_name)

[generic]
def broadcastEvent (var evt)
  concept_assert(typeinfo(struct_has_annotation<cpp_event> evt) || typeinfo(struct_has_annotation<event> evt), "Event type should be struct with event or cpp_event annotations, and it is not <{typename(evt)}>")
  if (typeinfo(struct_has_annotation<cpp_event> evt) || typeinfo(struct_has_annotation<event> evt))
    let evt_name = typeinfo(struct_has_annotation<cpp_event> evt) ? typeinfo(undecorated_typename evt) : typeinfo(typename evt)
    evt.eventType = ecs_hash(evt_name)
    evt.eventSize = uint16(typeinfo(sizeof evt))
    evt.eventFlags = uint16(0)//should not be needed
    if !typeinfo(is_raw evt)
      _builtin_event_strdup(evt)
      evt.eventFlags = uint16(ecs::EVFLG_DESTROY)
    _builtin_broadcast_blobevent(evt, evt_name)

[generic]
def new_ecs_array(blk:block<(var arr:Array):void>)
  var arr:Array? = new Array
  invoke(blk, *arr)
  unsafe
    delete arr

[generic]
def new_ecs_object(blk:block<(var obj:Object):void>)
  var obj:Object? = new Object
  invoke(blk, *obj)
  unsafe
    delete obj

[generic]
def new_eid_list(blk:block<(var list:EidList):void>)
  var list:EidList? = new EidList
  invoke(blk, *list)
  unsafe
    delete list

[generic]
def new_int_list(blk:block<(var list:IntList):void>)
  var list:IntList? = new IntList
  invoke(blk, *list)
  unsafe
    delete list

[generic]
def new_bool_list(blk:block<(var list:BoolList):void>)
  var list:BoolList? = new BoolList
  invoke(blk, *list)
  unsafe
    delete list

[generic]
def new_string_list(blk:block<(var list:StringList):void>)
  var list:StringList? = new StringList
  invoke(blk, *list)
  unsafe
    delete list

[generic]//can't be generic yet
def push_object_to_array(var ecs_array:Array; b:block<(var obj:Object):void>)
  var obj:Object? = new Object
  invoke(b, deref(obj))
  push_back(ecs_array, deref(obj))
  unsafe
    delete obj

[generic]//can't be generic yet
def push_object_to_array(var ecs_array:Array)
  var obj:Object? = new Object
  push_back(ecs_array, deref(obj))
  unsafe
    delete obj

[generic]//can't be generic yet
def push_object_to_object(var main_obj:Object; name : string; b:block<(var obj:Object):void>)
  var obj:Object? = new Object
  invoke(b, deref(obj))
  set(main_obj, name, deref(obj))
  unsafe
    delete obj

[generic]//can't be generic yet
def push_array_to_object(var main_obj:Object; name : string; b:block<(var obj:Array):void>)
  var arr:Array? = new Array
  invoke(b, deref(arr))
  set(main_obj, name, deref(arr))
  unsafe
    delete arr

[generic]//can't be generic yet
def push_array_to_object(var main_obj:Object; name : string)
  var arr:Array? = new Array
  set(main_obj, name, deref(arr))
  unsafe
    delete arr

[generic]
def getEventName ( evt:auto(no_const) )
  if typeinfo(safe_has_field<eventName> evt) // typeinfo(typename type no_const -const) == typeinfo(typename type Event) also works
    return evt.eventName
  elif typeinfo(safe_has_field<eventType> evt)
    return get_event_name_from_type(evt.eventType)
  else
    return ""
