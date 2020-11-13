options remove_unused_symbols = false
module input_common

require ecs
require game.es.events

enum InputMode
  MODE_UNKNOWN            = 0
  MODE_KEYBOARD_AND_MOUSE = 1
  MODE_GAMEPAD            = 2

def InputMode(v: int)
  for mode in each_enum(InputMode MODE_UNKNOWN)
    if int(mode) == v
      return mode
  return InputMode MODE_UNKNOWN

[generic]
def get_input_mode()
  var mode = InputMode MODE_UNKNOWN
  find_query() <| $[es](glob_input_dot_inputMode: int)
    mode = InputMode(glob_input_dot_inputMode)
    return true
  return mode

[generic]
def is_gamepad_input()
  return get_input_mode() == InputMode MODE_GAMEPAD

[generic]
def is_keyboard_and_mouse_input()
  return get_input_mode() == InputMode MODE_KEYBOARD_AND_MOUSE

[generic]
def do_rumble(event_name)
  if is_gamepad_input()
    broadcastEvent([[CmdRumble eventName=event_name]])