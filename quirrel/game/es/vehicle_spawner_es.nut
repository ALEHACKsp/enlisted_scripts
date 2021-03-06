local { TEAM_UNASSIGNED } = require("team")
local { TMatrix } = require("dagor.math")
local { EventLevelLoaded } = require("gameevents")

local function spawnItem(evt, eid, comp) {
  local tm = TMatrix(comp.transform)
  foreach (item in comp.spawnItemList) {
    local count = item.count.tointeger()
    for (local i = 0; i < count; ++i) {
      ::ecs.g_entity_mgr.createEntity(item.templ, { transform = tm, team = comp.team })
      tm.setcol(3, tm.getcol(3) + comp.spawnItemStep)
    }
  }
}

::ecs.register_es("item_spawner_es",
  {
    [EventLevelLoaded] = spawnItem,
  },
  {
    comps_ro = [
      ["transform", ::ecs.TYPE_MATRIX],
      ["spawnItemList", ::ecs.TYPE_ARRAY],
      ["spawnItemStep", ::ecs.TYPE_POINT3],
      ["team", ::ecs.TYPE_INT, TEAM_UNASSIGNED]
    ]
  },
  {tags = "server"}) 