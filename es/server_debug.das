options remove_unused_symbols = false
module server_debug
require ecs
require net
require DagorConsole
require game.es.events

def exec_server_cmd(message : string)
  client_broadcast_schemeless_event(typeinfo(undecorated_typename type<CmdChatMessage>)) <| $ (var init: Object)
    set(init, "mode", "team")
    set(init, "text", "/servercmd {message}")

[console_cmd(name="server.cmd")]
def do_server_cmd(cmd : string; arg1 : string = ""; arg2 : string = ""; arg3 : string = ""; arg4 : string = ""; arg5 : string = ""; arg6 : string = ""; arg7 : string = "")
  let message = "{cmd} {arg1} {arg2} {arg3} {arg4} {arg5} {arg6} {arg7}"
  exec_server_cmd(message)

