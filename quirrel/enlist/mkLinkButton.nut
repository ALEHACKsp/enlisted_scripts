local {isOpenSteamLinkUrlInProgress, isSteamLinked, openSteamLinkUrl} = require("enlist/state/steamState.nut")
local textButton = require("enlist/components/textButton.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local colors = require("ui/style/colors.nut")

local function steamLinkBtn() {
  local res = { watch = [isSteamLinked, isOpenSteamLinkUrlInProgress] }
  if (isSteamLinked.value)
    return res

  return res.__update({
    vplace = ALIGN_CENTER
    children = isOpenSteamLinkUrlInProgress.value
      ? {
          key = "openSteamLinkInProgress"
          rendObj = ROBJ_STEXT
          validateStaticText = false
          font = Fonts.fontawesome
          color = colors.TextDefault
          text = fa["spinner"]
          size = [fontH(100),fontH(100)]
          transform = {}
          animations = [
            { prop=AnimProp.rotate, from = 0, to = 360, duration = 1, play = true, loop = true, easing=Discrete8 }
          ]
        }
      : textButton(::loc("gamemenu/btnLinkAccount"), openSteamLinkUrl, { skipDirPadNav = true })
  })
}

return steamLinkBtn
 