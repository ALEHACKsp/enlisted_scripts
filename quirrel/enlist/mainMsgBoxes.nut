local {exit_game} = require("enlist.app")
local msgbox = require("enlist/components/msgbox.nut")
local login = require("login/login_state.nut")

local function exitGameMsgBox () {
  msgbox.show({
    text = ::loc("msgboxtext/exitGame")
    buttons = [
      { text = ::loc("Yes"), action = exit_game}
      { text = ::loc("No"), isCurrent = true }
    ]
  })
}
local function logoutMsgBox(){
  msgbox.show({
    text = ::loc("msgboxtext/logout")
    buttons = [
      { text = ::loc("Cancel"), isCurrent = true }
      { text = ::loc("Signout"), action = function() {
        login.logOut()
      }}
    ]
  })
}
return {
  exitGameMsgBox = exitGameMsgBox
  logoutMsgBox = logoutMsgBox
}
 