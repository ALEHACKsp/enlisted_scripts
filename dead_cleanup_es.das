require ecs
require game.es.events

[es (tag=server)]
def dead_cleanup_es(evt : EventEntityDied;
                    eid : EntityId;
                    bodyCleanupTime : float)
  sendEvent(eid, [[CmdBodyCleanup time=bodyCleanupTime]])