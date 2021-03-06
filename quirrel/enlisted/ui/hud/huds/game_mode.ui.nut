local fa = require("daRg/components/fontawesome.map.nut")
local style = require("ui/hud/style.nut")
local { visibleZoneGroups, whichTeamAttack } = require("enlisted/ui/hud/state/capZones.nut")
local { capzoneWidget, capzoneGap } = require("enlisted/ui/hud/components/capzone.nut")
local {
  myScore, enemyScore, myScoreBleed, myScoreBleedFast, enemyScoreBleed, enemyScoreBleedFast, myTeamFailTimer
} = require("enlisted/ui/hud/state/team_scores.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {secondsToHoursLoc} = require("utils/time.nut")
local {playerEvents} = require("ui/hud/state/eventlog.nut")
local {sound_play} = require("sound")

const GAP_RATIO = 0.4 // magic number calculated as gap/icon = (1 / 1.5) / (1 + 1 / 1.5)

local teamScoreBlink = @(trigger) [{ prop = AnimProp.opacity, from = 0.8, to = 1.0, trigger = trigger, easing = InCubic, duration = 0.5}]
local myTeamScoreBlinkAnim = teamScoreBlink("myTeamScoreChanged")
local enemyTeamScoreBlinkAnim = teamScoreBlink("enemyTeamScoreChanged")

myScore.subscribe(@(v) ::anim_start("myTeamScoreChanged"))
enemyScore.subscribe(@(v) ::anim_start("enemyTeamScoreChanged"))


local mkScoreTeam = @(params) function() {
  local score = params.score.value
  return {
    color = Color(200,100,10)
    size = [flex(), sh(0.5)]
    watch = params.score
    children = score != null
      ? {
          rendObj = ROBJ_PROGRESS_LINEAR
          size = flex()
          fgColor = params.fgColor
          bgColor = params.bgColor
          fValue = params.fValueMul * score
        }
      : null
    animations = params.anim
  }
}

local scoreTeam1 = mkScoreTeam({
  fgColor = style.TEAM0_COLOR_FG
  bgColor = style.TEAM0_COLOR_BG
  fValueMul = -1
  score = myScore
  anim = myTeamScoreBlinkAnim
})

local scoreTeam2 = mkScoreTeam({
  fgColor = style.TEAM1_COLOR_FG
  bgColor = style.TEAM1_COLOR_BG
  fValueMul = 1
  score = enemyScore
  anim = enemyTeamScoreBlinkAnim
})


local mkScoreBleed = @(params) @() {
  watch = [params.bleed, params.bleedFast]
  size = [SIZE_TO_CONTENT, ::hdpx(18)]
  valign = ALIGN_CENTER
  children = params.bleed.value
    ? {
        rendObj = ROBJ_STEXT
        fontSize = params.bleedFast.value ? ::hdpx(9) : ::hdpx(16)
        color = params.dirColor
        font = Fonts.fontawesome
        text = params.bleedFast.value ? params.dirFast : params.dirSlow
        validateStaticText = false
      }
    : null
}

local scoreBleedTeam1 = mkScoreBleed({
  bleed = myScoreBleed
  bleedFast = myScoreBleedFast
  dirColor = style.TEAM0_COLOR_FG
  dirSlow = fa["long-arrow-right"]
  dirFast = $"{fa["forward"]}{fa["forward"]}"
})

local scoreBleedTeam2 = mkScoreBleed({
  bleed = enemyScoreBleed
  bleedFast = enemyScoreBleedFast
  dirColor = style.TEAM1_COLOR_FG
  dirSlow = fa["long-arrow-left"]
  dirFast = $"{fa["backward"]}{fa["backward"]}"
})

local team1 = {
  flow = FLOW_VERTICAL
  halign = ALIGN_LEFT
  size = [flex(), sh(0.5)]
  children = [
    scoreTeam1
    scoreBleedTeam1
  ]
}

local team2 = {
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  size = [flex(), sh(0.5)]
  children = [
    scoreTeam2
    scoreBleedTeam2
  ]
}

local teamScores = {
  size = [sw(25), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    team1
    team2
  ]
}

local function capZonesBlock() {
  local groups = visibleZoneGroups.value
  local total = groups.reduce(@(res, g) res + g.len(), 0)
    + max(groups.len() - 1, 0) * GAP_RATIO
  local children = []
  local offset = 0.0
  foreach(idx, zList in groups) {
    if (idx != 0) {
      children.append(capzoneGap())
      offset += GAP_RATIO
    }
    foreach(zoneEid in zList) {
      children.append(
        capzoneWidget(zoneEid,
          {
            showDistance = false
            idx = offset
            total = total
          }))
      offset += 1.0
    }
  }

  return {
    watch = visibleZoneGroups
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    children = children
  }
}

local function failTimerBlock() {
  local timeIsRunningOut = myTeamFailTimer.value < 10
  return {
    watch = myTeamFailTimer
    margin = [hdpx(4), 0]
    children = myTeamFailTimer.value > 0
      ? {
          rendObj = ROBJ_DTEXT
          color = timeIsRunningOut ? Color(155, 0, 0, 95) : Color(155, 155, 155, 95)
          font = timeIsRunningOut ? Fonts.big_text : Fonts.medium_text
          text = secondsToHoursLoc(myTeamFailTimer.value)
        }
      : null
  }
}

local isMyTeamAttacking = ::Computed(@() localPlayerTeam.value == whichTeamAttack.value)

local attackerScoreWatch = ::Computed(function() {
  local score = isMyTeamAttacking.value ? myScore.value : enemyScore.value
  return score == null ? null : (1000.0 * score + 0.5).tointeger()
})

local function attackingTeamPoints() {
  local color = isMyTeamAttacking.value ? style.TEAM0_COLOR_FG : style.TEAM1_COLOR_FG
  return {
    watch = [isMyTeamAttacking, attackerScoreWatch]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_IMAGE
        image = ::Picture("ui/skin#initial_squad_size.svg:{0}:{0}:K".subst(::hdpx(32)))
        color = color
      }
      {
        rendObj = ROBJ_DTEXT
        size = [::hdpx(55), SIZE_TO_CONTENT]
        font = Fonts.medium_text
        text = attackerScoreWatch.value
        color = color
      }
    ]
  }
}

