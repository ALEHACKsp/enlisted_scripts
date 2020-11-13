require DagorConsole
require DagorMath public

[generic]
def visual_log(msg : string; color : E3DCOLOR = E3DCOLOR(0xffffffff); level : int = 0)
  _builtin_visual_log(msg, color, level)
