require ecs
require net

[generic]
def remote_recreate_entity_from (eid:EntityId const; templ:string)
  _builtin_remote_recreate_entity_from(eid, templ)

[generic]
def remote_recreate_entity_from (eid:EntityId const; templ:string; subexpr:block<(var compInit:ComponentsInitializer):void> )
  _builtin_remote_recreate_entity_from_block(eid, templ, subexpr)

[generic]
def server_send_schemeless_event (eid:EntityId const; evt_name:string const)
  server_send_schemeless_event(eid, evt_name) <| $ [unused_argument(init)](var init:Object) {}

[generic]
def server_send_schemeless_event (eid:EntityId const; evt_name:string const; to_whom:EntityId const)
  server_send_schemeless_event(eid, evt_name, to_whom) <| $ [unused_argument(init)](var init:Object) {}

[generic]
def server_broadcast_schemeless_event (evt_name:string const)
  server_broadcast_schemeless_event(evt_name) <| $ [unused_argument(init)](var init:Object) {}

[generic]
def server_broadcast_schemeless_event (evt_name:string const; to_whom:EntityId const)
  server_broadcast_schemeless_event(evt_name, to_whom) <| $ [unused_argument(init)](var init:Object) {}

[generic]
def client_send_schemeless_event (eid:EntityId const; evt_name:string const)
  client_send_schemeless_event(eid, evt_name) <| $ [unused_argument(init)](var init:Object) {}

[generic]
def client_send_schemeless_event (evt_name:string const)
  client_send_schemeless_event(evt_name) <| $ [unused_argument(init)](var init:Object) {}
