local userstat = require_optional("userstats")
if (userstat==null)
  return require("userstatSecondary.nut") //ui VM, receive all data by cross call instead of host

local log = require("std/log.nut")().with_prefix("[USERSTAT] ")
local string = require("std/string.nut")
local { debug } = require("dagor.debug")
local { debounce } = require("utils/timers.nut")
local userInfo = require("enlist/state/userInfo.nut")
local { get_time_msec } = require("dagor.time")
local {error_response_converter} = require("enlist/netUtils.nut")
local sharedWatched = require("globals/sharedWatched.nut")
local ipc_hub = require("ui/ipc_hub.nut")
local loginState = require("enlist/login/login_state.nut")
local matchingNotifications = require("enlist/state/matchingNotifications.nut")
local { get_app_id } = require("app")

local { appId, language } = require("enlist/state/clientState.nut")
local time = require("serverTime.nut")

const STATS_REQUEST_TIMEOUT = 45000
const STATS_UPDATE_INTERVAL = 300000 //unlocks progress update interval
const MAX_DELAY_FOR_MASSIVE_REQUEST_SEC = 300 //random delay up to this value when all player want the same config simultaneously.

local chardToken = keepref(Computed(@() userInfo.value?.token))
local userId = keepref(Computed(@() userInfo.value?.userId))

local receivedTime = persist("receivedTime", @() Watched(0))
local receiveTimeMsec = persist("receiveTimeMsec", @() Watched(0))
local needSyncSteamAchievements = false
local updateTime = @() receivedTime.value > 0 && time(receivedTime.value + (get_time_msec() - receiveTimeMsec.value) / 1000)
updateTime()
receivedTime.subscribe(@(t) updateTime())
::gui_scene.setInterval(1.0, updateTime)
userId.subscribe(@(v) needSyncSteamAchievements = loginState.isSteamRunning.value)

local errorLogMaxLen = 10
local errorLog = persist("errorLog", @() Watched([]))

local function checkError(actionId, result) {
  if (result?.error == null)
    return
  errorLog(function(l) {
    l.append({ action = actionId, result = result, time = get_time_msec() })
    if (l.len() > errorLogMaxLen)
      l.remove(0)
  })
}

local function doRequest(request, cb) {
  userstat.request(request, @(result) error_response_converter(cb, result))
}

local function syncSteamAchievements() {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value },
    action = "SyncUnlocksWithSteam"
  },
  @(result){}
  )
}

local function makeUpdatable(persistName, request, watches, defValue) {
  local data = sharedWatched($"userstat.{persistName}", @() defValue)
  local lastTime = sharedWatched($"userstat.{persistName}.lastTime", @() { request = 0, update = 0 })
  local isRequestInProgress = @() lastTime.value.request > lastTime.value.update
    && lastTime.value.request + STATS_REQUEST_TIMEOUT > get_time_msec()
  local canRefresh = @() !isRequestInProgress()
    && (!lastTime.value.update || (lastTime.value.update + STATS_UPDATE_INTERVAL < get_time_msec()))

  local function processResult(result, cb) {
    checkError(persistName, result)
    if (cb)
      cb(result)

    local timestamp = result?.response?.timestamp
    if (timestamp) {
      receiveTimeMsec((3 * get_time_msec() - lastTime.value.request) / 2)
      receivedTime(timestamp)
    }
    if (result?.error) {
      data(defValue)
      log($"Failed to update {persistName}")
      log(result)
      return
    }
    data(result?.response ?? defValue)

    if (needSyncSteamAchievements) {
      syncSteamAchievements()
      needSyncSteamAchievements = false
    }
  }

  local function prepareToRequest() {
    lastTime(@(v) v.request = get_time_msec())
  }

  local function refresh(cb = null) {
    if (!chardToken.value || appId.value < 0) {
      data.update(defValue)
      if (cb)
        cb({ error = "not logged in" })
      return
    }
    if (!canRefresh())
      return

    prepareToRequest()

    request(function(result){
      processResult(result, cb)
    })
  }

  local function forceRefresh(cb = null) {
    lastTime(@(v) v.__update({ update = 0, request = 0}))
    refresh(cb)
  }

  foreach(w in watches)
    w.subscribe(function(v) {
      lastTime(@(v) v.update = 0)
      data(defValue)
      forceRefresh()
    })

  if (lastTime.value.request > lastTime.value.update)
    forceRefresh()

  return {
    id = persistName
    data = data
    refresh = refresh
    forceRefresh = forceRefresh
    processResult = processResult
    prepareToRequest = prepareToRequest
    lastUpdateTime = ::Computed(@() lastTime.value.update)
  }
}


