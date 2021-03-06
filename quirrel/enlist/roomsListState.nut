local matchingCli = require("matchingClient.nut")
local math = require("math")
local matching_errors = require("matching.errors")
local localSettings = require("options/localSettings.nut")("roomsListState/")
local {get_game_name, get_app_id} = require("app")

local debugMode = persist("debugMode", @() Watched(false))
local roomsList = persist("roomsList", @() Watched([]))
local isRequestInProgress = persist("isRequestInProgress", @() Watched(false))
local curError = Watched(null)
local showForeignGames = localSettings(false, "showForeignGames")

local lobbyEnabled = Watched(true)

local function listRoomsCb(response) {
  isRequestInProgress.update(false)
  if (debugMode.value)
    return
  if (response.error) {
    curError.update(matching_errors.error_string(response.error))
    roomsList.update([])
  } else {
    curError.update(null)
    roomsList.update(response.digest)
  }
}

local function updateListRooms(){
  if (isRequestInProgress.value || !lobbyEnabled)
    return

  local params = {
    group = "custom-lobby"
    cursor = 0
    count = 100
    filter = {
      ["public/gameName"] = {
        test = "eq"
        value = get_game_name()
      },
      ["membersCnt"] = {
        test = "gr"
        value = 0
      }
    }
  }
  if (!showForeignGames.value) {
    params.filter["public/appId"] <- {
      test = "eq"
      value = get_app_id()
    }
  }

  matchingCli.netStateCall(function() {
    isRequestInProgress.update(true)
    matchingCli.call("mrooms.fetch_rooms_digest2", listRoomsCb.bindenv(this), params)
  }.bindenv(this))
}

local refreshPeriod = persist("refreshPeriod",@() Watched(5.0))
local refreshEnabled = persist("refreshEnabled",@() Watched(false))
local wasRefreshEnabled = false
local function toggleRefresh(val){
  if (!wasRefreshEnabled && val)
    updateListRooms()
  if(val)
    ::gui_scene.setInterval(refreshPeriod.value, updateListRooms)
  else
    ::gui_scene.clearTimer(updateListRooms)
  wasRefreshEnabled = val
}
refreshEnabled.subscribe(toggleRefresh)
refreshPeriod.subscribe(@(v) toggleRefresh(refreshEnabled.value))

local function switchDebugMode() {
  local function debugRooms() {
    local list = ::array(100).map(@(_) {
        roomId = math.rand()
        membersCnt = 2 + math.rand() % 25
        public = {
          creator = "%Username%{0}".subst(math.rand()%11)
          hasPassword = !(math.rand()%3)
        }
      }
    )
    roomsList.update(list)
  }
  debugMode.update(!debugMode.value)
  if (debugMode.value){
    refreshEnabled.update(false)
    debugRooms()
  }
  else{
    refreshEnabled.update(true)
  }
}

console.register_command(switchDebugMode, "rooms.switchDebugMode")

return {
  lobbyEnabled = lobbyEnabled
  showForeignGames = showForeignGames
  list = roomsList
  error = curError
  isRequestInProgress = isRequestInProgress
  refreshPeriod = refreshPeriod
  refreshEnabled = refreshEnabled
  _manualRefresh = updateListRooms
}
 