local modeDomination = {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = sh(1)
  children = [
    teamScores
    capZonesBlock
    failTimerBlock
  ]
}

local modeInvasion = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_TOP
  gap = sh(1)
  children = [
    attackingTeamPoints
    {
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      gap = sh(1)
      children = [capZonesBlock, failTimerBlock]
    }
  ]
}
local isDominationMode = Computed(@() whichTeamAttack.value < 0)

local defEvent = {text=::loc("The enemy's almost won!"), myTeamScores=false}
local defSound = "vo/ui/enlisted/narrator/loosing_scores_ally_domination"

local events = {
  showFailWarning = {
    watch = Computed(@() isDominationMode && (myScore.value < 0.2) && (myScoreBleed.value || myScoreBleedFast.value))
  }
  showFailFastWarning = {
    watch = Computed(@() isDominationMode && (myScore.value < 0.1) && (myScoreBleed.value || myScoreBleedFast.value))
  }
  showLowScore = {
    watch = Computed(@() isDominationMode && (myScore.value < 0.05))
  }
}
events.each(function(e){
  local {event=defEvent, sound = defSound, watch} = e
  keepref(watch)
  watch.subscribe(function(val) {
    if (val) {
      sound_play(sound)
      playerEvents.pushEvent(event)
    }
  })
})

local gameModeBlock = @() {
  watch = isDominationMode
  hplace = ALIGN_CENTER
  pos = [0, sh(3)]
  children = isDominationMode.value ? modeDomination : modeInvasion
}

return gameModeBlock 