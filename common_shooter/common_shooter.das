options remove_unused_symbols = false
options no_aot = true//since this is merely loader
module common_shooter
require ecs
require app
require ECSGlobalTags

[init]
def load
  var ok = true
  ok = load_es("common_shooter/es/mortar/mortar.das") && ok
  ok = load_es("common_shooter/es/mortar/mortar_control.das") && ok
  ok = load_es("common_shooter/es/mortar/mortar_trajectory.das") && ok
  ok = load_es("common_shooter/es/mortar/mortar_icon.das") && ok
  ok = load_es("common_shooter/es/can_pickup_items.das") && ok

  if app::get_game_name() == "aot"
    assert(ok)
