local {Watched} = require("frp")
local {get_game_name} = require("app")

local permissions = persist("permissions", @() Watched({})) //it is watched as we suppose to get it from server someday
local global_admins = [99298, 23, 177154, 1512469, 84365, 174556, 180326, 65282449, 43034050, 104669672, 78992476, 38777395, 95888162, 96216962, 96756945, 83231409, 78983890]

local default_permissions = {send_server_commands = false}
local all_permissions = default_permissions.map(@(v) true)
local global_permissions = {}
foreach(userid in global_admins)
  global_permissions[userid] <- all_permissions

local function updatePermissionsPerGame() {
  local resPermissions = clone global_permissions
  local perGamePermissions = require_optional("{0}/globals/client_permissions.nut".subst(get_game_name())) ?? {} //replace it with request to server
  default_permissions.__update(perGamePermissions?.DEFAULT ?? {})
  foreach (userid, userPermission in resPermissions)
    resPermissions[userid] = default_permissions.__merge(userPermission)
  foreach (userid, userPermission in perGamePermissions)
    resPermissions[userid] <- (resPermissions?[userid] ?? {}).__update(userPermission)
  permissions(resPermissions)
}
updatePermissionsPerGame()

return {
  permissions = permissions
  get_client_user_permissions = @(userid) permissions.value?[userid] ?? default_permissions
}
 