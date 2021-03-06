local json = require("json")
local io = require("io")
local { decode } = require("jwt")
local ipc_hub = require("ui/ipc_hub.nut")
local { playerSelectedSquads, allAvailableArmies } = require("enlisted/enlist/soldiers/model/state.nut")
local dagorDebug = require("dagor.debug")
local client = require("enlisted/enlist/meta/clientApi.nut")
local {profilePublicKey} = require("enlisted/game/data/profile_pubkey.nut")

local function requestProfileDataJwt(armies, cb) {
  if (armies.len() <= 0)
    return
  local armiesToCurSquad = {}
  foreach(armyId in armies)
    armiesToCurSquad[armyId] <- playerSelectedSquads.value?[armyId] ?? ""

  local cbWrapper = function(data) {
    local jwt = data?.jwt ?? ""
    local res = decode(jwt, profilePublicKey)
    if ("error" in res)
      cb(jwt, res)
    else
      cb(jwt, res?.payload.armies ?? {})
  }

  client.get_profile_data_jwt(armiesToCurSquad, cbWrapper)
}

local function splitStringBySize(str, maxSize) {
  ::assert(maxSize > 0)
  local result = []
  local start = 0
  local len = str.len()
  while (start < len) {
    local pieceSize = min(len - start, maxSize)
    result.append(str.slice(start, start + pieceSize))
    start += pieceSize
  }
  return result
}

local function send(playerEid, teamArmy) {
  requestProfileDataJwt([teamArmy], function(jwt, data) {
    ::ecs.client_send_event(playerEid, ::ecs.event.CmdProfileJwtData({ jwt = splitStringBySize(jwt, 4096) }))
    ipc_hub.send({ msg = "updateArmiesData", data = data })
  })
}

local function saveToFile(teamArmy = null) {
  local cb = function(jwt, data) {
    local fileName = "sendArmiesDataNew.json"
    local file = io.file(fileName, "wt+")
    file.writestring(json.to_string(data, true))
    file.close()
    log($"Saved json payload to {fileName}")
    fileName = "sendProfileDataNew.jwt"
    file = io.file(fileName, "wt+")
    file.writestring(jwt)
    file.close()
    log($"Saved jwt to {fileName}")
  }
  if (teamArmy == null) {
    local requestArmies = []
    foreach (armies in allAvailableArmies.value)
      requestArmies.extend(armies)
    requestProfileDataJwt(requestArmies, cb)
  }
  else
    requestProfileDataJwt([teamArmy], cb)
}

ipc_hub.subscribe("requestArmiesData", @(msg) send(msg.playerEid, msg.army))

console.register_command(@(armyId) requestProfileDataJwt([armyId], @(jwt, data)
  ::log.debugTableData(data, { recursionLevel = 7, printFn = dagorDebug.debug }) ?? log("Done")),
  "profileData.debugArmyData")

console.register_command(@() saveToFile(), "profileData.profileToJson")

console.register_command(@() send(), "profileData.reload")

return {
  send = send
  saveToFile = saveToFile
} 