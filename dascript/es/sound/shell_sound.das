require ecs
require soundEvent
require soundSystem
require AnimV20

[es (tag=sound, after=animchar_render_es)]
def shell_fly_sound_es(info:UpdateStageInfoAct;
                       active : bool;
                       shell_fly_sound_dot_sound : string;
                       var shell_fly_sound_dot_handle : int&;
                       transform : float3x4)
  if active
    if shell_fly_sound_dot_handle == 0
      shell_fly_sound_dot_handle = soundEvent::init(shell_fly_sound_dot_sound, "")
      soundEvent::set_pos(shell_fly_sound_dot_handle, transform[3])
      soundEvent::start(shell_fly_sound_dot_handle)
    else
      soundEvent::set_pos(shell_fly_sound_dot_handle, transform[3])
  elif shell_fly_sound_dot_handle != 0
    soundEvent::abandon(shell_fly_sound_dot_handle)

[es (on_event=EventEntityDestroyed, tag=sound)]
def shell_fly_sound_destroy_es(evt:Event; var shell_fly_sound_dot_handle : int&)
  soundEvent::abandon(shell_fly_sound_dot_handle)

[es (tag=sound, on_event=(EventEntityCreated, EventComponentsAppear))]
def shell_throw_sound_es(evt : Event;
                         shell_throw_sound_dot_name:string;
                         shell_dot_owner : ecs::EntityId)
  ecs::query(shell_dot_owner) <| $ [es] (is_watched_sound : bool; animchar : AnimcharBaseComponent)
    let nodeIdx = animchar_find_node_index(animchar, "weapon_right")
    if nodeIdx >= 0
      let pos = animchar_get_node_wpos(animchar, nodeIdx)
      if is_watched_sound || soundEvent::should_play(pos)
        soundEvent::oneshot(is_watched_sound ? "player/{shell_throw_sound_dot_name}" : "enemy/{shell_throw_sound_dot_name}", "", pos)

[es (tag=sound, on_event=(EventEntityCreated, EventComponentsAppear))]
def shell_launch_sound_es(evt : Event;
                          shell_launch_sound_dot_name:string;
                          shell_dot_owner : ecs::EntityId;
                          transform : float3x4)
  ecs::query(shell_dot_owner) <| $ [es] (is_watched_sound : bool)
    if is_watched_sound || soundEvent::should_play(transform[3])
      soundEvent::oneshot(is_watched_sound ? "player/{shell_launch_sound_dot_name}" : "enemy/{shell_launch_sound_dot_name}", "", transform[3])
