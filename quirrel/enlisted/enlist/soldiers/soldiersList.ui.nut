local { notChoosenPerkArmies } = require("model/soldierPerks.nut")
local { unseenArmiesWeaponry } = require("model/unseenWeaponry.nut")
local { unseenArmiesVehicle } = require("enlisted/enlist/vehicles/unseenVehicles.nut")
local {bigPadding} = require("enlisted/enlist/viewConst.nut")
local armySelect = require("army_select.ui.nut")
local squads_list = require("squads_list.ui.nut")
local squad_info = require("squad_info.ui.nut")
local mkSoldierInfo = require("mkSoldierInfo.nut")
local squadInfoState = require("model/squadInfoState.nut")
local campaignTitle = require("enlisted/enlist/campaigns/campaign_title.ui.nut")
local { startBtn, startBtnWidth } = require("enlisted/enlist/startBtn.nut")
local queueSelect = require("enlist/devQueueSelect.ui.nut")
local { curUnfinishedBattleTutorial } = require("enlisted/enlist/tutorial/battleTutorial.nut")
local { mkClustersUi } = require("enlist/clusters.nut")
local { matchRandomTeam } = require("enlist/quickMatchQueue.nut")
local blinkingIcon = require("enlisted/enlist/components/blinkingIcon.nut")
local { randTeamCheckbox } = require("enlisted/enlist/quickMatch.nut")
local { DBGLEVEL } = require("dagor.system")
local { unseenUpgradesByArmy } = require("model/unseenUpgrades.nut")

local quickMatchButtonWidth = hdpx(400)

local armySelectWithMarks = armySelect({
  function addChild(armyId, sf) {
    local count = ::Computed(@()
      ::max(notChoosenPerkArmies.value?[armyId] ?? 0, unseenArmiesWeaponry.value?[armyId] ?? 0)
      + (unseenArmiesVehicle.value?[armyId] ?? 0)
      + (unseenUpgradesByArmy.value?[armyId].len() ?? 0))
    return function() {
      local res = { watch = count, pos = [hdpx(25), 0], key = armyId }
      if(count.value <= 0)
        return res
      return blinkingIcon("user", count.value, false).__update(res)
    }
  }
})

local mainContent = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    armySelectWithMarks
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        squads_list
        squad_info
        mkSoldierInfo({ soldierInfoWatch = squadInfoState.curSoldierInfo })
      ]
    }
  ]
}

local clustersUi = mkClustersUi({style = {size = [startBtnWidth, SIZE_TO_CONTENT]}})

local randTeamCheckboxBlock = @() {
  watch = [curUnfinishedBattleTutorial, matchRandomTeam]
  children = curUnfinishedBattleTutorial.value == null ? randTeamCheckbox : null
}

local allowQueueSelect = persist("allowQueueSelect", @() Watched(DBGLEVEL > 0))
::console.register_command( @() allowQueueSelect(!allowQueueSelect.value), "feature.toggle.allowQueueSelect")

local queueSelectUi = @(){
  watch = allowQueueSelect
  children = allowQueueSelect.value ? queueSelect : null
  padding = allowQueueSelect.value ? hdpx(10) : 0
}

local startPlay = {
  size = flex()
  halign = ALIGN_RIGHT
  children = {
    size = [quickMatchButtonWidth, flex()]
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = bigPadding
    children = [
      {size = [0, flex()]}
      queueSelectUi
      startBtn
      clustersUi
      randTeamCheckboxBlock
    ]
  }
}

return {
  size = flex()
  halign = ALIGN_RIGHT
  children = [
    mainContent
    campaignTitle
    startPlay
  ]
} 