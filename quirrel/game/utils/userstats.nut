local string = require("string")
local message_queue = require_optional("message_queue")
local sys = require("dagor.system")
local {get_time_msec} = require("dagor.time")
local workcycle = require_optional("dagor.workcycle")
local delayedActs = null
local {INVALID_USER_ID} = require("matching.errors")
local { get_app_id, get_circuit } = require("app")

if (workcycle)
  delayedActs = require("utils/delayedActions.nut")

local tubeName = sys.get_arg_value_by_name("userstat_tube") ?? "userstat"
::print($"userstat_tube: {tubeName}")

local tubeNameV2 = sys.get_arg_value_by_name("userstat_tube_v2") ?? ""
if ((tubeNameV2 ?? "") != "")
  ::print($"userstat_tube_v2: {tubeNameV2}")

local appid = get_app_id()
::print($"userstats appid:{appid}")

local cachedStats = {}

local flushTime = (sys.get_arg_value_by_name("userstat_flush_stats_time_msec") ?? "3000").tointeger()
::print($"userstats flush time:{flushTime}")

local bulkSend = (sys.get_arg_value_by_name("userstat_bulk_send") ?? "1").tointeger() > 0
::print($"userstats bulk send:{bulkSend}")

if (bulkSend && !delayedActs){
  bulkSend = false
  ::print("userstat - disable bulk send due no delayed actions")
}

local isPackSupportOnCircuit = ["moon", "sun"].indexof(get_circuit())!=null
if (!isPackSupportOnCircuit)
  ::print($"userstats packs not allowed for this circuit")

local packStats = isPackSupportOnCircuit && bulkSend &&
                  (sys.get_arg_value_by_name("userstat_pack_send") ?? "1").tointeger() > 0
::print($"userstats packs send:{packStats}")

local function putToQueue(userid, sessionId, stats){
  if (sessionId != null && sessionId != 0)
    stats["$sessionId"] <- string.format("%X", sessionId)

  if (bulkSend){ // reduce spam in per stat mode
    ::print($"userstat - send stats userid:{userid}")
    ::debugTableData(stats)
  }

  if ((tubeNameV2 ?? "") != "") {
    local transactid = message_queue.gen_transactid()
    message_queue.put_raw(tubeNameV2, {
      action = "ChangeStats",
      headers = {
        userid = userid,
        appid = appid,
        transactid = transactid
      },
      body = stats
    })
  } else {
    message_queue.put(tubeName, {userid = userid, appid = appid, stats = stats})
  }
}

local function sendCacheData(userid){
  local userStats = cachedStats?[userid]
  if (userStats){
    if (packStats){
      local packed = {}
      packed["$bulk"] <- userStats.packs
      putToQueue(userid,
        userStats.sessionId,
        packed)
    } else {
      foreach (statVal in userStats.packs){
        putToQueue(userid,
          userStats.sessionId,
          statVal)
      }
    }
    userStats.packs.clear()
  }
}

local function flushStats(userid){
  sendCacheData(userid)
  if (userid in cachedStats)
    delete cachedStats[userid]
}

local function get_next_send_time(){
  return get_time_msec() + flushTime
}

local function hasDuplicateCommands(storedStats, newStats){
  foreach (statName, statVal in newStats){
    if (typeof statVal == "table" && (statName in storedStats)){
      return true
    }
  }
  return false
}

local function addStatsPack(mode, packs){
  local newPack = {}
  newPack["$mode"] <- mode

  packs.append(newPack)

  return newPack
}

local function putToCache(userid, stats, mode, sessionId) {
  local userStats = cachedStats?[userid]
  if (!userStats){
    userStats = {packs = [], sessionId = sessionId, time = get_next_send_time()}
    cachedStats[userid] <- userStats
  }

  if (sessionId != null && userStats.sessionId != sessionId){
    sendCacheData(userid)
    userStats.sessionId = sessionId
    userStats.time = get_next_send_time()
  }

  if (!userStats.packs.len())
    addStatsPack(mode, userStats.packs)

  local curPack = userStats.packs.top(); // last element
  if (curPack["$mode"] != mode || hasDuplicateCommands(curPack, stats)){
    if (!packStats){
      sendCacheData(userid);
      userStats.time = get_next_send_time()
    }
    curPack = addStatsPack(mode, userStats.packs)
  }

  foreach (statName, statVal in stats){
    if (statName in curPack){
      curPack[statName] += statVal
    }
    else{
      curPack[statName] <- statVal
    }
  }
}

local isSendScheduled = false

local function scheduleSend(time, cb){
  if (!isSendScheduled){
    isSendScheduled = true
    delayedActs.add(
      function(){
        isSendScheduled = false
        cb()
      },
      time + 200) // add delay 200 ms to guaranteed call send stats in first iteration
  }
}

local function sendAll(){
  local curTime = get_time_msec()
  local nextTime = flushTime
  local sent = []

  foreach (userid, stats in cachedStats){
    if (stats.time <= curTime){
      sendCacheData(userid)
      sent.append(userid)
    }
    else{
      nextTime = ::min(nextTime, stats.time - curTime)
    }
  }

  foreach (userid in sent)
    delete cachedStats[userid]

  if (cachedStats.len() > 0){
    scheduleSend(nextTime, sendAll)
  }
}

local function onAddStat(){
  scheduleSend(flushTime, sendAll)
}

local function sendToUserstats(userid, stats, mode, sessionId = null) {
  if (!message_queue || appid == 0 || mode == "" || !mode)
    return

  if (!bulkSend){
    stats["$mode"] <- mode
    putToQueue(userid, sessionId, stats)
    return
  }

  putToCache(userid, stats, mode, sessionId)

  onAddStat()
}

local function addUserstat(playerstats, playerstats_mode, name, params) {
  if (name in playerstats.getAll())
    playerstats[name] = playerstats[name] + 1
  else
    playerstats[name] <- 1

  if (params && (params?.mode ?? "") != "") {
    local modeKey = $"{name}_{params.mode}"
    if (modeKey in playerstats_mode.getAll())
      playerstats_mode[modeKey] = playerstats_mode[modeKey] + 1
    else
      playerstats_mode[modeKey] <- 1
  }

  if (params && "userid" in params && "mode" in params && params.userid != INVALID_USER_ID) {
    local stats = {}
    stats[name] <- 1
    sendToUserstats(params.userid, stats, params.mode)
  }
}

return {
  userstatsSend = sendToUserstats
  userstatsFlush = flushStats
  appid = appid
  userstatsAdd = addUserstat
}
 