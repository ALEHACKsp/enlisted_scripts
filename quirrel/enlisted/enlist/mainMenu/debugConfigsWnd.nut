local { openDebugWnd } = require("enlist/components/debugWnd.nut")
local {configs} = require("enlisted/enlist/configs/configs.nut")

local overrides = {
  items_templates = { recursionLevel = 1 }
  perks = { recursionLevel = 1 }
  researches = { recursionLevel = 5 }
  squads_config = { recursionLevel = 1 }
}

local getTabs = @() configs.value
  .map(@(_, name) { id = name, data = ::Computed(@() configs.value?[name] ?? {}) }.__merge(overrides?[name] ?? {}))
  .values()
  .sort(@(a, b) a.id <=> b.id)

return @() openDebugWnd({
  wndUid = "debug_configs_wnd"
  tabs = getTabs()
})
 