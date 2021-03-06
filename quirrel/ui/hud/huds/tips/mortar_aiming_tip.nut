local { tipCmp } = require("tipComponent.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")

local isMortarMode = Watched(false)
local mortarDistance = Watched(0.0)
local mortarEid = INVALID_ENTITY_ID

local function trackMortarMode(evt, eid, comp) {
  local isActive = comp["human_weap.mortarMode"]
  isMortarMode(isActive)
  mortarEid = (isActive ? comp["human_weap.currentGunEid"] : null) ?? INVALID_ENTITY_ID
  local distance = ::ecs.get_comp_val(mortarEid, "mortar.targetDistance", 0.0)
  if (distance > 0)
    mortarDistance(distance)
}

::ecs.register_es("mortar_aiming_mode_es",
  {
    [["onInit", "onChange"]] = trackMortarMode
    onDestroy = @(evt, eid, comp) isMortarMode(false)
  },
  {
    comps_track = [
      ["human_weap.mortarMode", ::ecs.TYPE_BOOL],
      ["human_weap.currentGunEid", ::ecs.TYPE_EID, INVALID_ENTITY_ID]
    ]
    comps_rq = ["hero","watchedByPlr"]
  })

local function trackMortarDistance(evt, eid, comp) {
  if (eid != mortarEid)
    return
  local distance = comp["mortar.targetDistance"]
  if (distance > 0)
    mortarDistance(distance)
}

::ecs.register_es("mortar_aiming_distance_es",
  {
    [["onInit", "onChange"]] = trackMortarDistance
  },
  {
    comps_track = [["mortar.targetDistance", ::ecs.TYPE_FLOAT]]
  })

local mkAimDistance = @(distance) tipCmp({
  text = ::loc("hud/mortar_aiming", { distance = distance })
  inputId = "Human.Aim"
})

local function mortar() {
  local res = { watch = [isMortarMode, mortarDistance, showPlayerHuds] }
  if (!showPlayerHuds.value || !isMortarMode.value)
    return res
  return res.__update({
    children = mkAimDistance(mortarDistance.value.tointeger())
  })
}

return mortar
 