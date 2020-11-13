local {revokeAllSquadInvites, dismissAllOfflineSquadmates,
  squadId, squadOnlineMembers, autoSquad, isInSquad, isSquadLeader, availableSquadMaxMembers,
  squadSharedData, squadMembers, isInvitedToSquad, squadLeaderState} = require("enlist/squad/squadState.nut")
local squadClusters = squadSharedData.clusters
local msgbox = require("components/msgbox.nut")
local { settings, onlineSettingUpdated } = require("enlist/options/onlineSettings.nut")

local clusterState = require("clusterState.nut")
local selfClusters = clusterState.clusters
local matchingCli = require("matchingClient.nut")
local matching_api = require("matching.api")
local matching_errors = require("matching.errors")
local {get_time_msec} = require("dagor.time")
local app = require("enlist.app")
local {matchingQueues} = require("matchingQueues.nut")
local localSettings = require("options/localSettings.nut")("quickMatch/")
local {get_app_id} = require("app")

const SAVED_QUEUE_ID = "selectedQueue"

local STATUS = {
  NOT_IN_QUEUE = 0
  JOINING = 1
  IN_QUEUE = 2
}

local queueStatus = Watched(STATUS.NOT_IN_QUEUE)
local debugShowQueue = Watched(false)
console.register_command(@() debugShowQueue(!debugShowQueue.value), "ui.showQueueInfo")
local isInQueue = ::Computed(function(){
  return queueStatus.value != STATUS.NOT_IN_QUEUE || debugShowQueue.value
})

local matchRandomTeam = localSettings(true, "matchRandomTeam")

local savedQueueId = ::Computed(@()
  onlineSettingUpdated.value ? settings.value?[SAVED_QUEUE_ID] : null)

local selectedQueueInternal = Watched(null)

local selectedQueue = ::Computed(function() {
  if (isInSquad.value && !isSquadLeader.value && squadLeaderState.value?.selectedQueue!=null)
    return squadLeaderState.value.selectedQueue
  local queueId = selectedQueueInternal.value?.id ?? savedQueueId.value
  return matchingQueues.value.findvalue(@(val) val.id == queueId) ?? matchingQueues.value?[0]
})
local function selectQueue(queue){
//  if (::type(queue) == "string")
  selectedQueueInternal(queue)
}

local function saveSelectedQueue(...) {
  local queue = selectedQueueInternal.value
  if (typeof queue != "table" || !onlineSettingUpdated.value)
    return

  local queueId = queue?.id
  if (queueId != null && queueId != savedQueueId.value)
    settings(@(os) os[SAVED_QUEUE_ID] <- queueId)
}
selectedQueueInternal.subscribe(saveSelectedQueue)
onlineSettingUpdated.subscribe(saveSelectedQueue)
saveSelectedQueue()

local maxSquadSize = ::Computed(@() matchingQueues.value.reduce(@(res, gt) ::max(res, (gt?.maxGroupSize ?? 1)), 1))
maxSquadSize.subscribe(@(v) availableSquadMaxMembers(v))
availableSquadMaxMembers(maxSquadSize.value)

local matchingTeam = Watched(null)
local startQueueTime = Watched(0)
local timeInQueue = Watched(0)
local queueClusters = ::Computed(@()
    (isInSquad.value && !isSquadLeader.value && squadClusters.value != null) ? clone squadClusters.value : clone selfClusters.value) //clone to trigger change

local queueInfo = Watched(null)
local canChangeQueueParams = ::Computed(@() !isInQueue.value && (!isInSquad.value || isSquadLeader.value))

local function recalcSquadClusters(...) {
  if (isSquadLeader.value)
    squadSharedData.clusters(clone clusterState.clusters.value)
}
isSquadLeader.subscribe(recalcSquadClusters)
selfClusters.subscribe(recalcSquadClusters)

local private = {
  nextQPosUpdateTime  = 0
}

local function onTimer(){
  if (queueStatus.value == STATUS.NOT_IN_QUEUE)
    return

  timeInQueue.update(get_time_msec() - startQueueTime.value)

  local now = get_time_msec()
  if (now > private.nextQPosUpdateTime) {
    private.nextQPosUpdateTime = now + 1000000

    matchingCli.call("enlmm.get_my_queue_postion",
      function(response) {
        private.nextQPosUpdateTime = now + 5000
        if (response.error == 0)
          queueInfo(response)
      }
    )
  }
}

local wasStatus = queueStatus.value
queueStatus.subscribe(function(s) {
  if (s == STATUS.NOT_IN_QUEUE) {
    timeInQueue(0)
    startQueueTime(get_time_msec())
    queueInfo(null)
    ::gui_scene.clearTimer(onTimer)
  } else if (s == STATUS.JOINING || (s == STATUS.IN_QUEUE && wasStatus == STATUS.NOT_IN_QUEUE)) {
    startQueueTime(get_time_msec())
    timeInQueue(0)
    queueInfo(null)
    ::gui_scene.clearTimer(onTimer)
    ::gui_scene.setInterval(1.0, onTimer)

    app.on_queue_join()
  }
  wasStatus = s
})

