local { txt } = require("enlisted/enlist/components/defcomps.nut")
local { secondsToStringLoc } = require("utils/time.nut")
local { premiumActiveTime, hasPremium } = require("premium.nut")
local {
  hasPremiumColor, defTxtColor
} = require("enlisted/enlist/viewConst.nut")


local premiumImagePath = @(size)
  "!ui/uiskin/currency/enlisted_prem.svg:{0}:{0}:K"
    .subst(size.tointeger())

local premiumImage = @(size, override = {}) @() {
  watch = hasPremium
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = ::Picture(premiumImagePath(size))
  color = hasPremium.value ? Color(255,255,255) : Color(120,120,120)
}.__update(override)


local premiumActiveInfo = @(customStyle = {}) function() {
  local activeTime = premiumActiveTime.value
  return txt({
    watch = premiumActiveTime
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color = activeTime > 0 ? hasPremiumColor : defTxtColor
    text = activeTime > 0
      ? ::loc("premium/activatedInfo", {
          timeInfo = secondsToStringLoc(activeTime)
        })
      : ::loc("premium/notActivated")
  }).__update(customStyle)
}

return {
  premiumImage = premiumImage
  premiumActiveInfo = premiumActiveInfo
}
 