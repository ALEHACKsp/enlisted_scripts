options remove_unused_symbols = false
module events
require ecs
require dm
require net
require Gun
require DaWeapons
require DaWeaponProps
require DagorInput

[cpp_event(unicast)]
struct EventEntityCreated {}

[cpp_event(unicast)]
struct EventEntityRecreated {}

[cpp_event(unicast)]
struct EventEntityDestroyed {}

[cpp_event(unicast)]
struct EventComponentsDisappear {}

[cpp_event(unicast)]
struct EventComponentsAppear {}

[cpp_event]
struct EventFirstContact {}

[cpp_event]
struct CmdClearAllAttachedUserPoint
  target: ecs::EntityId
  team: int

[cpp_event]
struct EventHeroChanged
  eid : ecs::EntityId

[cpp_event]
struct EventOnDownedThreshold {}

[cpp_event]
struct EventAnyEntityDowned
  victim : EntityId
  offender : EntityId

[cpp_event]
struct CmdPossessEntity
  possessedEid : EntityId

[cpp_event]
struct CmdTeleportEntity
  newTm : float3x4
  hard: bool

[cpp_event]
struct CmdSetCameraTarget
  target : EntityId

[cpp_event]
struct CmdSwitchCamera {}

[event(unicast)]
struct EventLutSwitcherAliveState {}

[cpp_event]
struct EventOnVehicleDamageEffects
  offender: EntityId
  vehicle: EntityId
  effects: int

[cpp_event]
struct CmdShowVehicleDamageEffectsHint
  offender: EntityId
  vehicle: EntityId
  effects: int

[cpp_event]
struct EventOnVehicleDamaged
  offender: EntityId
  vehicle: EntityId
  damage: float
  hp: float
  maxHp: float

[cpp_event]
struct EventRiExtraDestroyed
  offenderEid : ecs::EntityId

[cpp_event]
struct CmdCollisionDamage
  damage : float
  pos : float3
  offender : ecs::EntityId

[cpp_event]
struct CmdRendinstDamage
  handle : uint
  damage : float
  pos : float3
  impulse : float3
  time : float

[cpp_event]
struct RequestRendinstDamage
  handle : uint
  damage : float
  pos : float3
  impulse : float3
  time : float

[cpp_event]
struct RequestRendinstEntityDamage
  eid : EntityId
  damage : float
  pos : float3
  impulse : float3
  time : float

[cpp_event]
struct EventOnLootPickup
  itemEid:ecs::EntityId

[cpp_event]
struct CmdInventoryPickup
  itemEid:ecs::EntityId
  usefulOnly: bool

[cpp_event]
struct EventOnLootDrop
  itemEid:ecs::EntityId

[cpp_event]
struct EventOnLootUse
  itemEid:ecs::EntityId

[cpp_event]
struct EventPlayerOnLootUse
  entityToUse : EntityId

[cpp_event]
struct EventOnEntityHit
  victim: ecs::EntityId
  offender: ecs::EntityId
  damageDesc: dm::DamageDesc
  hitResult: uint8

[cpp_event(unicast)]
struct EventOnProjectileHit
  hitPos : float3
  norm : float3
  shellId : int
  physMatId : int
  collNodeId : int

[cpp_event(unicast)]
struct EventOnHitByProjectile
  localHitPos : float3
  localNormal : float3
  caliber : float
  bulletTypeId : int
  nodeId : int
  pierced : bool

[cpp_event(unicast)]
struct EventOnRicochet
  localHitPos : float3
  caliber : float

[cpp_event]
struct EventPlayerInjuredEntity
  victim: ecs::EntityId
  offender: ecs::EntityId
  damageDesc: dm::DamageDesc
  victimPlrEid: ecs::EntityId
  offenderPlrEid: ecs::EntityId

[cpp_event]
struct EventZoneEnter
  visitorEid : EntityId

[cpp_event]
struct EventZoneLeave
  visitorEid : EntityId

[cpp_event(unicast)]
struct CmdHumanHitTagging
  powerMult : float

[cpp_event]
struct EventCapZoneEnter
  visitorEid : EntityId

[cpp_event]
struct EventCapZoneLeave
  visitorEid : EntityId

[cpp_event]
struct CmdWeapAttach
  toEid: EntityId
  isAttached: bool
  slotId: int

[cpp_event]
struct CmdUse
  requesterEid : EntityId

[cpp_event]
struct HumanUseObjectRequest
  objectEid : EntityId

[cpp_event]
struct CmdChangePlayerPerk
  perkName : string
  active : bool

[cpp_event]
struct CmdChangeAllPlayersPerk
  perkName : string
  active : bool

[event(unicast)]
struct CmdAddUserstats
  name : string
  change : int

[cpp_event]
struct CmdHeroLogEvent
  event : string
  text : string
  ttl : int

[cpp_event(unicast)]
struct CmdHeroLogExEvent
  data : ecs::Object

[event(unicast)]
struct CmdAddRegionstats
  region : string
  name : string
  change : int

[cpp_event]
struct CmdKill
  offender: EntityId
  damageType: uint16

[cpp_event]
struct CmdSetDeviceState
  enabled : bool

[cpp_event]
struct CmdStartArtilleryStrike
  owner: EntityId

[cpp_event]
struct CmdStartArtilleryStrikeAtPos
  owner: EntityId
  pos: float3

[cpp_event]
struct RequestArtilleryStrikeAtPos
  owner: EntityId
  pos: float3

[cpp_event]
struct EventEntityDied
  victim: EntityId
  offender: EntityId
  deathDesc: dm::DeathDesc

[cpp_event]
struct EventAnyEntityDied
  victim: EntityId
  offender: EntityId
  offenderSquad: EntityId
  victimSquad: EntityId
  offenderPlayer: EntityId
  victimPlayer: EntityId
  deathDesc: dm::DeathDesc

