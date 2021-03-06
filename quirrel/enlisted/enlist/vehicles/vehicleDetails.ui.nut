local { unitSize, bigPadding, smallPadding, textBgBlurColor, detailsHeaderColor } = require("enlisted/enlist/viewConst.nut")
local defcomps = require("enlisted/enlist/components/defcomps.nut")
local textButton = require("enlist/components/textButton.nut")
local {
  statusTier, statusIconLocked, statusIconBlocked, hintText
} = require("enlisted/enlist/soldiers/components/itemPkg.nut")
local {
  viewVehicle, selectVehicle, selectedVehicle, selectParams, curSquadId, curSquadArmy,
  CAN_USE, LOCKED, CANT_USE, CAN_RECEIVE_BY_ARMY_LEVEL, NEED_RESEARCH_USE
} = require("vehiclesListState.nut")
local { getItemName } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local { isGamepad } = require("ui/control/active_controls.nut")
local { focusResearch, findClosestResearch } = require("enlisted/enlist/researches/researchesFocus.nut")
local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { blur } = require("enlisted/enlist/soldiers/components/itemDetailsPkg.nut")

local close = @() selectParams(null)

local function txt(text) {
  local children = (::type(text) == "string")
    ? defcomps.txt({font = Fonts.small_text, text = text})
    : defcomps.txt(text)
  return blur(children)
}

local function makeStandartDetailRow(detail_id, measure) {
  return function(details) {
    local val = details?[detail_id]
    if (val == null)
      return []
    return [
      txt(::loc("vehicleDetails/{0}".subst(detail_id)))
      { size = [flex(), SIZE_TO_CONTENT] }
      txt(::loc("vehicleDetails/{0}".subst(measure), { val = val }))
    ]
  }
}

local function enginePowerRow(details) {
  if (!("enginePower" in details) || !("engineSpeed" in details))
    return []
  return [
    txt(::loc("vehicleDetails/enginePower"))
    { size = [flex(), 0] }
    txt(::loc("vehicleDetails/enginePowerReadings", { enginePower = details.enginePower, engineSpeed = details.engineSpeed }))
  ]
}

local detailsList = [
  makeStandartDetailRow("gunRotationSpeed", "°/С")
  makeStandartDetailRow("vCorners", "°")
  makeStandartDetailRow("reloadTime", "seconds")
  makeStandartDetailRow("corpArmorTickness","millimeter")
  makeStandartDetailRow("towerArmorTickness", "millimeter")
  makeStandartDetailRow("penetration", "millimeter")
  makeStandartDetailRow("distancePenetration", "meter")
  enginePowerRow
  makeStandartDetailRow("weight", "tons")
  makeStandartDetailRow("visibility", "%")
]

local detailsBlock = @(details) details
  ? {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = ::hdpx(1)
      children = detailsList.map(@(detailCtor) {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        children = detailCtor(details)
      })
    }
  : null

local mkStatusRow = @(text, icon) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = textBgBlurColor
  padding = smallPadding
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    hintText(text)
    icon
  ]
}

local vehicleStatusRow = @(item) item.status == CAN_USE ? null
  : mkStatusRow(item.statusText,
      (item.status & (LOCKED | CANT_USE)) ? statusIconLocked : statusIconBlocked)

local backButton = textButton.Flat(::loc("mainmenu/btnBack"), close, { margin = 0 })

local function mkChooseButton(curVehicle, selVehicle) {
  if (curVehicle == selVehicle || curVehicle == null)
    return null

  if (curVehicle.status == CAN_USE)
    return textButton.PrimaryFlat(::loc("mainmenu/btnSelect"), @() selectVehicle(curVehicle), { margin = 0 })

  if (curVehicle.status & LOCKED)
    return !(curVehicle.status & CAN_RECEIVE_BY_ARMY_LEVEL) ? null
      : textButton.Flat(::loc("GoToArmyLeveling"),
          function() {
            close()
            setCurSection("SQUADS")
          },
          { margin = 0 })

  return !(curVehicle.status & NEED_RESEARCH_USE) ? null
    : textButton.PrimaryFlat(::loc("mainmenu/btnResearch"),
        function() {
          local { basetpl } = curVehicle
          local squadId = curSquadId.value
          local research = findClosestResearch(curSquadArmy.value,
            @(researchData) (researchData?.effect.vehicle_usage?[squadId] ?? []).contains(basetpl))
          focusResearch(research)
          close()
        },
        { margin = 0 })
}


local animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic,
    play = true, trigger = "vehicleDetailsAnim"}
  { prop = AnimProp.translate, from =[0, hdpx(100)], to = [0, 0], duration = 0.15, easing = OutQuad,
    play = true, trigger = "vehicleDetailsAnim"}
]

local buttons = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = [viewVehicle, selectedVehicle, isGamepad]
  color = textBgBlurColor
  flow = FLOW_HORIZONTAL
  padding = bigPadding
  gap = bigPadding
  valign = ALIGN_BOTTOM
  children = [
    !isGamepad.value ? backButton : null
    mkChooseButton(viewVehicle.value, selectedVehicle.value)
  ]
}

local lastVehicleTpl = null
return function() {
  local res = { watch = viewVehicle }
  local item = viewVehicle.value
  if (lastVehicleTpl != item?.basetpl) {
    lastVehicleTpl = item?.basetpl
    ::anim_start("vehicleDetailsAnim")
  }
  return res.__update({
    size = [unitSize * 10, flex()]
    flow = FLOW_VERTICAL
    gap = bigPadding
    valign = ALIGN_BOTTOM
    halign = ALIGN_RIGHT
    transform = {}
    animations = animations
    children = [
      txt({
        font = Fonts.big_text
        color = detailsHeaderColor
        text = getItemName(item)
      })
      item?.tier ? blur(statusTier(item)) : null
      vehicleStatusRow(item)
      item?.guid == null ? null
        : item?.guns?.len() ? {
            flow = FLOW_VERTICAL
            children = [
              {
                flow = FLOW_VERTICAL
                gap = ::hdpx(1)
                halign = ALIGN_RIGHT
                children = item.guns.map(@(gun, idx) txt(
                  "{gun}{amount}{ammo}".subst({
                    gun = ::loc("guns/{0}".subst(gun.gun_id))
                    amount = gun.amount > 1 ? " {0}".subst(::loc("vehicleDetails/amount", { val = gun.amount })) : ""
                    ammo = gun.ammo > 0 ? " {0}".subst(::loc("vehicleDetails/ammunition", { val = gun.ammo })) : ""
                  })
                ))
              }
            ]
          }
        : txt(::loc("vehicleDetails/weaponsNotInstalled"))
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = ::hdpx(1)
        children = [
          (item?.crew ?? 0) > 0
            ? {
                size = [flex(), SIZE_TO_CONTENT]
                flow = FLOW_HORIZONTAL
                children = [
                  txt(::loc("vehicleDetails/crew"))
                  { size = [flex(), SIZE_TO_CONTENT] }
                  txt(::loc("vehicleDetails/crewCount", { crewCount = item?.crew }))
                ]
              }
            : null
          detailsBlock(item?.details)
        ]
      }
      buttons
    ]
  })
}


 