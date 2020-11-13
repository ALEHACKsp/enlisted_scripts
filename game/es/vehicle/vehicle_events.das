options remove_unused_symbols = false
module vehicle_events
require ecs
require dm
require DagorMath

[cpp_event]
struct EventOnPartDamageEffects
  offender: ecs::EntityId
  partId: int
  effects: int

[cpp_event]
struct EventOnPartKillEffects
  offender: ecs::EntityId
  partId: int
  effects: int

[cpp_event(unicast)]
struct EventOnPartDamaged
  partId: int
  damageTypeId: int
  damageEffectsMask: int
  damage: float
  hpFixed: uint16
  prevHpFixed: uint16
  state: int
  hitData: HitData

[cpp_event]
struct CmdVolumetricDamage
  offender: ecs::EntityId
  sph : BSphere3
  damage : float
  isDamageRel : bool
  damageTypeId : int
  damageEffectsMask: int
  seed : int

[cpp_event(unicast)]
struct EventOnVolumetricDamage
  offender: ecs::EntityId
  damageTypeId: int
  damageEffectsMask: int
  damagedParts: ecs::Array

[cpp_event]
struct EventOnMetaPartDamage
  offender: ecs::EntityId
  metaPartId: int
  damage: float
  hp: float
  maxHp: float

[cpp_event]
struct CmdUseVehiceOnSpawn
  possessed: ecs::EntityId
  squad: ecs::EntityId
  vehicle: ecs::EntityId
  seatOrderNo: int

[cpp_event]
struct CmdVehicleSwapSeats
  seatNo1 : int
  seatNo2 : int

[cpp_event]
struct EventExplosionFatal
  offender: ecs::EntityId

[cpp_event]
struct EventFireFatal
  offender: ecs::EntityId

[cpp_event]
struct EventCrashExplosionFatal
  offender: ecs::EntityId

[cpp_event]
struct EventEnterVehicle
  incomer : ecs::EntityId
  vehicle : ecs::EntityId
  enter : bool

[cpp_event]
struct CmdActivateExtinguisher
  eid: EntityId

[cpp_event]
struct CmdStopExtinguisher
  eid: EntityId

[cpp_event]
struct CmdKickFromVehicle
  eid: EntityId

[cpp_event(unicast)]
struct CmdStopBurn {}

[cpp_event]
struct RequestStartMaintenance
  target: EntityId

[cpp_event]
struct RequestStopMaintenance
  target: EntityId

[cpp_event]
struct CmdStartMaintenance
  target: EntityId

[cpp_event]
struct CmdStopMaintenance
  target: EntityId

[cpp_event]
struct CmdStartRepair
  target: EntityId

[cpp_event]
struct CmdStopRepair
  target: EntityId

[cpp_event]
struct CmdVehicleHornRequest
  enable: bool

[cpp_event]
struct RequestVehicleChangeSeat
  eid: EntityId
  seat: int

[cpp_event]
struct CmdVehicleChangeSeat
  eid: EntityId
  seat: int

[cpp_event]
struct EventOnStartVehicleChangeSeat
  eid: EntityId
  seat: int

[cpp_event]
struct CmdVehiclePlaceSeat
  eid: EntityId
  seat: int

[cpp_event]
struct CmdVehiclePlaceDriverSeat
  eid: EntityId

[cpp_event]
struct CmdVehiclePlaceNextSeat
  eid: EntityId

[cpp_event]
struct CmdSwitchSquadLeader
  eid: EntityId

[cpp_event]
struct RequestSquadChangeLeader
  eid: EntityId

[cpp_event]
struct CmdSetVehicleShootDir
  dir: float3

[cpp_event]
struct CmdSetGunnerCockpitRequest
  isGunner: bool
