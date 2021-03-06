local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local weaponSlots = require("globals/weapon_slots.nut")
local {get_sync_time} = require("net")
local actionTimer = Watched({ curProgress = -1.0, totalTime = -1.0, endTimeToComplete = -1.0, actionTimerMul = 1, actionTimerColor = Color(0, 0, 0, 0)})

local function resetState() {
  actionTimer({curProgress = -1.0, totalTime = -1.0, endTimeToComplete = -1.0, actionTimerMul = 1 actionTimerColor = Color(0, 0, 0, 0)})
}

local destroyableBuildingsQuery = ::ecs.SqQuery("buildingsQuery", {
  comps_ro = [
    ["building_destroy.timeToDestroy", ::ecs.TYPE_FLOAT],
    ["building_destroy.maxTimeToDestroy", ::ecs.TYPE_FLOAT],
    ["actionTimerColor", ::ecs.TYPE_POINT3]
  ],
})

local unfinishedBuildingsQuery = ::ecs.SqQuery("buildingsQuery", {
  comps_ro = [
    ["building_builder.timeToBuild", ::ecs.TYPE_FLOAT],
    ["building_builder.maxTimeToBuild", ::ecs.TYPE_FLOAT],
    ["actionTimerColor", ::ecs.TYPE_POINT3]
  ],
})

local buildersQuery = ::ecs.SqQuery("buildingsQuery", {
  comps_ro = [
    ["building_action.target", ::ecs.TYPE_EID],
    ["human_weap.gunEids", ::ecs.TYPE_EID_LIST]
  ],
})

local function trackComponents(evt, eid, comp) {
  local hero = watchedHeroEid.value
  local herobuildingEid = INVALID_ENTITY_ID
  buildersQuery.perform(hero, function(eid, buildersComps) {
    herobuildingEid = buildersComps["building_action.target"]
  })
  if (herobuildingEid == INVALID_ENTITY_ID) {
    resetState()
    return
  }
  local actionSpeed = 1.0
  buildersQuery.perform(function(eid, buildersComps) {
    if (herobuildingEid == buildersComps["building_action.target"]){
      local scondaryGunEid = buildersComps["human_weap.gunEids"][weaponSlots.EWS_SECONDARY]
      actionSpeed = ::ecs.get_comp_val(scondaryGunEid,"engineerBuildingSpeedMul") ?? 1.0
    }
  })
  if (actionSpeed <= 0.0)
    return
  local curTime = get_sync_time()
  destroyableBuildingsQuery.perform(herobuildingEid, function(eid, buildingComps) {
    local maxTimeToDestroy = buildingComps["building_destroy.maxTimeToDestroy"]
    if (maxTimeToDestroy <= 0.0)
      return
    local timeToDestroy = buildingComps["building_destroy.timeToDestroy"]
    local totalDestroyTime = timeToDestroy / actionSpeed
    local realTimeToCompleteBuild = curTime + totalDestroyTime
    local color = buildingComps.actionTimerColor
    actionTimer(function (v) {
      v.curProgress = timeToDestroy / maxTimeToDestroy
      v.totalTime = totalDestroyTime
      v.endTimeToComplete = realTimeToCompleteBuild
      v.actionTimerMul = -1 * v.curProgress
      v.actionTimerColor = Color(color.x, color.y, color.z, 0)
    })
  })
  unfinishedBuildingsQuery.perform(herobuildingEid, function(eid, buildingComps) {
    local maxTimeToBuild = buildingComps["building_builder.maxTimeToBuild"]
    if (maxTimeToBuild <= 0.0)
      return
    local timeToBuild = buildingComps["building_builder.timeToBuild"]
    local totalBuildTime = (maxTimeToBuild - timeToBuild) / actionSpeed
    local realTimeToCompleteBuild = curTime + totalBuildTime
    local color = buildingComps.actionTimerColor
    actionTimer(function (v) {
      v.curProgress = timeToBuild / maxTimeToBuild
      v.totalTime = totalBuildTime
      v.endTimeToComplete = realTimeToCompleteBuild
      v.actionTimerMul = 1 - v.curProgress
      v.actionTimerColor = Color(color.x, color.y, color.z, 0)
    })
  })
}


::ecs.register_es("buildings_destroyer_ui_es", {
  onChange = trackComponents
},
{
  comps_track = [
    ["building_action.target", ::ecs.TYPE_EID],
  ]
})

return {actionTimer = actionTimer} 