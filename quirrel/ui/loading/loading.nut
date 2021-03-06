local {verPadding} = require("globals/safeArea.nut")
local {levelIsLoading, dbgLoading} = require("ui/hud/state/appState.nut")
local {mkAnimatedEllipsis} = require("loadingComponents.nut")

local color = Color(160,160,160,160)

local fontSize = hdpx(25)
local animatedEllipsis = mkAnimatedEllipsis(fontSize, color)

local animatedLoading = @(){
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  watch = verPadding
  valign = ALIGN_CENTER
  pos = [-sh(7),-verPadding.value-sh(3)]
  children = [
    {
      rendObj = ROBJ_STEXT
      text = ::loc("Loading")
      fontSize = fontSize
      color = color
    }
    {size=[hdpx(4),0]}
    animatedEllipsis
  ]
}

local simpleLoading = {
  size = flex()
  children = animatedLoading
}

local loadingComp = Watched(simpleLoading) //maybe it is better to have default loading null
local loadingUI = Computed(@() (levelIsLoading.value || dbgLoading.value) ? loadingComp.value : null)

return {loadingUI, loadingComp}
 