require ecs
require app
require soundHash
require game.es.events
require game.es.sound.sound_events

[es (tag=server)]
def shell_explode_net_sound(evt : CmdShellExplode;
                            shell_explode_sound_dot_sound : string)
  broadcastEvent([[CmdPlayCommonNetSound hash=sound_hash(shell_explode_sound_dot_sound), pos=evt.position, time=get_sync_time()]])
