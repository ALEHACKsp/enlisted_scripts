options remove_unused_symbols = false
module team

let
  TEAM_UNASSIGNED = -1
  TEAM_SPECTATOR = 0

[generic]
def is_teams_friendly(lhs, rhs : int)
  return lhs == rhs && lhs != TEAM_UNASSIGNED && rhs != TEAM_UNASSIGNED
