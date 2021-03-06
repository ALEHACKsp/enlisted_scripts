local {EventHeroChanged} = require("gameevents")
local {EventEntityDied} = require("deathevents")
local {warningUpdate, warningHide, WARNING_PRIORITIES, addWarnings} = require("ui/hud/state/warnings.nut")
local {localPlayerTeamInfo} = require("enlisted/ui/hud/state/teams.nut")
const leftBattleArea = "leftBattleArea"
const taskPoint = "taskPoint"

addWarnings({
  [leftBattleArea]         = { priority = WARNING_PRIORITIES.HIGH, getSound = @() localPlayerTeamInfo.value?["team.narrator_leftBattleArea"] },
  [taskPoint]              = { priority = WARNING_PRIORITIES.HIGH, getSound = @() localPlayerTeamInfo.value?["team.narrator_taskPoint"] }
})

local function onBorderBattleArea(evt, eid, comp) {
  warningUpdate(leftBattleArea, comp.isAlive && evt.data["leaving"])
}

local function onBorderOldBattleArea(evt, eid, comp) {
  local enteringOldBattleArea = !evt.data["leaving"]
  warningUpdate(taskPoint, comp.isAlive && enteringOldBattleArea)
}

local function onHeroChanged(evt, eid, comp) {
  local outside = ::ecs.get_comp_val(evt[0], "isOutsideBattleArea", false)
  warningUpdate(leftBattleArea, outside)
  warningHide(taskPoint)
}

local function onHeroDied(evt, eid, comp) {
  warningHide(leftBattleArea)
  warningHide(taskPoint)
}

::ecs.register_es("leaving_battle_area_ui_es",
  {
    [::ecs.sqEvents.EventOnBorderBattleArea] = onBorderBattleArea,
    [::ecs.sqEvents.EventOnBorderOldBattleArea] = onBorderOldBattleArea,
    [EventHeroChanged] = onHeroChanged,
    [EventEntityDied] = onHeroDied,
  },
  {
    comps_rq = ["hero"],
    comps_ro = [["isAlive", ::ecs.TYPE_BOOL]]
  }
)
 