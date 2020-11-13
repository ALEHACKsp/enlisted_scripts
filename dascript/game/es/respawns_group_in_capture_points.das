require ecs
require game.utils.team

def set_respawns_group_on_point_active(group, respawnTeam)
  ecs::query() <| $[es](var active : bool&; respawnBaseGroup : int; team : int)
    if respawnBaseGroup == group
      active = team == respawnTeam

[es (tag=server, track=capzone_dot_progress, track=capzone_dot_capTeam, track=active)]
def activate_respawn_on_point_es(evt : Event;
                                 active : bool;
                                 capzone_dot_capTeam: int;
                                 capzone_dot_progress: float;
                                 capzone_dot_activateRespawnOnProgress : float;
                                 capzone_dot_acivateRespawnGroup : int)
  let enoughProgress = capzone_dot_progress >= capzone_dot_activateRespawnOnProgress
  let respawnForTeam = (active && enoughProgress) ? capzone_dot_capTeam : TEAM_UNASSIGNED
  set_respawns_group_on_point_active(capzone_dot_acivateRespawnGroup, respawnForTeam)