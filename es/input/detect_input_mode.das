require ecs
require DagorInput
require game.es.input.input_common

let
  PAST_FRAMES_THRESHOLD   = 100u

[es (tag=input, no_order)]
def detect_input_mode(info: UpdateStageInfoAct; var glob_input_dot_inputMode: int&)
  let mask = get_last_used_device_mask(PAST_FRAMES_THRESHOLD)
  if mask == 0u
    return

  if (mask & (DEV_USED_mouse | DEV_USED_kbd)) != 0u
    glob_input_dot_inputMode = int(InputMode MODE_KEYBOARD_AND_MOUSE)
  elif (mask & DEV_USED_gamepad) != 0u
    glob_input_dot_inputMode = int(InputMode MODE_GAMEPAD)
  else
    glob_input_dot_inputMode = int(InputMode MODE_UNKNOWN)