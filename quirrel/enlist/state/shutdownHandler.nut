local app = require_optional("enlist.app")

local list = []

local function onShutdown() {
  foreach(func in list)
    func()
}

if (app)
  app.set_app_shutdown_handler(onShutdown)

return {
  add = @(func) list.append(func)
  remove = function(func) {
    local idx = list.indexof(func)
    if (idx != null)
      list.remove(idx)
  }
} 