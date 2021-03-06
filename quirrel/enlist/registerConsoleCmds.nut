local matchingCli = require("matchingClient.nut")
local ipc = require("ipc")
local loginState = require("login/login_state.nut")
local { actionInProgress, controllerDisconnected } = require("globals/uistate.nut")
local checkReconnect = require("checkReconnect.nut")
local inspector = require("daRg/components/inspector.nut")
local msgbox = require("components/msgbox.nut")


local function test(val){
  if (val==1) {
    ::loc <- function(...) {
      local l = ::__loc.acall([null].extend(vargv))
      return l+l
    }
  } else
    ::loc<-::__loc
}

console.register_command(function(val) {test(val)}, "ui.localization_test")
console.register_command(@(locId) console_print($"String:{locId} is localized as:{::loc(locId)}"), "ui.loc")

console.register_command(@() matchingCli.disconnect(), "app.matching_disconnect")
console.register_command(@() matchingCli.startLogin(), "app.matching_connect")

console.register_command(function() { msgbox.show({ text = "Test messagebox" buttons = [{ text = "Yes" action=@()vlog("Yes")} { text = "No" action = @() vlog("no")} ]})}, "ui.test_msgbox2")
console.register_command(function() { msgbox.show({
   text = "Test messagebox" buttons = [{ text = "Yes" action=@()::vlog("yes")} { text = "No", action=@()vlog("No")} { text = "Cancel" action=@()vlog("Cancel")}]})}, "ui.test_msgbox3")
console.register_command(function() { msgbox.show({ text = "Test messagebox"})}, "ui.test_msgbox")

console.register_command(function(key, value) {
    matchingCli.call("mpresence.set_presence",
      function (response) {
        console_print(response)
      },
      {[key] = value}
    )
  },
  "mpresence.set_presence")

console.register_command(function() {
    matchingCli.call("mpresence.reload_contact_list",
      function (response) {
        console_print(response)
      })
    },
  "mpresence.reload_contact_list")

console.register_command(function() {
    matchingCli.call("mpresence.notify_friend_added",
    function (response) {
      console_print(response)
    })
  },
  "mpresence.notify_friend_added")

console.register_command(@(message) ipc.send(message), "ipc.send")

console.register_command(@() inspector.shown.update(!inspector.shown.value), "ui.inspector_enlist")

console.register_command(@() loginState.logOut(), "app.logout")
console.register_command(@() checkReconnect(), "app.check_reconnect")

console.register_command(@() controllerDisconnected(!controllerDisconnected.value), "ui.controllerDisconnected")
console.register_command(@() actionInProgress(!actionInProgress.value), "ui.actionInProgress")
 