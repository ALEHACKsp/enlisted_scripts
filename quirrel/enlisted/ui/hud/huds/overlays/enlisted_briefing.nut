local { missionName } = require("enlisted/ui/hud/state/mission_params.nut")
local briefingState = require("enlisted/ui/hud/state/briefingState.nut")
local {showBriefingForTime, showBriefing} = briefingState
local briefingStateBriefing = briefingState.briefing
local {localPlayerTeamInfo, localPlayerTeamIcon} = require("enlisted/ui/hud/state/teams.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local mkTeamIcon = require("enlisted/ui/hud/components/teamIcon.nut")
local {tokenizeTextWithShortcuts, makeHintsRows, controlView} = require("ui/hud/components/templateControls.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local JB = require("ui/control/gui_buttons.nut")
local textarea = require("daRg/components/textArea.nut")
local {dtext} = require("daRg/components/text.nut")
local {isAlive} = require("ui/hud/state/hero_state_es.nut")

local teamIcon = mkTeamIcon(localPlayerTeamIcon)
local showGoalAuto = Watched(false)
local showGoal = showBriefing

local function hideGoalAfterTime() {
  if ((showBriefingForTime.value ?? 0) > 0){
    showBriefingForTime(null)
    showGoalAuto(false)
    showGoal(false)
  }
}

showGoal.subscribe(function(v){
  if (v)
    return
  showGoalAuto(false)
  showBriefingForTime(null)
})

local function briefingText(briefing, teamInfo) {
  local team_briefing = teamInfo?["team.briefing"]
  if (team_briefing==null || team_briefing == "")
    team_briefing = briefing?["briefing_common"]
  return team_briefing
}

local function isBriefingEmpty(briefing, teamInfo){
  local team_briefing = briefingText(briefing, teamInfo)
  return ((team_briefing==null || team_briefing=="") && (briefing?.common == null || briefing?.common == ""))
}

local function setShow() {
  showGoalAuto(true)
  showGoal(true)
}

local hasGoals = Computed(@() !isBriefingEmpty(briefingStateBriefing.value, localPlayerTeamInfo.value))

showBriefingForTime.subscribe(function(value){
  if (value==null || value <=0)
    return
  if (!hasGoals.value)
    return
  ::gui_scene.clearTimer(setShow)
  ::gui_scene.clearTimer(hideGoalAfterTime)
  ::gui_scene.setTimeout(0.5, setShow)
  ::gui_scene.setTimeout(value+0.5, hideGoalAfterTime)
})

local showBrief = ::Computed(@() showGoal.value || showGoalAuto.value)

isAlive.subscribe(function(live){
  if(live)
    showGoal(false)
})
local lightgray = Color(180,180,180,180)

local hintSrcState = ::Computed(@() ::loc(briefingStateBriefing.value?.hints ?? ""))
local hintsTokensState = ::Computed(@() tokenizeTextWithShortcuts(hintSrcState.value))


local kbCloseKey = "Esc"
local gpCloseKey = JB.B
local closeMenuKey ="^{0} | {1}".subst(gpCloseKey, kbCloseKey)

local function closeHint() {
  local closeKey = controlView([isGamepad.value ? gpCloseKey : kbCloseKey])
  return closeKey!=null ? {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(10)
    children = [
      closeKey
      dtext(::loc("briefing/close"))
    ]
  } : null
}

local hintsBlock = @(hintsHeader, hintsTokens) @() {
  watch = isGamepad
  size = flex()
  color = lightgray
  flow = FLOW_VERTICAL
  gap = hdpx(2)
  children = [
    dtext(::loc(hintsHeader), { halign = ALIGN_CENTER, margin = [0, 0, sh(2), 0] })
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = ::hdpx(2)
      children = makeHintsRows(hintsTokens)
    }
  ]
}

local isEmpty = Computed(@() !hasGoals.value && !hintsTokensState.value.len())

local emptyBriefing = {
  size = flex()
  flow = FLOW_VERTICAL
  children = { size=flex() halign=ALIGN_CENTER valign=ALIGN_CENTER children=dtext(::loc("No briefing available")) }
}

local function goalsBriefing(){
  local briefing = briefingStateBriefing.value
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = sh(2)
    watch = [localPlayerTeamInfo, briefingStateBriefing]
    children = [
      {size = [flex(), SIZE_TO_CONTENT] flow=FLOW_HORIZONTAL valign=ALIGN_CENTER gap=sh(1)
        children = [
          teamIcon
          {size=flex() maxWidth=hdpx(10)}
          dtext(::loc(briefing?.header), { size = [flex(), SIZE_TO_CONTENT] font = Fonts.big_text})
          {size=flex()}
        ]
      },
      textarea(::loc(briefingText(briefing, localPlayerTeamInfo.value)), {font=Fonts.medium_text color=lightgray}),
      dtext(::loc(briefing?.common_header), {halign=ALIGN_CENTER font = Fonts.medium_text}),
      ::type(briefing?.common) == "string" ? textarea( ::loc(briefing.common), {font=Fonts.small_text, size=[flex(),sh(10)], halign=ALIGN_LEFT color=lightgray}) : null
    ]
  }
}
local mainBlock = @() {
  watch = [isEmpty, hasGoals]
  size = flex()
  children = isEmpty.value
    ? emptyBriefing
    : hasGoals.value
      ? goalsBriefing
      : null
}

local function briefingComp() {
  local briefing = briefingStateBriefing.value
  local hints = hintsTokensState.value.len() ? hintsBlock(briefing.hints_header, hintsTokensState.value) : null

  return {
    size = [sh(hasGoals ? 110 : 80), sh(72)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color (120,120,120,255)
    flow = FLOW_VERTICAL
    padding = [sh(2), sh(4)]
    gap = sh(2)
    hotkeys = [[closeMenuKey, @() showGoal.update(false)]]
    watch = [ hintsTokensState, hasGoals, briefingStateBriefing]
    halign = ALIGN_CENTER
    children = [
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        gap = sh(7)
        children = [
          mainBlock
          hints
        ]
      }
      closeHint
    ]
  }
}

local missionTitle = @(){
  rendObj = ROBJ_DTEXT
  text = ::loc(missionName.value)
  font = Fonts.huge_text
  pos = [-sh(10), 0]
  fontFxColor = Color(0, 0, 0, 180)
  fontFxFactor = min(64, hdpx(64))
  fontFx = FFT_GLOW
}

local titledBriefing = {
  flow = FLOW_VERTICAL
  gap = sh(2)
  children = [
    missionTitle
    briefingComp
  ]
}

local animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true, easing = OutQuintic }
  { prop = AnimProp.scale, from =[0.5, 0.5], play = true, to = [1, 1], duration = 0.15, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.15, playFadeOut = true, easing = InQuintic }
  { prop = AnimProp.scale, from =[1, 1], playFadeOut = true, to = [1.2, 1.2], duration = 0.15, easing = InQuad }
]

local function briefingUi() {
  return {
    key = "briefing"
    size = flex()
    halign = ALIGN_CENTER
    transform = {}
    animations = animations
    valign = ALIGN_CENTER
    children = showBrief.value ? titledBriefing : null
    watch = [localPlayerTeam, showBrief, briefingStateBriefing, localPlayerTeamInfo]
    hotkeys = [[closeMenuKey, {
        action = @() showGoal(false)
        description =::loc("Close")
        inputPassive = true
      }]]
  }
}

return briefingUi
 