local descListUpdatable = makeUpdatable("GetUserStatDescList",
  @(cb) doRequest({
    headers = {
      appid = appId.value,
      token = chardToken.value,
      language = ::loc("steam/languageName", language.value.tolower())
    },
    action = "GetUserStatDescList"
  }, cb),
  [appId, chardToken, language],
  {})

local statsFilter = {
  //tables = [ "global" ]
  modes = [ "solo", "duo", "group" ]
  //stats  = [ "winRating", "killRating", "battles" ]
}

local statsUpdatable = makeUpdatable("GetStats",
  @(cb) doRequest({
      headers = {
        appid = appId.value,
        token = chardToken.value
      },
      action = "GetStats"
      data = statsFilter,
    }, cb),
  [appId, chardToken],
  {})

local unlocksUpdatable = makeUpdatable("GetUnlocks",
  @(cb) doRequest({
      headers = {
        appid = appId.value,
        token = chardToken.value
      },
      action = "GetUnlocks"
    }, cb),
  [appId, chardToken],
  {})

local lastMassiveRequestTime = persist("lastMassiveRequestTime", @() ::Watched(0))
local massiveRefresh = debounce(
  function(checkTime) {
    log("Massive update start")
    foreach(data in [statsUpdatable, descListUpdatable, unlocksUpdatable])
      if (data.lastUpdateTime.value < checkTime) {
        log($"Update {data.id}")
        data.forceRefresh()
      }
    lastMassiveRequestTime(checkTime)
  }, 0, MAX_DELAY_FOR_MASSIVE_REQUEST_SEC)

local nextMassiveUpdateTime = persist("nextMassiveUpdateTime", @() ::Watched(0))
statsUpdatable.data.subscribe(function(stats) {
  local nextUpdate = 0
  local curTime = time.value
  foreach(tbl in stats?.inactiveTables ?? {}) {
    local startsAt = tbl?["$startsAt"] ?? 0
    if (startsAt > curTime)
      nextUpdate = nextUpdate > 0 ? ::min(nextUpdate, startsAt) : startsAt
  }
  foreach(tbl in stats?.stats ?? {}) {
    local endsAt = tbl?["$endsAt"] ?? 0
    if (endsAt > curTime)
      nextUpdate = nextUpdate > 0 ? ::min(nextUpdate, endsAt) : endsAt
  }
  nextMassiveUpdateTime(nextUpdate)
})

local lastMassiveRequestQueued = persist("lastMassiveRequestQueued", @() ::Watched(0))
if (lastMassiveRequestQueued.value > lastMassiveRequestTime.value)
  massiveRefresh(lastMassiveRequestQueued.value) //if reload script while wait for the debounce
local function queueMassiveUpdate() {
  log("Queue massive update")
  lastMassiveRequestQueued(nextMassiveUpdateTime.value)
  massiveRefresh(nextMassiveUpdateTime.value)
}

local function startMassiveUpdateTimer() {
  if (nextMassiveUpdateTime.value <= lastMassiveRequestTime.value)
    return
  ::gui_scene.clearTimer(queueMassiveUpdate)
  ::gui_scene.setTimeout(nextMassiveUpdateTime.value - time.value, queueMassiveUpdate)
}
startMassiveUpdateTimer()
nextMassiveUpdateTime.subscribe(@(_) startMassiveUpdateTimer())

local function regeneratePersonalUnlocks(cb = null) {
  doRequest({
      headers = {
        appid = appId.value,
        token = chardToken.value
      },
      action = "RegeneratePersonalUnlocks"
    },
    function(result) {
      if (cb)
        cb(result)
      if (result?.error)
        return
      unlocksUpdatable.forceRefresh()
      statsUpdatable.forceRefresh()
    })
}

local function generatePersonalUnlocks(cb = null) {
  doRequest({
      headers = {
        appid = appId.value,
        token = chardToken.value
      },
      data = {
        table = "daily"
      },
      action = "GeneratePersonalUnlocks"
    },
    function(result) {
      if (cb)
        cb(result)
      if (!result?.error)
        unlocksUpdatable.forceRefresh()
    })
}

