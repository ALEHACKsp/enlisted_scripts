local {tostring_r} = require("std/string.nut")
local userInfo = require("enlist/state/userInfo.nut")
local lowLevelClient = "char" in getroottable() ? ::char : require("char")
local {get_app_id, get_game_name} = require("app")
local {get_setting_by_blk_path} = require("settings")

local function char_request(action, data, callback, auth_token = null) {
  auth_token = auth_token ?? userInfo.value?.token
  ::assert(auth_token != null, "No auth token provided for char request")
  local request = {
    headers = {token = auth_token, appid = get_app_id()},
    action = action
  }

  if (data) {
    request["data"] <- data
  }

  lowLevelClient.request(request, function(result) {
    if ("error" in result) {
      callback( { result = {
        success = false,
        error = result.error
      }})
    }
    else {
      callback(result)
    }
  })
}

local function char_host_request(action, userid, data, callback) {
  local request = {
    headers = {userid = userid},
    action = action
  }

  if (data) {
    request["data"] <- data
  }

  lowLevelClient.request(request, callback)
}


local function char_login(auth_token, user_cb) {

  local request = {
    game =  get_setting_by_blk_path("contactsGameId") ?? get_game_name()
  }

  char_request("cln_cs_login", request,
    function(result) {
      if ( typeof result != "table" ) {
        log("ERROR: invalid cln_cs_login result\n")
        user_cb({error = "INTERNAL_SERVER_ERROR"})
        return
      }

      if ("result" in result)
        result = result.result

      if ( "error" in result ) {
        log("ERROR: cln_cs_login result: {0}".subst(tostring_r(result)))
        user_cb(result)
        return
      }

      ::log("char_login performed for user")
      user_cb({ chard_token = result.chardToken })
    },
    auth_token)
}

local function perform_contact_action(action, request, params) {
  local onSuccessCb = params?.success
  local onFailureCb = params?.failure

  log("perform_contact_action", request)

  char_request(action, request, function(result) {
    log("char_request", result)

    local subResult = result?.result
    if (subResult != null)
      result = subResult

    // Failure only if its explicitly defined in result
    if ("success" in result && !result.success) {
      if (typeof onFailureCb == "function") {
        onFailureCb(result?.error)
      }
    } else {
      if (typeof onSuccessCb == "function") {
        onSuccessCb()
      }
      log("Ok")
    }
  })
}

local function perform_single_contact_action(request, params) {
  perform_contact_action("cln_change_single_contact_json", request, params)
}

local function contacts_add(id, params = {}) {
  local request = {
    friend = {
      add = [id]
    }
  }

  perform_single_contact_action(request, params)
}


local function contacts_remove(id, params = {}) {
  local request = {
    friend = {
      remove = [id]
    }
  }
  perform_single_contact_action(request, params)
}

local function perform_contacts_for_requestor(action, apprUid, group, params = {}, requestAddon = {}) {
  local request = {
    apprUid = apprUid
    groupName = group
  }
  perform_contact_action(action, request.__merge(requestAddon), params)
}

local function perform_contacts_for_approver(action, requestorUid, group, params = {}, requestAddon = {}) {
  local request = {
    requestorUid = requestorUid
    groupName = group
  }
  perform_contact_action(action, request.__merge(requestAddon), params)
}

local charClient = {
  low_level_client = lowLevelClient
  char_request = char_request
  char_host_request = char_host_request
  char_login = char_login
  perform_contacts_for_requestor = perform_contacts_for_requestor
  perform_contacts_for_approver = perform_contacts_for_approver
  contacts_add = contacts_add
  contacts_remove = contacts_remove
  perform_single_contact_action = perform_single_contact_action
  perform_contact_action = perform_contact_action

  function contacts_request_for_contact(id, group, params = {}) {
    perform_contacts_for_requestor("cln_request_for_contact", id, group, params)
  }

  function contacts_cancel_request(id, group, params = {}) {
    perform_contacts_for_requestor("cln_cancel_request_for_contact", id, group, params)
  }

  function contacts_approve_request(id, group, params = {}) {
    perform_contacts_for_approver("cln_approve_request_for_contact", id, group, params)
  }

  function contacts_break_approval_request(id, group, params = {}) {
    perform_contacts_for_approver("cln_break_approval_contact", id, group, params)
  }

  function contacts_reject_request(id, group, params = {}) {
    perform_contacts_for_approver("cln_reject_request_for_contact", id, group, params, {silent="on"})
  }

  function contacts_add_to_blacklist(id, group, params = {}) {
    perform_contacts_for_approver("cln_blacklist_request_for_contact", id, group, params)
  }

  function contacts_remove_from_blacklist(id, group, params = {}) {
    perform_contacts_for_approver("cln_remove_from_blacklist_for_contact", id, group, params)
  }

}

// console commands
local function contacts_get() {
  char_request("cln_get_contact_lists_ext", null, function(result) {
    log(result)
  })
}

local function leaderboard_get() {
  local request = {
    category = "relativePlayerPlace",
    valueType = "value_total",
    gameMode = "cuisine_royale_test"
    count = 10,
    start = 0
  }

  char_request("cln_get_leaderboard_json", request, function(result) {
    log(result)
  })
}

local function leaderboard_host_push() {
  local request = {
    nick = "__",
    data = {
      arcade = {
          each_player_session = 1,
          each_player_victories = 1,
          finalSessionCounter = 1,
          flyouts = 1,
          ground_spawn = 1,
          position = 1,
          relativePosition = 1000,
          time_pvp_played = 41
      }
    }
  }

  char_host_request("hst_leaderboard_player_set", 666, request, function(result) {
    if (result) {
      ::log("hst_leaderboard_player_set result", result)
    }
    else {
      ::log("Ok")
    }
  })
}


local function contacts_search(nick) {
  local request = {
    nick = nick
    max_count = 10
    ignore_case = true
  }

  char_request("cln_find_users_by_nick_prefix_json", request, function(result) {
    log("cln_find_users_by_nick_prefix_json result", result)
  })
}


console.register_command(contacts_get, "char.contacts_get")
console.register_command(contacts_add, "char.contacts_add")
console.register_command(contacts_search, "char.contacts_search")
console.register_command(leaderboard_get, "char.leaderboard_get")
console.register_command(leaderboard_host_push, "char.leaderboard_host_push")

return charClient
 