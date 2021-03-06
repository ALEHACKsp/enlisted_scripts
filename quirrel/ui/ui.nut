#default:no-func-decl-sugar
#default:no-class-decl-sugar

require("daRg/library.nut")
require("ui/enlisted-lib.nut")

::VM_NAME <- "ui"

local registerScriptProfiler = require("utils/regScriptProfiler.nut")

::ecs.clear_vm_entity_systems()

local {sound_set_volume, sound_play} = require_optional("sound")
local {get_game_name} = require("app")

console.register_command(function(name) {sound_play(name)}, "sound.play")
foreach (opt in ["MASTER","ambient","weapon","effects","voices","interface","music"]) {
  local capOpt = opt
  console.register_command(function(val) {sound_set_volume(capOpt, val)}, $"sound.set_volume_{opt}")
}
console.register_command(function(val) {sound_set_volume("MASTER", val)}, "sound.set_volume")

local inspector = require("daRg/components/inspector.nut")

console.register_command(@() inspector.shown.update(!inspector.shown.value), "ui.inspector_battle")
console.register_command(@() ::dump_observables(), "script.dump_observables")

registerScriptProfiler("hud")

/*
// cursorPresent watch example
::gui_scene.cursorPresent.subscribe(function(new_val) {
  ::vlog("cursorPresent -> "+new_val)
})
*/

local {DBGLEVEL} = require("dagor.system")
local {logerr} = require("dagor.debug")
local {scan_folder} = require("dagor.fs")
local use_realfs = (DBGLEVEL > 0) ? true : false
local files = scan_folder({root="ui/es", vromfs = true, realfs = use_realfs, recursive = true, files_suffix=".nut"})
files.extend(scan_folder({root="{0}/ui/es".subst(get_game_name()), vromfs = true, realfs = use_realfs, recursive = true, files_suffix=".nut"}))
foreach(i in files) {
  try {
    require(i)
  } catch (e) {
    logerr("UI module {0} was not loaded - see log for details".subst(i))
  }
}


local root = require("root.nut")

return root
 