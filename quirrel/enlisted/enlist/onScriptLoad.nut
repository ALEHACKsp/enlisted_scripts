local { get_circuit } = require("app")
local {DBGLEVEL} = require("dagor.system")
require("styleUpdate.nut")
require("notifications.nut")
require("currency/currenciesList.nut")
require("sections.nut")
require("scene/scene_control.nut")
require("soldiers/selectItemScene.nut")
require("campaigns/selectCampaignArmyScene.nut")
require("meta/profileServer.nut")
require("meta/profileRefresh.nut")
require("faceGen.nut")
require("battleData/sendSoldiersData.nut")
require("battleData/mkDefaultProfile.nut")
require("battleData/singleMissionRewardId.nut")
require("enlisted/enlist/deliveries/deliveriesScene.nut")
require("battleData/applyBattleExp.nut")
require("mainMenu/menuHeaderRightUiList.nut")
local { mainMenuWatchedComp } = require("enlist/mainMenu/mainMenuComp.nut")
local mainMenu = require("enlisted/enlist/mainMenu/mainMenu.nut")
mainMenuWatchedComp(@(v) v.comp <- mainMenu)
require("notifications/mainMenuDescription.nut")
require("notifications/premiumExpiration.nut")
require("configs/configs.nut")
require("login/initLoginStages.nut")
require("squad/contactBlockExtensionCtr.nut")
require("squad/myExtData.nut")
require("soldiers/choosePerkWnd.nut")
require("enlisted/enlist/currency/initPurchaseActions.nut")
require("soldiers/chooseSquadsScene.nut")
require("soldiers/chooseSoldiersScene.nut")
require("soldiers/notReadySquadsMsg.nut")
require("enlist/roomsListState.nut").lobbyEnabled(DBGLEVEL > 0 || ["moon","sun","ganymede"].indexof(get_circuit()) != null)
require("enlist/squad/squadState.nut").autoSquad(false)
local { matchingQueues } = require("enlist/matchingQueues.nut")

local quickMatchQueueInfoCmp = require("queueWaitingInfo.ui.nut")
local {aboveUiLayer} = require("enlist/uiLayers.nut")
aboveUiLayer.add(quickMatchQueueInfoCmp, "quickMatchQueue")

local { matchRandomTeam, selectedQueue, selectQueue, matchingTeam } = require("enlist/quickMatchQueue.nut")
local { mteam, curCampaign, playerSelectedArmy } = require("soldiers/model/state.nut")

mteam.subscribe(@(m) matchingTeam(m))
matchingTeam(mteam.value)

local {haveUnseenVersions} = require("changeLogState.nut")
local {openChangelog} = require("openChangelog.nut")
haveUnseenVersions.subscribe(@(have) have ? openChangelog() : null)

curCampaign.subscribe(function(campaign){
  local queues = matchingQueues.value
  local suitableQueue = selectedQueue.value
  foreach (queue in queues){
    if (queue?.extraParams?.campaigns.indexof(campaign)!=null){
      suitableQueue = queue
      break
    }
  }
  selectQueue(suitableQueue)
})

local leaveQueueNotification = require("notifications/leaveQueueNotification.nut")
leaveQueueNotification(curCampaign)
leaveQueueNotification(playerSelectedArmy, {
  askLeave = @(self) self.watch.value != self.last && !matchRandomTeam.value
})

local dCtorBase = require("enlisted/enlist/debriefing/debriefingCtor.nut")
require("enlist/debriefing/debriefingInMenu.nut")(dCtorBase)

local debriefingDbg = require("enlist/debriefing/debriefing_dbg.nut")
local debriefingState = require("enlist/debriefing/debriefingStateInMenu.nut")
debriefingDbg.init({
  state = debriefingState
  samplePath = ["../prog/scripts/enlisted/enlist/debriefing/samples/debriefing_sample.json",
                "../prog/scripts/enlisted/enlist/debriefing/samples/debriefing_sample2.json"]
  savePath = "debriefing_enlisted.json"
  loadPostProcess = function(debrData) {
    if (typeof debrData?.players != "table")
      return

    local players = {}
    foreach(id, player in debrData.players)
      players[id.tointeger()] <- player
    debrData.players = players
  }
})

console.register_command(@(trigger) ::anim_start(trigger), "anim.start")
console.register_command(@(trigger) ::anim_stop(trigger), "anim.stop")
console.register_command(@(trigger) ::anim_skip(trigger), "anim.skip")
console.register_command(@(trigger) ::anim_skip_delay(trigger), "anim.skipDelay")
 