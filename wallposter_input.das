require ecs
require ecs.common
require DagorInput
require game.es.events
require enlisted.game.es.enlisted_events
require player

[private]
def initActions(var wallposter_input_dot_place, wallposter_input_dot_cancel : int&)
  wallposter_input_dot_place = int(get_action_handle("Wallposter.Place", TYPEGRP_DIGITAL))
  wallposter_input_dot_cancel = int(get_action_handle("Wallposter.Cancel", TYPEGRP_DIGITAL))

[private]
def resetActions(var wallposter_input_dot_place, wallposter_input_dot_cancel : int&)
  wallposter_input_dot_place = int(BAD_ACTION_HANDLE)
  wallposter_input_dot_cancel = int(BAD_ACTION_HANDLE)

[es(tag=input)]
def wallposter_input_setup_es(evt : EventDaInputInit; var wallposter_input_dot_place, wallposter_input_dot_cancel : int&)
  if evt.init
    initActions(wallposter_input_dot_place, wallposter_input_dot_cancel)
  else
    resetActions(wallposter_input_dot_place, wallposter_input_dot_cancel)

[es(tag=input, on_event=(EventComponentsAppear, EventEntityCreated))]
def wallposter_input_appear_es(evt : Event; var wallposter_input_dot_place, wallposter_input_dot_cancel : int&)
  initActions(wallposter_input_dot_place, wallposter_input_dot_cancel)

[es(tag=input, on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def wallposter_input_disappear_es(evt : Event; var wallposter_input_dot_place, wallposter_input_dot_cancel : int&)
  resetActions(wallposter_input_dot_place, wallposter_input_dot_cancel)

[es(tag=input)]
def wallposter_input_es(evt : EventDaInputActionTriggered;
                        input_dot_enabled : bool;
                        wallposter_input_dot_place, wallposter_input_dot_cancel : int)
  if !input_dot_enabled
    return
  let playerEid = get_local_player_eid()
  if int(evt.action) == wallposter_input_dot_place
    sendEvent(playerEid, [[CmdWallposterPlace]])
  elif int(evt.action) == wallposter_input_dot_cancel
    sendEvent(playerEid, [[CmdWallposterPreview enable=false, wallPosterId=0]])
