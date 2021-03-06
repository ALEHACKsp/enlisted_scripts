local {get_action_bindings_text} = require("dainput2")
local {isGamepad} = require("ui/control/active_controls.nut")


local function controlText(params){
  local id = (typeof params == "string") ? params : params.id

  local texts = get_action_bindings_text(id)
  if (isGamepad.value) {
    if (texts[1])
      return texts[1]
  } else {
    if (texts[0])
      return texts[0]
  }

  foreach (t in texts) {
    if (t)
      return t
  }

  return "--"
}

return controlText
 