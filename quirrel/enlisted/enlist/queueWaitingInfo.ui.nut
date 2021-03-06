local {secondsToStringLoc} = require("utils/time.nut")
local armyPackage = require("enlisted/enlist/soldiers/components/armyPackage.nut")
local textArea = require("ui/components/textarea.nut")
local spinner = require("enlist/components/spinner.nut")({height=::hdpx(80)})
local { WindowTransparent } = require("ui/style/colors.nut")
local cursors = require("ui/style/cursors.nut")
local { activeTitleTxtColor, titleTxtColor } = require("enlisted/enlist/viewConst.nut")
local { randTeamCheckbox } =require("enlisted/enlist/quickMatch.nut")
local { matchRandomTeam, selectedQueue, timeInQueue, queueInfo, isInQueue } = require("enlist/quickMatchQueue.nut")

local {
  allArmiesInfo
} = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")

local {
  curArmies_list, curArmy
} = require("enlisted/enlist/soldiers/model/state.nut")

const TIME_BEFORE_SHOW_QUEUE = 15

local defaultSize = [hdpx(480), hdpx(360)]
local defPosSize = {
  size = defaultSize
  pos = [ sw(50) - defaultSize[0] / 2, sh(80) - defaultSize[1] ]
}

local posSize = Watched(defPosSize)

local infoContainer = {
  valign = ALIGN_TOP
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  padding = hdpx(20)
  transform = {}
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
}

local function queueTitle() {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    watch = timeInQueue
    children = [
      textArea(::loc("queue/searching", {
        wait_time = secondsToStringLoc(timeInQueue.value  / 1000)
      }), { halign = ALIGN_CENTER })
    ]
  }
}
local maxMinPlayersAmount = Computed(@() (selectedQueue.value?.modes ?? []).reduce(@(res, val) (val?.minPlayers ?? 1) > res ? val : res, 1))
local queueContent = @() {
    watch = [queueInfo, timeInQueue]
    size = [flex(), SIZE_TO_CONTENT]
    children = (timeInQueue.value > TIME_BEFORE_SHOW_QUEUE && (queueInfo.value?.matched ?? 0) > 0)
    ? @(){
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        watch = [curArmies_list, curArmy, allArmiesInfo, matchRandomTeam, maxMinPlayersAmount]
        gap = {
          rendObj = ROBJ_DTEXT
          text = ::loc("mainmenu/versus_short")
          vplace = ALIGN_CENTER
          margin = hdpx(20)
          color = activeTitleTxtColor
        }
        halign = ALIGN_CENTER
        children = curArmies_list.value.map(@(army, idx) {
          rendObj = ROBJ_BOX
          borderWidth = matchRandomTeam.value ? 0 : [0, 0, army == curArmy.value ? 1 : 0, 0]
          fillColor = Color(10,10,10,10)
          size = [hdpx(150), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = hdpx(20)
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = [
            armyPackage.mkIcon(allArmiesInfo.value?[army].id),
            maxMinPlayersAmount.value < 2 ? null : textArea(queueInfo.value?.matchedByTeams[idx] ?? 0)
          ]
        })
      }
    : null
}

local mkRandomTeamContent = {
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      font = Fonts.small_text
      color = titleTxtColor
      text = ::loc("queue/join_any_team_hint")
    }
    randTeamCheckbox
  ]
}

return function queueWaitingInfo() {
  local pos = posSize.value.pos

  return !isInQueue.value ? {watch=[isInQueue]} : {
    fillColor = WindowTransparent
    borderRadius = hdpx(2)
    rendObj = ROBJ_WORLD_BLUR_PANEL
    moveResizeCursors = null
    size = SIZE_TO_CONTENT
    behavior = Behaviors.MoveResize
    cursor = cursors.normal
    stopHover = true

    watch = [ posSize, isInQueue]
    key = 1
    pos = pos
    onMoveResize = function(dx, dy, dw, dh) {
      local newPosSize = {size = defaultSize, pos = [
        ::clamp(pos[0] + dx, 0, sw(95) - defaultSize[0]),
        ::clamp(pos[1] + dy, 0, sh(90) - defaultSize[1])
      ]}
      posSize.update(newPosSize)
      return newPosSize
    }
    children = infoContainer.__merge({
      size = defaultSize
      gap = hdpx(20)
      valign = ALIGN_CENTER
      children = [
        queueTitle
        {
          size = flex()
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = spinner
        }
        queueContent
        mkRandomTeamContent
      ]
    })
  }
}
 