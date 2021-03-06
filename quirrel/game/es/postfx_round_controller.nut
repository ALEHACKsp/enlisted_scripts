local { TEAM_UNASSIGNED } = require("team")
local {get_controlled_hero} = require("globals/common_queries.nut")
local {EventTeamRoundResult} = require("teamevents")

local function onRoundResult(evt, eid, comp) {
  local heroTeam = ::ecs.get_comp_val(get_controlled_hero() ?? INVALID_ENTITY_ID, "team", TEAM_UNASSIGNED)
  if (evt[0] != heroTeam)
    return
  comp["postfx_round_ctrl.maxExposure"] = comp["post_fx"]["adaptation.maxExposure"] ?? comp["postfx_round_ctrl.maxExposure"]
  comp["post_fx"]["adaptation.maxExposure"] <- 1000.0
  comp["post_fx"]["adaptation.minExposure"] = 0.001
  local expScale = evt[1] ? comp["postfx_round_ctrl.scaleOnWin"] : comp["postfx_round_ctrl.scaleOnLose"];
  comp["postfx_round_ctrl.expScale"] = expScale
  comp["post_fx"]["adaptation.adaptUpSpeed"] = 1
  comp["post_fx"]["adaptation.adaptDownSpeed"] = 1
  ::ecs.recreateEntityWithTemplates({eid = eid, addTemplates = ["postfx_roundctrl_update"]})
}

local postfx_comps = {
  comps_rw = [
    ["post_fx", ::ecs.TYPE_OBJECT],
    ["postfx_round_ctrl.expScale", ::ecs.TYPE_FLOAT],
    ["postfx_round_ctrl.maxExposure", ::ecs.TYPE_FLOAT],
  ],
  comps_ro = [
    ["postfx_round_ctrl.scaleOnWin", ::ecs.TYPE_FLOAT, 1.15],
    ["postfx_round_ctrl.scaleOnLose", ::ecs.TYPE_FLOAT, 0.9],
  ]
}

::ecs.register_es("postfx_round_ctrl_es", {
  [EventTeamRoundResult] = onRoundResult,
}, postfx_comps)


local function onUpdate(dt, eid, comp){
  local post_fx = comp["post_fx"]
  local curScale = post_fx?["adaptation.autoExposureScale"] ?? 1.0
  post_fx["adaptation.autoExposureScale"] <- ::min(1000.0, curScale * comp["postfx_round_ctrl.expScale"] * dt * 5.0)
}

local updateComps = clone postfx_comps
updateComps.comps_rq <- ["postfx_round_ctrl_update"]

::ecs.register_es(
  "postfx_round_ctrl_update_es",
  {onUpdate = onUpdate},
  updateComps,
  {updateInterval = 0.2, tags="render", before="postfx_round_ctrl_es"}
)
 