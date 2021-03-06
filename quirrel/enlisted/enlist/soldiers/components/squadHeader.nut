local fa = require("daRg/components/fontawesome.map.nut")
local { gap, noteTxtColor, defTxtColor, disabledTxtColor } = require("enlisted/enlist/viewConst.nut")
local { autoscrollText, txt, note } = require("enlisted/enlist/components/defcomps.nut")
local tooltipBox = require("ui/style/tooltipBox.nut")
local { tooltip } = require("ui/style/cursors.nut")
local { READY } = require("enlisted/enlist/soldiers/model/readyStatus.nut")
local { mkSquadPremIcon } = require("squadsUiComps.nut")
local { classIcon, className } = require("soldiersUiComps.nut")


local mkMaxSquadSizeComp = @(curSquadParams, vehicleCapacity) ::Computed(function() {
  local size = curSquadParams.value?.size ?? 1
  local vCapacity = vehicleCapacity.value
  return vCapacity > 0 ? min(size, vCapacity) : size
})

local mkSClassLimitsComp = @(curSquad, curSquadParams, soldiersList, soldiersStatuses) ::Computed(function() {
  local res = []
  local maxClasses = curSquadParams.value?.maxClasses ?? {}
  if (!maxClasses.len())
    return res

  local soldierStatus = soldiersStatuses.value
  local usedClasses = {}
  foreach(idx, soldier in soldiersList.value) {
    if (soldierStatus?[soldier.guid] != READY)
      continue
    local sClass = soldier?.sClass ?? ""
    usedClasses[sClass] <- (usedClasses?[sClass] ?? 0) + 1
  }

  local fillerClass = curSquad.value?.fillerClass
  foreach(sClass, total in maxClasses)
    res.append({
      sClass = sClass
      total = total
      used = usedClasses?[sClass] ?? 0
      isFiller = sClass == fillerClass
    })
  res.sort(@(a, b) a.isFiller <=> b.isFiller || b.total <=> a.total || a.sClass <=> b.sClass)
  return res
})

local classAmountHint = @(sClassLimits) @() {
  watch = sClassLimits
  flow = FLOW_VERTICAL
  gap = gap
  children = [
    txt({
      text = ::loc("hint/squadClassLimits")
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = ::hdpx(400)
    })
  ].extend(sClassLimits.value.map(@(c) {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = gap
      children = [
        txt({ text = $"{c.used}/{c.total}", size = [::hdpx(30), SIZE_TO_CONTENT], halign = ALIGN_RIGHT })
        classIcon(c.sClass, ::hdpx(30))
        className(c.sClass).__update({ font = Fonts.small_text, color = defTxtColor })
      ]
    }))
}

local mkClassAmount = @(sClass, total, used) {
  size = [flex(), ::hdpx(34)]
  flow = FLOW_VERTICAL
  maxWidth = pw(20)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    classIcon(sClass, ::hdpx(24))
    note({ text = $"{used}/{total}", color = noteTxtColor })
  ]
}

local squadClassesUi = @(sClassLimits) @() {
  watch = sClassLimits
  size = [flex(), SIZE_TO_CONTENT]
  margin = [gap, 0]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = {
    rendObj = ROBJ_SOLID
    size = [hdpx(1), flex()]
    color = disabledTxtColor
  }
  children = sClassLimits.value
    .filter(@(c) c.total > 0)
    .map(@(c) mkClassAmount(c.sClass, c.total, c.used))
}

local sizeHint = @(battleAmount, maxAmount) @() {
  watch = [battleAmount, maxAmount]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = ::hdpx(500)
  color = defTxtColor
  text = ::loc("hint/maxSquadSize", {
    battle = battleAmount.value
    max = maxAmount.value
  })
}

local squadSizeUi = @(battleAmount, maxSquadSize) function() {
  local res = { watch = [battleAmount, maxSquadSize] }
  local size = maxSquadSize.value
  if (size <= 0)
    return res

  return res.__update({
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onHover = @(on) tooltip.state(!on ? null : tooltipBox(sizeHint(battleAmount, maxSquadSize)))
    skipDirPadNav = true
    children = [
      txt({ text = $"{battleAmount.value}/{size}", color = noteTxtColor })
      {
        rendObj = ROBJ_STEXT
        font = Fonts.fontawesome
        fontSize = ::hdpx(12)
        text = fa["user-o"]
        color = noteTxtColor
      }
    ]
  })
}

local function squadHeader(curSquad, curSquadParams, soldiersList, vehicleCapacity, soldiersStatuses) {
  local maxSquadSize = mkMaxSquadSizeComp(curSquadParams, vehicleCapacity)
  local battleAmount = ::Computed(@()
    soldiersList.value.reduce(@(res, s) soldiersStatuses.value?[s.guid] == READY ? res + 1 : res, 0))
  local sClassLimits = mkSClassLimitsComp(curSquad, curSquadParams, soldiersList, soldiersStatuses)

  return function() {
    local res = { watch = curSquad }
    local squad = curSquad.value
    if (!squad)
      return res

    local group = ::ElemGroup()
    return res.__update({
      group = group
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      onHover = @(on) tooltip.state(on ? tooltipBox(classAmountHint(sClassLimits)) : null)
      skipDirPadNav = true
      children = [
        {
          size = [flex(), ::hdpx(26)]
          flow = FLOW_HORIZONTAL
          gap = gap
          children = [
            mkSquadPremIcon(squad?.premIcon, { pos = [0, -::hdpx(2)] })
            autoscrollText({
              group = group
              text = ::loc(squad?.titleLocId)
              color = noteTxtColor
              textParams = { font = Fonts.tiny_text }
            })
            squadSizeUi(battleAmount, maxSquadSize)
          ]
        }
        squadClassesUi(sClassLimits)
      ]
    })
  }
}

return ::kwarg(squadHeader) 