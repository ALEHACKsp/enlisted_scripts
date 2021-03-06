  
       
                                       
  

local scrollbar = require("ui/components/scrollbar.nut")
local {formatText} = require("enlist/components/formatText.nut")
local {curPatchnote, chosePatchnote, versions, curVersionInfo} = require("changeLogState.nut")

local gap = ::hdpx(10)

local function patchnote(v) {
  local stateFlags = Watched(0)
  return @() {
    size = [flex(1), ::ph(100)]
    maxWidth = ::hdpx(300)
    behavior = [Behaviors.Button, Behaviors.TextArea]
    onClick = @() chosePatchnote(v)
    watch = [stateFlags, curPatchnote]
    onElemState = @(sf) stateFlags(sf)
    skipDirPadNav = false
    rendObj = ROBJ_TEXTAREA
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    color = stateFlags.value & S_HOVER
    ? Color(200,200,200)
    : curPatchnote.value == v
      ? Color(100,100,200)
      : Color(80,80,80)
    text = v?.title ?? v.tVersion
  }
}

local patchotes = @() {
  size = [flex(), ::ph(100)]
  flow = FLOW_HORIZONTAL
  gap = {
    rendObj = ROBJ_SOLID
    color = Color(80,80,80)
    size = [::hdpx(1), flex()]
    margin = [0, gap]
  }
  children = versions.map(patchnote)
}

local missedPatchnoteText = formatText([::loc("NoUpdateInfo", "Oops... No information yet :(")])

local seeMoreUrl = {
  t="url"
  platform="pc,ps4"
  url="https://enlisted.net/"
  v=::loc("visitGameSite", "See game website for more details")
  margin = [hdpx(50), 0, 0, 0]
}

local function selPatchnote(){
  local text = curVersionInfo.value ?? missedPatchnoteText
  if (::type(text)!="array")
    text = [text, seeMoreUrl]
  else
    text = (clone text).append(seeMoreUrl)
  return {
    rendObj = ROBJ_SOLID
    color = Color(10,10,10,10)
    watch = [curVersionInfo]
    children = scrollbar.makeVertScroll({
      size = [flex(), SIZE_TO_CONTENT]
      padding = gap
      children = formatText(text)
    })
    size = [sw(80), sh(70)]
  }
}

return {
  currentPatchnote = selPatchnote
  patchoteSelector = patchotes
}
 