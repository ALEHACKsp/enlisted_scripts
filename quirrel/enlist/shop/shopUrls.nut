local steam = require("steam")
local { isSteamRunning } = require("enlist/login/login_state.nut")
local { get_circuit_conf } = require("app")

local function getShopUrl() {
  if (!isSteamRunning.value)
    return get_circuit_conf()?.shopUrl
  local url = get_circuit_conf()?.shopUrlSteam
  return url ? url.subst({ appId = steam.get_app_id(), steamId = steam.get_my_id() }) : null
}

local function getUrlByGuid(guid) {
  local url  = isSteamRunning.value
    ? get_circuit_conf()?.shopGuidUrlSteam
    : get_circuit_conf()?.shopGuidUrl
  if (!url || !guid.len())
    return null
  local params = { guid = guid }
  if (isSteamRunning.value)
    params.__update({ appId = steam.get_app_id(), steamId = steam.get_my_id() })
  return url.subst(params)
}

return {
  getShopUrl
  getUrlByGuid
} 