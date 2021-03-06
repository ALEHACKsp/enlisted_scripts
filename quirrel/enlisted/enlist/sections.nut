local { sectionsSorted } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local soldiersList = require("soldiers/soldiersList.ui.nut")
local armyUnlocksUi = require("soldiers/armyUnlocksUi.nut")
local researchesList = require("researches/researchesList.ui.nut")
local { unseenResearches } = require("researches/unseenResearches.nut")
local { hasCurArmyUnlockAlert } = require("soldiers/model/armyUnlocksState.nut")
local { unseenClasses } = require("enlisted/enlist/soldiers/model/unseenClasses.nut")
local {
  hasTrainedSoldier, hasArmyTraining
} = require("enlisted/enlist/soldiers/model/trainingState.nut")
local academyUi = require("soldiers/academyUi.nut")
local armyShopUi = require("shop/armyShopUi.nut")
local { curUnseenAvailableShopItems } = require("shop/armyShopState.nut")

local hasTrainAlert = ::Computed(@()
  hasTrainedSoldier.value || (unseenClasses.value.len() > 0 && !hasArmyTraining.value))

local hasShopAlert = ::Computed(@() curUnseenAvailableShopItems.value.len() > 0)

sectionsSorted([

  {
    locId = "menu/soldier"
    content = soldiersList
    id = "SOLDIERS"
    camera = "soldiers"
  }

  {
    locId = "menu/campaignRewards"
    descId = "menu/campaignRewardsDesc"
    content = armyUnlocksUi
    id = "SQUADS"
    camera = "researches"
    unseenWatch = hasCurArmyUnlockAlert
  }

  {
    locId = "menu/researches"
    descId = "menu/researchesDesc"
    content = researchesList
    id = "RESEARCHES"
    camera = "researches"
    unseenWatch = ::Computed(@() unseenResearches.value.findindex(@(a) a.len() > 0) != null)
  }

  {
    locId = "menu/enlistedShop"
    content = armyShopUi
    id = "SHOP"
    camera = "researches"
    unseenWatch = hasShopAlert
  }

  {
    locId = "menu/academy"
    descId = "menu/academyDesc"
    content = academyUi
    id = "ACADEMY"
    camera = "researches"
    unseenWatch = hasTrainAlert
  }
])
 