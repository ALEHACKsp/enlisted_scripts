local activateGroup = require("game/utils/activate_group.nut")
local selectRandom = require("game/utils/random_list_selection.nut")
local {EventLevelLoaded} = require("gameevents")

local initNextChoiceQuery = ::ecs.SqQuery("initNextChoiceQuery", {comps_rw = [ ["capzone.activateAfterCap", ::ecs.TYPE_STRING], ["capzone.alwaysShow", ::ecs.TYPE_BOOL], ["ui_order", ::ecs.TYPE_INT] ],
  comps_ro = [ ["groupName", ::ecs.TYPE_STRING], ["capzone.activateChoice", ::ecs.TYPE_OBJECT], ]
})
local function initNextChoice(groupName, ui_order) {
  local nextGroup = null
  initNextChoiceQuery.perform(function(eid, comp) {
      if (comp.groupName != groupName)
        return
      comp["capzone.alwaysShow"] = true
      nextGroup = selectRandom(comp["capzone.activateChoice"].getAll())
      comp["capzone.activateAfterCap"] = nextGroup ?? "" // empty string is what we activate by default. i.e. nothing.
      comp["ui_order"] = ui_order
    })
  if (nextGroup != null && nextGroup != groupName)
    return 1 + initNextChoice(nextGroup, ui_order + 1)
  return 1
}
local onInitChoiceQuery = ::ecs.SqQuery("onInitChoiceQuery", {comps_rw = [ ["team.score", ::ecs.TYPE_FLOAT], ["team.scoreCap", ::ecs.TYPE_FLOAT] ]})
local function onInitChoice(evt, eid, comp) {
  if (!comp["activator.enabled"])
    return
  local choice = comp["activator.activateChoice"]
  local initialGroup = selectRandom(choice.getAll())
  if (initialGroup != null) {
    activateGroup(initialGroup)
    local numChoice = initNextChoice(initialGroup, 0)
    local mult = comp["activator.initialLength"] > 0
                 ? numChoice.tofloat() / comp["activator.initialLength"].tofloat()
                 : 1.0
    onInitChoiceQuery.perform(
        function(eid, comp) {
          comp["team.score"] = comp["team.score"] * mult
          comp["team.scoreCap"] = comp["team.scoreCap"] * mult
        }
      )
  }
}

::ecs.register_es("group_activator_es", {
    [EventLevelLoaded] = onInitChoice,
  },
  {comps_ro = [ ["activator.activateChoice", ::ecs.TYPE_OBJECT], ["activator.initialLength", ::ecs.TYPE_INT], ["activator.enabled", ::ecs.TYPE_BOOL] ] },
  {tags = "server"}
)



 