//config = { <unlockId> = <stage> }
local function setLastSeen(config) {
  doRequest({
    headers = {
      appid = appId.value,
      token = chardToken.value
    },
    data = config
    action = "SetLastSeenUnlocks"
  },
  function(result) {
    if (!result?.error)
      unlocksUpdatable.forceRefresh()
  })
}

local function receiveRewards(unlockName, stage, cb = null) {
  doRequest({
    headers = {
      appid = appId.value,
      token = chardToken.value
    },
    data = {
      unlock = unlockName
      stage = stage
    }
    action = "GrantRewards"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(cb)
    statsUpdatable.forceRefresh()
  })
}

local function resetPersonalUnlockProgress(unlockName, cb = null) {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value, userId = userId.value },
    data = { unlock = unlockName }
    action = "AdmResetPersonalUnlockProgress"
  },
  function(result) {
    if (cb)
      cb(result)
    if (!result?.error)
      unlocksUpdatable.forceRefresh()
  })
}

local function rerollUnlock(unlockName, cb = null) {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value },
    data = { unlock = unlockName }
    action = "RerollPersonalUnlock"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(cb)
    statsUpdatable.forceRefresh()
  })
}

local function selectUnlockRewards(unlockName, selectedArray, cb = null) {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value },
    data = { unlock = unlockName, selection = selectedArray }
    action = "SelectRewards"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(cb)
  })
}


local modeAvailable = @(mode) ["solo","duo","group"].indexof(mode)!=null //FIXME: list of avaialble modes should be get from matching, not by game!

local function changeStat(stat, mode, amount, shouldSet, cb = null) {
  local errorText = null
  if (typeof amount != "integer" && typeof amount != "float")
    errorText = $"Amount must be numeric (current = {amount})"
  else if (!statsUpdatable.data.value?.stats?["global"]?[mode] && !modeAvailable(mode))
    errorText = $"Mode {mode} does not exist"
  else if (descListUpdatable.data.value?.stats?[stat] == null) {
    errorText = $"Stat {stat} does not exist."
    local similar = []
    local parts = string.split(stat, "_", true)
    foreach(s, v in descListUpdatable.data.value?.stats ?? {})
      foreach(part in parts)
        if (s.indexof(part) != null) {
          similar.append(s)
          break
        }
    errorText = "\n".join([errorText, $"Similar stats: {" ".join(similar)}"], true)
  }

  if (errorText != null) {
    cb?({ error = errorText })
    return
  }

  doRequest({
      headers = {
        appid = appId.value,
        token = chardToken.value
        userId = userId.value
      },
      data = {
        [stat] = shouldSet ? { "$set": amount } : amount,
        ["$mode"] = mode
      }
      action = "ChangeStats"
    },
    function(result) {
      cb?(result)
      if (!result?.error) {
        unlocksUpdatable.forceRefresh()
        statsUpdatable.forceRefresh()
      }
    })
}


local function addStat(stat, mode, amount, cb = null) {
  changeStat(stat, mode, amount, false, cb)
}


local function setStat(stat, mode, amount, cb = null) {
  changeStat(stat, mode, amount, true, cb)
}


local function sendPsPlus(havePsPlus, token, cb = null) {
  local haveTxt = havePsPlus ? "present" : "absent"
  debug($"Sending PS+: {haveTxt}")
  doRequest({
      headers = {
        appid = get_app_id(),
        token = token
      },
      data = {
        ["have_ps_plus"] = havePsPlus ? true : false
      },
      action = "SetPsPlus"
    },
    function(result) {
      if (cb)
        cb({})
      if (result?.error)
        debug($"Failed to send PS+: {result.error}")
      else
        debug("Succesfully sent PS+")
    })
}


local function getStatsSum(tableName, statName) {
  local res = 0
  local tbl = statsUpdatable.data.value?.stats?[tableName]
  if (tbl)
    foreach(modeTbl in tbl)
      res += modeTbl?[statName] ?? 0
  return res
}


local function buyUnlock(unlockName, stage, currency, price, cb = null) {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value}
    data = { name = unlockName, stage = stage, price = price, currency = currency },
    action = "BuyUnlock"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(function(res) {
      statsUpdatable.forceRefresh(cb)
    })
  })
}

