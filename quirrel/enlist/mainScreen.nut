local userInfo = require("enlist/state/userInfo.nut")
local {scenesList} = require("navState.nut")

local {mainMenuWatchedComp} = require("enlist/mainMenu/mainMenuComp.nut")

local notLoggedInText = {
  rendObj = ROBJ_DTEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  font = Fonts.big_text
  text = ::loc("Error: not logged in")
}

local function mainScreen() {
  local children = scenesList.value.len() > 0
    ? scenesList.value.top()
    : userInfo.value==null
      ? notLoggedInText
      : mainMenuWatchedComp.value?.comp

  return {
    watch = [userInfo, scenesList, mainMenuWatchedComp]
    size = [sw(100), sh(100)]

    children = children
  }
}

return mainScreen
 