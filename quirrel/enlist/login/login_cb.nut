local {sound_play} = require("sound")
local auth  = require("auth")
local msgbox = require("enlist/components/msgbox.nut")
local urlText = require("enlist/components/urlText.nut")
local userInfo = require("enlist/state/userInfo.nut")
local remap_nick = require("globals/remap_nick.nut")
local loginActions = require("loginActions.nut")
local {exit_game} = require("enlist.app")
local decode_jwt = require("jwt").decode
local {ssoPublicKey} = require("sso_pubkey.nut")
local debug = require("std/log.nut")().with_prefix("[LOGIN_CB]")

local function onSuccess(state) {
  local authResult = state.stageResult.auth_result
  local token = authResult.token
  local jwt = authResult?.jwt
  local permissions = []
  if (jwt) {
    local decoded_jwt = decode_jwt(jwt, ssoPublicKey)
    if ("error" in decoded_jwt) {
      local resError = decoded_jwt["error"]
      debug($"Could not decode jwt token: {resError}. use Auth token")
    }
    else {
      debug($"Use Jwt token")
      token = jwt
      permissions = decoded_jwt?.payload?["perm"] ?? []
    }
  }
  else
    debug($"Use Auth token")

  userInfo.update({
    userId = authResult.userId
    userIdStr = authResult.userId.tostring()
    realName = authResult.name
    name = remap_nick(authResult.name)
    token = token
    tags = authResult?.tags ?? []
    permissions = permissions
    chardToken = state.stageResult?.char?.chard_token
  }.__update(state.userInfo))
  loginActions.value?.onAuthComplete?.filter(@(v) ::type(v)=="function")?.map(@(action) action())
}

local function getErrorText(state) {
  if (!(state.params?.needShowError(state) ?? true))
    return null
  if (!state.stageResult?.needShowError)
    return null
  if ((state?.status ?? auth.YU2_OK) != auth.YU2_OK)
    return "{0} {1}".subst(::loc("loginFailed/authError"), ::loc(state.stageResult.error))
  if ((state.stageResult?.char?.success ?? true) != true)
    return "{0} {1}".subst(::loc("loginFailed/profileError"), ::loc($"error/{state.stageResult.char.error}"))
  local errorId = state.stageResult?.error
  if (errorId != null)
    return ::loc(errorId)
  return null
}

local function showStageErrorMsgBox(errText, state, mkChildren = @(defChild) defChild) {
  local afterErrorProcessed = state.params?.afterErrorProcessed
  if (errText == null) {
    afterErrorProcessed?(state)
    return
  }

  local urlObj = null
  if (state.stageResult?.errorWithLink ?? false) {
    local linkUrl = ::loc($"{state.stageResult.error}/link/url")
    local linkText = ::loc($"{state.stageResult.error}/link/text")
    if (linkUrl != "" && linkText != "") {
      urlObj = urlText(linkText, linkUrl)
    }
  }


  sound_play("ui/enlist/login_fail")
  local msgboxParams = {
    text = errText,
    onClose = @() afterErrorProcessed?(state),
    children = mkChildren(urlObj)
  }

  if (state.stageResult?.quitBtn ?? false) {
    msgboxParams.buttons <- [
      {
        text = ::loc("mainmenu/btnClose")
      },
      {
        text = ::loc("gamemenu/btnQuit")
        action = exit_game
        isCurrent = true
      }
    ]
  }

  msgbox.show(msgboxParams)
}

local onInterrupt = @(state) showStageErrorMsgBox(getErrorText(state), state)

return {
  onSuccess = onSuccess
  onInterrupt = onInterrupt
  showStageErrorMsgBox = showStageErrorMsgBox
}
 