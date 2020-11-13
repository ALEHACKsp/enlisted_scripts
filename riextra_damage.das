require ecs
require game.es.events
require RiDestr
require RendInst

def damage_ri_on_server(handle: uint; damage: float; pos: float3; impulse: float3; time: float; eid: ecs::EntityId)
  setOptional(get_ri_extra_eid(handle), "riOffender", eid)
  apply_damage_to_riextra(handle, damage, pos, impulse, time)

[es (tag=server)]
def riextra_request_damage_server_es(evt : RequestRendinstDamage; eid : ecs::EntityId)
  damage_ri_on_server(evt.handle, evt.damage, evt.pos, evt.impulse, evt.time, eid)

[es (tag=server)]
def riextra_ent_request_damage_server_es(evt : RequestRendinstEntityDamage; eid : ecs::EntityId)
  ecs::query(evt.eid) <| $ [es] (ri_extra : RiExtraComponent)
    damage_ri_on_server(uint(ri_extra.handle), evt.damage, evt.pos, evt.impulse, evt.time, eid)

[es (tag=server)]
def riextra_damage_server_es(evt : CmdRendinstDamage; eid : ecs::EntityId; possessedByPlr : ecs::EntityId)
  var isLocal = true
  ecs::query(possessedByPlr) <| $ [es] (is_local : bool)
    isLocal = is_local
  if isLocal
    damage_ri_on_server(evt.handle, evt.damage, evt.pos, evt.impulse, evt.time, eid)

// 'netClient' tag because we want true network client here, which sends request to server.
// otherwise we'll have double damage of same rendinst, one by this es, one by riextra_damage_server_es
[es (tag=netClient)]
def riextra_damage_client_es(evt : CmdRendinstDamage; eid : ecs::EntityId; possessedByPlr : ecs::EntityId)
  ecs::query(possessedByPlr) <| $ [es] (is_local : bool)
    if is_local
      var riExtraEid = get_ri_extra_eid(evt.handle)
      if riExtraEid != INVALID_ENTITY_ID
        sendEvent(eid, [[RequestRendinstEntityDamage eid=riExtraEid, damage=evt.damage, pos=evt.pos, impulse=evt.impulse, time=evt.time]])
      else
        sendEvent(eid, [[RequestRendinstDamage handle=evt.handle, damage=evt.damage, pos=evt.pos, impulse=evt.impulse, time=evt.time]])

