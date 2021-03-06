local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local { settings, onlineSettingUpdated } = require("enlist/options/onlineSettings.nut")
local { curCampaign, curArmy } = require("enlisted/enlist/soldiers/model/state.nut")
local debriefingState = require("enlist/debriefing/debriefingStateInMenu.nut")
local { lastGame } = require("enlist/gameLauncher.nut")

local SAVE_FOLDER = "battleTutorial"
const defTutorial = "content/e_normandy/gamedata/scenes/normandy_tutorial_germ.blk" //used when profileServer unavaialble

local tutorialSceneByArmy = {
  berlin_axis = "content/e_berlin/gamedata/scenes/berlin_tutorial_germ.blk"
  berlin_allies = "content/e_berlin/gamedata/scenes/berlin_tutorial_ussr.blk"
  moscow_axis = "content/e_moscow/gamedata/scenes/volokolamsk_tutorial_germ.blk"
  moscow_allies = "content/e_moscow/gamedata/scenes/volokolamsk_tutorial_ussr.blk"
  normandy_axis = "content/e_normandy/gamedata/scenes/normandy_tutorial_germ.blk"
  normandy_allies = "content/e_normandy/gamedata/scenes/normandy_tutorial_usa.blk"
}

local curTutorialGroup = ::Computed(function() {
  local groupId = gameProfile.value?.campaigns[curCampaign.value].tutorial
  local group = gameProfile.value?.tutorials[groupId]
  if (groupId == null || group == null)
    return null

  return {
    id = groupId
    version = group?.version ?? 1
    scene = tutorialSceneByArmy?[curArmy.value]
  }
})

local curBattleTutorial = ::Computed(@() curTutorialGroup.value?.scene ?? defTutorial)

local curUnfinishedBattleTutorial = ::Computed(function() {
  if (!onlineSettingUpdated.value)
    return null

  local group = curTutorialGroup.value
  if (group == null)
    return null

  local { version, id } = group
  return (settings.value?[SAVE_FOLDER][id] ?? 0) != version ? group.scene : null
})

local function markCompleted() {
  local group = curTutorialGroup.value
  if (group == null)
    return

  settings(function(saved) {
    local saveData = saved?[SAVE_FOLDER] ?? {}
    local { version, id } = group
    saved[SAVE_FOLDER] <- saveData.__merge({ [id] = version })
  })
}

local function resetTutorialsSave() {
  if (SAVE_FOLDER in settings.value)
    settings(function(saved) { delete saved[SAVE_FOLDER] })
}

local lastGameTutorialId = ::Computed(function() {
  local lastScene = lastGame.value?.scene
  if (lastScene == null)
    return null
  return lastScene == curTutorialGroup.value?.scene ? curTutorialGroup.value.id : null
})

debriefingState.data.subscribe(function(debData) {
  if ((debData?.result.success ?? false) && lastGame.value?.scene == curBattleTutorial.value)
    markCompleted()
})

console.register_command(markCompleted, "tutorial.markCompleted")
console.register_command(@() console_print(curBattleTutorial.value), "tutorial.getCurrent")
console.register_command(resetTutorialsSave, "tutorial.resetComplete")

return {
  curBattleTutorial = curBattleTutorial
  curUnfinishedBattleTutorial = curUnfinishedBattleTutorial
  lastGameTutorialId = lastGameTutorialId
}
 