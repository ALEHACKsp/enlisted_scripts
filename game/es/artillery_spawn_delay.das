require ecs
require app
require math

[es (tag=server, on_event=CmdSpawnSquad)]
def artillery_cooldown_on_spawn(evt: Event;
                                artillery_dot_spawnDelay: float;
                                var artillery_dot_availableAtTime: float&)
  artillery_dot_availableAtTime = max(artillery_dot_availableAtTime, get_sync_time() + artillery_dot_spawnDelay)