local function clnChangeStats(data, cb = null) {
  statsUpdatable.prepareToRequest()
  unlocksUpdatable.prepareToRequest()
  data["$filter"] <- statsFilter
  doRequest({
    headers = { appid = appId.value, token = chardToken.value}
    data = data
    action = "ClnChangeStats"
  },
  function(result) {
    statsUpdatable.processResult(result, cb)
    unlocksUpdatable.processResult(result, cb)
  })
}

local function clnAddStat(mode, stat, amount, cb = null) {
  local data = {
      [stat] = amount,
      ["$mode"] = mode
  }

  clnChangeStats(data, cb)
}

local function clnSetStat(mode, stat, amount, cb = null) {
  local statData = {
    ["$set"] = amount
  }

  local data = {
      [stat] = statData,
      ["$mode"] = mode
  }

  clnChangeStats(data, cb)
}

matchingNotifications.subscribe("userStat",
  @(ev) ev?.func == "updateConfig" ? queueMassiveUpdate() : unlocksUpdatable.forceRefresh())


console.register_command(@() descListUpdatable.forceRefresh(console_print), "userstat.get_desc_list")
console.register_command(@() ::log.debugTableData(descListUpdatable.data.value, { recursionLevel = 7, printFn = debug }) || print("Done"),
  "userstat.debug_desc_list")
console.register_command(@() statsUpdatable.forceRefresh(console_print), "userstat.get_stats")
console.register_command(@() ::log.debugTableData(statsUpdatable.data.value, { recursionLevel = 7, printFn = debug }) || print("Done"),
  "userstat.debug_stats")
console.register_command(@() unlocksUpdatable.forceRefresh(console_print), "userstat.get_unlocks")
console.register_command(@() regeneratePersonalUnlocks(console_print), "userstat.reset_personal")
console.register_command(@(unlockName) resetPersonalUnlockProgress(unlockName, console_print), "userstat.reset_unlock_progress")
console.register_command(@() generatePersonalUnlocks(console_print), "userstat.generate_personal")
console.register_command(@() ::log.debugTableData(unlocksUpdatable.data.value?.personalUnlocks, { recursionLevel = 7 }), "userstat.debug_personal")
console.register_command(@(stat, mode, amount) addStat(stat, mode, amount, console_print), "userstat.add_stat")
console.register_command(@(stat, mode, amount) setStat(stat, mode, amount, console_print), "userstat.set_stat")
console.register_command(@() syncSteamAchievements(), "userstat.sync_steam_achievements")
console.register_command(@(have_psplus) sendPsPlus(have_psplus, chardToken.value), "userstat.set_ps_plus")
console.register_command(@(mode, stat, amount) clnAddStat(mode, stat, amount, console_print), "userstat.cln_add_stat")
console.register_command(@(mode, stat, amount) clnSetStat(mode, stat, amount, console_print), "userstat.cln_set_stat")
console.register_command(@() nextMassiveUpdateTime(time.value + 1), "userstat.test_massive_update")
console.register_command(@(amount) addStat("monthly_challenges", "solo", amount, console_print), "unlocks.add")

local cmdList = {
  setLastSeenCmd = @(d) setLastSeen(d?.p ?? d)
  refreshStats = @(d = null) statsUpdatable.refresh()
  forceRefreshUnlocks = @(d = null) unlocksUpdatable.forceRefresh()
}

ipc_hub.subscribe("userstat.cmd", @(d) cmdList?[d.cmd]?(d))
local isUserstatFailedGetData = ::Computed(
    @() errorLog.value.len() > 0
      && (receiveTimeMsec.value <= 0 || errorLog.value.top().time > receiveTimeMsec.value))

return {
  buyUnlock,
  userstatStats = statsUpdatable.data
  userstatUnlocks = unlocksUpdatable.data
  userstatTime = time
  userstatDescList = descListUpdatable.data
  userstatErrorLog = errorLog
  userstatReceivedTime = receivedTime
  isUserstatFailedGetData
  setLastSeenUnlocks = setLastSeen
  getUserstatsSum = getStatsSum
  receiveUnlockRewards = receiveRewards
  setUserstat = clnSetStat
  sendPsPlusStatusToUserstatServer = sendPsPlus
  selectUnlockRewards = selectUnlockRewards
  rerollUnlock = rerollUnlock
  forceRefreshUnlocks = cmdList.forceRefreshUnlocks
  setLastSeenUnlocksCmd = cmdList.setLastSeenCmd
  refreshUserstats = cmdList.refreshStats
}
 