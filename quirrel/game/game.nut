#default:no-func-decl-sugar
#default:no-class-decl-sugar
#default:no-root-fallback
                         
                      

::VM_NAME <- "game"

local {DBGLEVEL} = require("dagor.system")
local {logerr} = require("dagor.debug")
local {scan_folder} = require("dagor.fs")

::ecs.clear_vm_entity_systems()

::print("enlisted game scripts init started:")
local use_realfs = (DBGLEVEL > 0) ? true: false
local files = scan_folder({root="game/es", vromfs = true, realfs = use_realfs, recursive = true, files_suffix=".nut"})

local game_name = require("app").get_game_name()
files.extend(scan_folder({root="{0}/game/es".subst(game_name), vromfs = true, realfs = use_realfs, recursive = true, files_suffix=".nut"}))

foreach(i in files) {
  try {
    require(i)
  } catch (e) {
    logerr("Module {0} was not loaded - see log for details".subst(i))
  }
}

require_optional($"{game_name}/game/onGameScriptLoad.nut")

require("game/report_logerr.nut")

::print("enlisted game scripts init finished")
/*
local io = require("io")
::runf <- function(fn) {
  local f = io.file(fn, "rt")
  local s = f.readblob(f.len()).tostring()
  f.close()
  local script=compilestring(s)
  script()
}
*/ 