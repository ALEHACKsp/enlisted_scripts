options remove_unused_symbols = false
module enlisted_events
require ecs
require EnlistedWalkerai

[cpp_event]
struct RequestSquadOrder
  orderType : SquadOrder
  orderPosition : float3
  orderUseEntity : ecs::EntityId

[cpp_event]
struct RequestSquadMateOrder
  orderType : SquadMateOrder
  orderPosition : float3
  orderUseEntity : ecs::EntityId

[cpp_event]
struct RequestPersistentSquadOrder
  orderType : PersistentSquadOrder
  orderPosition : float3
  orderUseEntity : ecs::EntityId

[cpp_event]
struct RequestArtilleryOverOrder
  active : bool
  targetPos : float3

[cpp_event]
struct RqContextCommand{}

[cpp_event]
struct RqCancelContextCommand
  include_personal_orders : bool

[cpp_event(unicast)]
struct CmdShowArtilleryCooldownHint
  data : ecs::Object

[cpp_event(unicast)]
struct CmdOpenArtilleryMap
  data : ecs::Object

[cpp_event(unicast)]
struct EventArtilleryMapPosSelected
  data : Object // pos : float3

[cpp_event(unicast)]
struct CmdCloseArtilleryMap
  data : ecs::Object

[cpp_event]
struct EventTeamMemberJoined
  eid : ecs::EntityId
  team : int

[cpp_event]
struct EventTeamMemberLeave
  eid : ecs::EntityId
  team : int

[cpp_event(unicast)]
struct CmdSelectBuildingType
  data : ecs::Object // index : int

[event(unicast)]
struct EventTryBuildFortification {}

[event(unicast)]
struct EventRecreateBuildPreview {}

[event(unicast)]
struct EventRecreateBuildIcons {}

[event(unicast)]
struct EventApplyCustomAnimcharVars {}

[cpp_event]
struct CmdBuildFortification
  builderGunEid: ecs::EntityId
  tm: float3x4
  boxMin: float3
  boxMax: float3

[cpp_event]
struct EventSetBuildingTarget
  target: EntityId

[cpp_event]
struct EventDismantleBuilding
  target: EntityId

[cpp_event]
struct CmdDetachAttachedGun {}

[cpp_event(unicast)]
struct CmdCreateRespawner
  data : ecs::Object

[cpp_event]
struct CmdWallposterPreview
  enable: bool
  wallPosterId : int

[cpp_event]
struct CmdWallposterPlace {}

[cpp_event]
struct WallposterRequestPlace
  wallPosterId : int
  wallPostersCurCount : int
  tm: float3x4
  bmin: float3
  bmax: float3
