require ecs

[es (tag=server, track=vehicle_seats_dot_restrictToTeam, on_event=(EventEntityCreated,EventComponentsAppear))]
def autodetect_team(evt: Event;
                    vehicle_seats_dot_restrictToTeam : int;
                    vehicle_seats_dot_autoDetectRestrictToTeam : bool;
                    var team : int&)
  if !vehicle_seats_dot_autoDetectRestrictToTeam
    return
  team = vehicle_seats_dot_restrictToTeam
