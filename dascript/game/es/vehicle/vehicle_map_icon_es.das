require vehicle
require ecs
require app
require game.utils.hero
require game.utils.team

let
  MARKER_EMPTY_VEHICLE = 0
  MARKER_FRIENDLY_VEHICLE = 1
  MARKER_SQUAD_VEHICLE = 2
  MARKER_CONTROLLED_VEHICLE = 3
  MARKER_TYPES = [[string[] ""; "friendlyTank"; "squadTank"; "controlledTank"]]

def set_marker_type(var hud_marker_dot_type: das_string; markerType: string)
//  if hud_marker_dot_type != markerType
  hud_marker_dot_type := markerType
  return

def select_marker_type(is_alive : bool; team: int; vehicle_seats_owners: VehicleSeatsOwners):string
  if !is_alive
    return ""

  let hero = get_controlled_hero()
  if hero == INVALID_ENTITY_ID
    return "emptyTank"

  let heroTeam = get_int(hero, "team") ?? TEAM_UNASSIGNED
  let heroSquad = get_Eid(hero, "squad_member.squad") ?? INVALID_ENTITY_ID

  var markerType = MARKER_EMPTY_VEHICLE

  for owner in vehicle_seats_owners.data
    if owner.eid == INVALID_ENTITY_ID || !(get_bool(owner.eid, "isAlive") ?? true)
      continue

    if owner.eid == hero
      markerType = MARKER_CONTROLLED_VEHICLE
      break

    if owner.squad != INVALID_ENTITY_ID && owner.squad == heroSquad
      markerType = max(markerType, MARKER_SQUAD_VEHICLE)

    if is_teams_friendly(team, heroTeam)
      markerType = max(markerType, MARKER_FRIENDLY_VEHICLE)

  return MARKER_TYPES[markerType]


[es (tag=gameClient, on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=vehicle)]
def init_vehicle_map_icon_es(evt: Event; team: int; isAlive : bool;
                             vehicle_seats_owners: VehicleSeatsOwners; var hud_marker_dot_type: das_string)
  set_marker_type(hud_marker_dot_type, select_marker_type(isAlive, team, vehicle_seats_owners))

[es (tag=gameClient, track=vehicle_seats_owners, REQUIRE=vehicle)]
def vehicle_map_icon_es(evt: Event; team: int; isAlive: bool;
                        vehicle_seats_owners: VehicleSeatsOwners; var hud_marker_dot_type: das_string)
  set_marker_type(hud_marker_dot_type, select_marker_type(isAlive, team, vehicle_seats_owners))

[es (tag=gameClient, on_event=EventEntityDied, track=isAlive, REQUIRE=vehicle)]
def vehicle_map_icon_vehicle_destroyed_es(evt: Event; isAlive: bool; var hud_marker_dot_type: das_string)
  if !isAlive
    set_marker_type(hud_marker_dot_type, "")
