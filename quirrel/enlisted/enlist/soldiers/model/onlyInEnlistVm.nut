return function(modelId) {
  if (require_optional("onlineStorage") != null)
    return

  local { logerr, debug_dump_stack } = require("dagor.debug")
  logerr($"Loaded enlist model in UI VM. ({modelId})")
  debug_dump_stack()
} 