local function errorText(response) {
  if (response.error == 0)
    return ""
  local errKey = response?.error_id ?? matching_errors.error_string(response.error)
  return ::loc("".concat("error/", errKey))
}

local function joinImpl(){
  matchingCli.netStateCall(function() {
    if (selectedQueue.value == null)
      return

    local params = {
      gameId = selectedQueue.value.id
      clusters = queueClusters.value.filter(@(has) has).keys()
      autoSquad = autoSquad.value
      groupType = selectedQueue.value?.groupType
      appId = get_app_id()
    }
    if (matchingTeam.value != null)
      params.mteams <- matchRandomTeam.value ? [0, 1] : [matchingTeam.value]

    if (isInSquad.value && squadOnlineMembers.value.len() > 1) {
      local smembers = []
      foreach (uid, member in squadOnlineMembers.value)
        smembers.append(uid)
      local squad = {
        members = smembers
        leader = squadId.value
      }
      params.squad <- squad
    }

    queueStatus(STATUS.JOINING)
    matchingCli.call("enlmm.join_quick_match_queue", function(response) {
      if (response.error != 0){
        log(response)
        queueStatus(STATUS.NOT_IN_QUEUE)
        msgbox.show({text = errorText(response) })
      }
    }, params)
  })
}

local curMaxGroupSize = Computed(@() selectedQueue.value?.maxGroupSize ?? 1)
local curMinGroupSize = Computed(@() selectedQueue.value?.minGroupSize ?? 1)
local tooBigGroup = Computed(@() curMaxGroupSize.value < squadOnlineMembers.value.len())
local tooSmallGroup = Computed(@() curMinGroupSize.value > squadOnlineMembers.value.len())

local function join() {
  if (!isInSquad.value)
    return joinImpl()

  local notReadyMembers = ""
  foreach (uid, member in squadOnlineMembers.value)
    if ((!member.isLeader.value && !member.state.value?.ready) || member.state.value?.inBattle)
      notReadyMembers += ((notReadyMembers != "") ? ", " : "") + member.contact.nick.value

  if (notReadyMembers.len())
    return msgbox.show({text=::loc("squad/notReadyMembers" {notReadyMembers=notReadyMembers})})
  if (tooSmallGroup.value)
    return msgbox.show({text=::loc("squad/tooFewMembers" { reqMembers=curMinGroupSize.value})})
  if (tooBigGroup.value)
    return msgbox.show({text=::loc("squad/tooMuchMembers" { maxMembers=curMaxGroupSize.value})})

  local offlineNum = squadMembers.value.len() - squadOnlineMembers.value.len()
  local msg = offlineNum ? ::loc("squad/hasOfflineMembers", { number = offlineNum }) : ""
  if (isInvitedToSquad.value.len())
    msg = (msg.len() ? "\n" : "").concat(msg, ::loc("squad/hasInvites", { number = isInvitedToSquad.value.len() }))

  if (msg.len()) {
    return msgbox.show({
      text = "\n".concat(msg, ::loc("squad/theyWillNotGoToBattle"))
      buttons = [
        { text = ::loc("squad/removeAndGoToBattle")
          isCurrent = true
          action = function() {
            dismissAllOfflineSquadmates()
            revokeAllSquadInvites()
            joinImpl()
          }
        }
        { text = ::loc("Cancel"), isCancel = true }
      ]
    })
  }
  else
    joinImpl()
}

local function leave(cb = null) {
  queueStatus(STATUS.NOT_IN_QUEUE)
  matchingCli.netStateCall(function() {
    matchingCli.call("enlmm.leave_quick_match_queue",
      function(response) {
        if (cb != null)
          cb()
      }.bindenv(this), {})
  })
}


/************************************* Subscriptions **************************************/

foreach(name, cb in {
  ["enlmm.on_quick_match_queue_leaved"] = function(request) {
    print("onQuickMatchQueueLeaved")
    log(request)
    queueStatus(STATUS.NOT_IN_QUEUE)
  },

  ["enlmm.on_quick_match_queue_joined"] = function(request) {
    print("onQuickMatchQueueJoined")
    log(request)
    queueStatus(STATUS.IN_QUEUE)
  },
})
matching_api.subscribe(name,cb)

matchingCli.connected.subscribe(function(newValue) {
  if (!newValue)
    queueStatus(STATUS.NOT_IN_QUEUE)
})

//leave queue if isInSquad triggered on true
isInSquad.subscribe(function(v) {
  if (v && isInQueue.value)
    leave()
})
//leave queue if squadMembers list changed
squadMembers.subscribe(function(v) {
  if (isInQueue.value)
    leave()
})

return {
  NOT_IN_QUEUE = STATUS.NOT_IN_QUEUE
  JOINING = STATUS.JOINING
  IN_QUEUE = STATUS.IN_QUEUE

  joinQueue = join
  leaveQueue = leave

  isInQueue
  maxSquadSize
  selectedQueue
  selectQueue
  startQueueTime
  queueInfo
  matchingTeam
  timeInQueue
  queueClusters
  matchRandomTeam
  canChangeQueueParams
}.__update(STATUS)
 