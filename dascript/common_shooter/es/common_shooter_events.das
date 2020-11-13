options remove_unused_symbols = false
module common_shooter_events
require ecs
module common_shooter_events;

[cpp_event]
struct CmdOpenMapForMortar {}

[cpp_event]
struct EventMortarMapClosed
  active : bool
  targetPos : float3

[cpp_event]
struct CmdStartMortarStrikeAtPos
  pos: float3