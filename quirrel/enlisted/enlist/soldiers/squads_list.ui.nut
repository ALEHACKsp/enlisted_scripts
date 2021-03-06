local fa = require("daRg/components/fontawesome.map.nut")
local { mkCurSquadsList } = require("mkSquadsList.nut")
local { smallPadding, multySquadPanelSize,
  listCtors } = require("enlisted/enlist/viewConst.nut")
local { curArmy, curSquadId, curChoosenSquads, curUnlockedSquads } = require("model/state.nut")
local { allSquadsLevels } = require("enlisted/enlist/researches/researchesState.nut")
local { notChoosenPerkSquads } = require("model/soldierPerks.nut")
local { unseenSquadsWeaponry } = require("model/unseenWeaponry.nut")
local { unseenSquadsVehicle } = require("enlisted/enlist/vehicles/unseenVehicles.nut")
local { unseenSquads } = require("model/unseenSquads.nut")
local blinkingIcon = require("enlisted/enlist/components/blinkingIcon.nut")
local { openChooseSquadsWnd } = require("model/chooseSquadsState.nut")
local { squadBgColor } = require("components/squadsUiComps.nut")
local { needSoldiersManageBySquad } = require("model/reserve.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")(0.7)
local { curUnseenUpgradesBySquad } = require("model/unseenUpgrades.nut")

local function newPerksArmyIcon(squad) {
  local count = ::Computed(@() ::max(notChoosenPerkSquads.value?[curArmy.value][squad.squadId] ?? 0,
      unseenSquadsWeaponry.value?[squad.guid] ?? 0)
    + (unseenSquadsVehicle.value?[squad.guid].len() ? 1 : 0)
    + (curUnseenUpgradesBySquad.value?[squad.guid] ?? 0))
  return function () {
    local res = { watch = count }
    if (count.value > 0)
      res.__update(blinkingIcon("user", count.value, false))
    return res
  }
}

local squadAlertIcon = @(squad) function() {
  local ret = { watch = needSoldiersManageBySquad }
  local needManage = needSoldiersManageBySquad.value?[squad.guid] ?? false
  return needManage ? ret.__update(unseenSignal) : ret
}

local restSquadsCount = ::Computed(@()
  max(curUnlockedSquads.value.len() - curChoosenSquads.value.len(), 0))

local curSquadsList = ::Computed(@() (curChoosenSquads.value ?? [])
  .map(@(squad, idx) squad.__merge({
    addChild = @() { //function need only to notcreate computed direct in computed. Maybe it will be allowed in future
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      children = [
        squadAlertIcon(squad)
        newPerksArmyIcon(squad)
      ]
    }
    level = allSquadsLevels.value?[squad.squadId] ?? 0
  })))


local dot = @(sf) {
  rendObj = ROBJ_STEXT
  font = Fonts.fontawesome
  text = fa["circle"]
  color = listCtors.txtColor(sf, false)
  fontSize = hdpx(5)
}

local unseeSquadsIcon = @() {
  watch = [unseenSquads, curArmy]
  hplace = ALIGN_RIGHT
  children = (unseenSquads.value?[curArmy.value] ?? {}).findindex(@(v) v)
    ? unseenSignal
    : null
}

local squadManageButton = ::watchElemState(function(sf) {
  local rest = restSquadsCount.value
  return {
    rendObj = ROBJ_SOLID
    watch = restSquadsCount
    size = [multySquadPanelSize[0], (multySquadPanelSize[1] * 0.5).tointeger()]
    behavior = Behaviors.Button
    xmbNode = ::XmbNode()
    color = squadBgColor(sf, false)
    onClick = @() openChooseSquadsWnd(curArmy.value, curSquadId.value)
    children = [
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = ::hdpx(2)
        children = [dot(sf), dot(sf), dot(sf)]
      }
      rest < 1 ? null : {
        rendObj = ROBJ_DTEXT
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        font = Fonts.small_text
        color = listCtors.txtColor(sf, false)
        text = $"+{rest}"
        padding = smallPadding
      }
      unseeSquadsIcon
    ]
  }
})

return mkCurSquadsList({
  curSquadsList
  curSquadId
  addedObj = squadManageButton
})
 