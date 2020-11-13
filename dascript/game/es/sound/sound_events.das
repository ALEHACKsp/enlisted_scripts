options remove_unused_symbols = false
module sound_events
require ecs

[cpp_event]
struct CmdPlayNetSound
  hash:uint
  pos:float3
  param:float
  interval:float
  time:float

[cpp_event]
struct CmdPlayNetSoundExceptHero
  hash:uint
  pos:float3
  param:float
  interval:float
  time:float

[cpp_event]
struct CmdPlaySound
  hash:uint
  pos:float3
  param:float
  interval:float

[event(broadcast)]
struct CmdPlayCommonSound
  hash:uint
  pos:float3
  isWatched:bool

[cpp_event]
struct CmdPlayCommonNetSound
  hash:uint
  pos:float3
  time:float

[cpp_event(broadcast)]
struct EventOnSoundGameToggle
  hash:uint
  isValid:bool

[cpp_event]
struct CmdHumanPlayerSpeech
  phraseId:int
  time:float

[cpp_event]
struct CmdHumanTeamSpeech
  phraseId:int
  time:float

[cpp_event]
struct CmdHumanSpeech
  phraseId:int
  time:float

[cpp_event]
struct CmdHeroSpeech
  phrase:string

[cpp_event]
struct CmdRequestHumanSpeech
  phrase:uint
  threshold:float

[cpp_event]
struct CmdPlayLootSoundForEnemy
  hash:uint
  time:float

[cpp_event]
struct CmdPlayLootSound
  hash:uint
  time:float

[cpp_event]
struct CmdVehicleSoundHorn
  enable:bool
  end:float

[cpp_event(broadcast)]
struct EventOnGunSound
  pos : float3
  vel : float3

[cpp_event]
struct CmdPlayMinionSound
  eid : ecs::EntityId
  time : float

[cpp_event]
struct CmdSoundMeleeIrq
  irq : int
