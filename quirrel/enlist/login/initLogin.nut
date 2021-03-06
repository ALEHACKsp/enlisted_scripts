local platform = require("globals/platform.nut")
local currentLoginUi = require("currentLoginUi.nut")
local { setStagesConfig, isStagesInited } = require("login_chain.nut")
local { disableNetwork, linkSteamAccount } = require("login_state.nut")
local { get_arg_value_by_name } = require("dagor.system")
local { dd_file_exist } = require("dagor.fs")

if (!isStagesInited.value)
  setStagesConfig(require("defaultLoginStages.nut"))

if (currentLoginUi.value.comp == null) { //when not set by game before
  local setComp = @(comp) currentLoginUi(@(v) v.comp = comp)

  if (disableNetwork)
    setComp(require("enlist/login/ui/fake.nut"))
  else if (platform.is_xbox)
    setComp(require("enlist/login/ui/xbox.nut"))
  else if (platform.is_sony)
    setComp(require("enlist/login/ui/ps4.nut"))
  else if (platform.is_nswitch)
    setComp(require("enlist/login/ui/nswitch.nut"))
  else {
    local steam = require("steam")
    local steamNoPasswd = "enlist/login/ui/steam.nut"
    local dmmNoPasswd = "enlist/login/ui/dmm.nut"
    local passwdScreen = "enlist/login/ui/go.nut"
    local dmmRequire = "enlist/login/ui/dmmRequire.nut"
    local isDMMLogin = get_arg_value_by_name("dmm_user_id") != null
    local isDMMDistr = dd_file_exist("dmm")

    local updatePcComp = function() {
      if (isDMMDistr && !isDMMLogin)
        setComp(require(dmmRequire))
      else if (isDMMLogin)
        setComp(require(dmmNoPasswd))
      else if (steam.is_running() && !linkSteamAccount.value)
        setComp(require(steamNoPasswd))
      else
        setComp(require(passwdScreen))
    }

    if (steam.is_running())
      linkSteamAccount.subscribe(@(_) updatePcComp())
    updatePcComp()
  }
}
 