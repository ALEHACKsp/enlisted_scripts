require ecs
require app
require game.utils.hero
require soundEvent
require soundHash
require soundSystem
require game.es.sound.sound_events

def get_net_sound_desc(hash:uint; descs:Object) : Object const?
  for it in descs
    if sound_hash(it.key) == hash
      return get_ecs_object(it.value)
  soundSystem::debug("net_sound: hash '{hash}' not found in net_sound.descs")
  soundSystem::debug("list of descs:")
  for it in descs
    soundSystem::debug("  {it.key}({sound_hash(it.key)})")
  return null

def play_impl(hash:uint; pos:float3; param:float; interval:float; descs:Object; is_watched:bool)
  let objRef = get_net_sound_desc(hash, descs)
  if objRef != null
    var obj:Object const& = deref(objRef)
    let nameRef = is_watched ? (has(obj, "hero") ? obj["hero"] : obj["event"]) : (has(obj, "enemy") ? obj["enemy"] : obj["event"])
    if nameRef != null
      let name = string(deref(get_ecs_string(deref(nameRef))))
      var handle:int = soundEvent::init(name, "")
      soundEvent::set_pos(handle, pos)
      if has(obj, "var")
        soundEvent::set_var(handle, string(deref(get_ecs_string(deref(obj["var"])))), param)
      soundEvent::start(handle)
      soundEvent::abandon(handle, interval)


[es (tag=sound)]
def play_net_sound_event_handler_es(cmd : CmdPlayNetSound; eid:ecs::EntityId; net_sound_dot_descs:Object)
  if get_sync_time() < cmd.time + 5.0
    play_impl(cmd.hash, cmd.pos, cmd.param, cmd.interval, net_sound_dot_descs, eid==get_controlled_hero())

[es (tag=sound)]
def play_net_sound_except_hero_event_handler_es(cmd : CmdPlayNetSoundExceptHero; eid:ecs::EntityId; net_sound_dot_descs:Object)
  if get_sync_time() < cmd.time + 5.0
    if eid==get_controlled_hero()
      soundSystem::debug("warning: CmdPlayNetSoundExceptHero is played by hero")
    play_impl(cmd.hash, cmd.pos, cmd.param, cmd.interval, net_sound_dot_descs, false)

[es (tag=sound)]
def client_sound_event_handler_es(cmd : CmdPlaySound; eid:ecs::EntityId; net_sound_dot_descs:Object)
  play_impl(cmd.hash, cmd.pos, cmd.param, cmd.interval, net_sound_dot_descs, eid==get_controlled_hero())

[es (tag=sound, REQUIRE=commonNetSounds)]
def common_sound_event_handler_es(cmd : CmdPlayCommonSound; net_sound_dot_descs:Object)
  play_impl(cmd.hash, cmd.pos, 0., 0., net_sound_dot_descs, cmd.isWatched)

[es (tag=sound, REQUIRE=commonNetSounds)]
def common_net_sound_event_handler_es(cmd : CmdPlayCommonNetSound; net_sound_dot_descs:Object)
  play_impl(cmd.hash, cmd.pos, 0., 0., net_sound_dot_descs, false)