[cpp_event]
struct CmdMedkitUseCancel {}

[cpp_event]
struct CmdMedkitUse {}

[cpp_event]
struct EventOnClientDisconnected
  connid : int
  connerr : ConnErr

[cpp_event]
struct EventOnLootItemUsed
  target: ecs::EntityId

[cpp_event]
struct CmdPostPhysUpdate
  tick : int
  dt : float
  isForReal : bool

[cpp_event]
struct CmdWeapPhysUpdate
  owner : ecs::EntityId
  atTime : float
  dt : float
  isForReal : bool
  slotId : int
  gctrl : GunControls
  gloc : GunLocation

[cpp_event]
struct EventOnInstallWeapMod
  slotTag : string
  gunSlotId : int
  withSfx : bool

[cpp_event]
struct EventOnShellExploded
  explPos : float3
  shellId : ShellPropIds
  gunPropsId : int
  owner : ecs::EntityId
  prevPos : float3
  vel : float3

[cpp_event]
struct CmdShellExplode
  position : float3
  prevPos : float3
  vel : float3

[cpp_event]
struct CmdRequestReload
  atTime : float
  gunEid : ecs::EntityId

[cpp_event]
struct CmdSwitchCameraByEntity
  index : int
  camNamesEid : ecs::EntityId

[cpp_event]
struct CmdSwitchCameraByIndex
  index : int

[cpp_event]
struct CmdPutOutFireStart {}

[cpp_event]
struct CmdPutOutFireStop {}

[cpp_event]
struct CmdNextBuildingType {}

[cpp_event]
struct EventCutPart
  offender : ecs::EntityId
  partNo : int

[event(unicast)]
struct EventOnDeviceShoot {}

[cpp_event]
struct EventOnPlayerConnected
  wishTeam : int
  reconnected : bool
  canSpawnEntity : bool

[cpp_event(unicast)]
struct EventOnBorderBattleArea
  data : ecs::Object

[cpp_event(unicast)]
struct EventOnBorderOldBattleArea
  data : ecs::Object

[cpp_event(unicast)]
struct EventEntityAboutToDeactivate
  data : ecs::Object

[cpp_event]
struct EventTeamRoundResult
  team: int
  isWon: bool

[cpp_event]
struct CmdSpawnSquad
  team: int
  possessed: ecs::EntityId
  squadId: int
  memberId: int
  respawnGroupId: int

[cpp_event]
struct EventZoneCaptured
  zone: EntityId
  team: int

[cpp_event]
struct EventZoneIsAboutToBeCaptured
  zone: EntityId
  team: int

[cpp_event]
struct EventZoneDecaptured
  zone: EntityId
  team: int

[cpp_event]
struct CmdEquipItemDirect
  itemEid: ecs::EntityId
  slot: string
  allowReorderSlots: bool

[cpp_event]
struct CmdEquipItemEntity
  slot: string
  name: string

[cpp_event(unicast)]
struct EventEntityActivate
  data : ecs::Object

[cpp_event]
struct CmdInitPolyBattleAreas {}

[cpp_event]
struct EventOnCollision
  vel: float3
  pvel: float3
  pos: float3
  offender: EntityId
  cvel: float3
  dt: float
  damage: float

[cpp_event]
struct EventOnModsChanged {}

[cpp_event]
struct CmdBodyCleanup
  time : float

[cpp_event]
struct EventOnItemStartUse
  target : EntityId

[cpp_event(unicast)]
struct CmdChatMessage // {mode="team", text="", qmsg=null},
  data : Object

[cpp_event]
struct CmdRestoreEntityHp
  restoreHp : float

[cpp_event(unicast)]
struct CmdSetMarkMain // {plEid = 0}
  data : Object

[cpp_event]
struct CmdCreateMapUserPoint
  pos : float3
  item_name : string

[cpp_event]
struct EventPlayerKilledEntity
  victimEid : EntityId
  killerEid : EntityId
  deathDesc : DeathDesc
  victimPlayerEid : EntityId
  killerPlayerEid : EntityId

[cpp_event]
struct EventPlayerGotDamage
  victimEid : EntityId
  offenderEid : EntityId
  damageDesc : DamageDesc
  victimPlayerEid : EntityId
  offenderPlayerEid : EntityId

[cpp_event]
struct EventSomeSwarmBoidDied
  pos : float3

[cpp_event]
struct CmdPushPhys
  vel : float3
  push_immunity : float

[cpp_event]
struct CmdVehiclePushPhys
  energyScaledDir : float3
  arm : float3
  duration : float

[cpp_event]
struct CmdShipPushPhys
  energyScaledDir : float3
  arm : float3
  duration : float

[cpp_event]
struct CmdInventorySwitchGunMod
  item : EntityId

[cpp_event]
struct CmdGetUserstats {}

[cpp_event(unicast)]
struct CmdToggleDoor
  data : ecs::Object

[cpp_event]
struct CmdWeapModToggle
  slotId : int

[cpp_event]
struct CmdWeapModActivate
  slotId : int
  activate : bool

[cpp_event]
struct HumanRequestModActivate
  slotId : int
  activate : bool

[cpp_event]
struct EventOnGrenadeThrow
  gun_props_id : int

[cpp_event(broadcast)]
struct CmdRumble
  eventName: string

[cpp_event]
struct EventDaInputInit
  init : bool

[cpp_event]
struct EventDaInputActionTriggered
  action : action_handle_t
  duration_ms : uint16

[cpp_event]
struct EventDaInputActionTerminated
  action : action_handle_t
  duration_ms : uint16

[cpp_event(unicast)]
struct EventPlayerPlace
  team_id : int
  player_place : int
  total_places : int
  killer_player : ecs::EntityId