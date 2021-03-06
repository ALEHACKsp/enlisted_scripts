local charactions = require("charactions")
local {get_game_name, get_app_id} = require("app")

local dedicated = require_optional("dedicated")
if (dedicated == null)
  return

local char = require("char")
local {CmdGetUserstats} = require("gameevents")

local {INVALID_USER_ID} = require("matching.errors")


local function onCmdGetUserStats(evt, eid, comp) {
  if (comp.userid == INVALID_USER_ID)
    return

  local request = {
    headers = {
      userid = comp.userid,
      game = get_game_name(),
      appid = get_app_id()
    },
    action = "hst_get_chat_data"
  }


  ::log("request hst_get_chat_data", comp.userid, get_app_id())

  char.request(request, function(result) {
    if (result) {
      local bestPenalty = result?.bestPenalty ?? ""

      local errorMsg = result?.error
      if (errorMsg)
        ::log("hst_get_chat_data of", comp.userid, "returns error", errorMsg)

      ::log("bestPenalty of", comp.userid, "is", bestPenalty)

      ::ecs.set_comp_val(eid, "ban_status", bestPenalty)
    }
    else {
      ::ecs.set_comp_val(eid, "ban_status", "")
      ::log("hst_get_chat_data return NO result")
    }
  })
}



::ecs.register_es("contacts_es", {
    [CmdGetUserstats] = onCmdGetUserStats,
  },
  {
    comps_rw = [
      ["ban_status", ::ecs.TYPE_STRING]
    ]
    comps_ro = [
      ["userid", ::ecs.TYPE_INT64]
    ]
  },
  {tags = "server"}
)


local function CmdSendComplaint(evt, eid, comp) {

  if (comp.userid == INVALID_USER_ID)
    return

  local offender_userid = evt[0]
  local category = evt[1]
  local user_comment = evt[2]
  local details_json = evt[3]
  local chat_log = evt[4]
  local lang = evt[5]


  ::log("CmdSendComplaint", comp.userid, get_app_id(), offender_userid,
        category, user_comment, details_json, chat_log, lang)

  local matchingModeInfo = dedicated.get_matching_mode_info()
  local sessionId = matchingModeInfo?.sessionId ?? 0

  local request = {
    headers = {
      userid = comp.userid,
      appid = get_app_id(),
    },
    data = {
      offender_userid = offender_userid,
      room_id = sessionId,
      category = category,
      lang = lang,
      user_comment = user_comment,
      chat_log = chat_log,
      details_json = details_json
    },
    action = "hst_complaint"
  }


  char.request(request, function(result) {
    if (result) {

      local errorMsg = result?.result?.error
      if (errorMsg)
        ::log("hst_complaint for", comp.userid, "returns error", errorMsg)
    }
    else {
      ::log("hst_complaint return NO result")
    }
  })
}


::ecs.register_es("complaints_es", {
  [charactions.CmdSendComplaint] = CmdSendComplaint }, {
    comps_ro = [ ["userid", ::ecs.TYPE_INT64] ] })

 