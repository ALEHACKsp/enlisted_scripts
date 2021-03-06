local cursors = require("ui/style/cursors.nut")
local { sound_play } = require("sound")
local { progressBar, txt } = require("enlisted/enlist/components/defcomps.nut")
local { mkSquadIcon } = require("enlisted/enlist/soldiers/components/squadsUiComps.nut")
local {
  gap, slotBaseSize, soldierLvlColor, smallPadding, activeTxtColor
} = require("enlisted/enlist/viewConst.nut")

local TIME_TO_NEXT_SQUAD = 0.5
local UNLOCK_ADD_EXP_TIME = 1.0

local colon = ::loc("ui/colon")

local squadIconStyle = {
  size = [hdpx(77), hdpx(77)]
  margin = [hdpx(3), 0, 0, 0]
}

local squadStatsCfg = [
  { stat = "expBonus", locId = "debriefing/squadBonusExp", toString = @(v) v > 0 ? $"+{100 * v}%" : "0%"},
  { stat = "exp", locId = "debriefing/expAdded" },
].map(@(s) { toString = @(v) v.tostring() }.__update(s))

local function mkSquadTooltipText(squad) {
  local textList = squadStatsCfg.map(@(s)
    "".concat(::loc(s.locId), colon, s.toString(squad?[s.stat] ?? 0)))
  return "\n".join(textList)
}

local mkShowAnim = @(duration) {
  prop = AnimProp.opacity, from = 1, to = 1, duration = duration,
  play = true, easing = InOutCubic, trigger = "content_anim"
}

local mkHideAnim = @(duration) {
  prop = AnimProp.opacity, from = 0, to = 0, duration = duration,
  play = true, easing = InOutCubic, trigger = "content_anim"
}

local function mkProgress(wasLevel, wasExp, addExp, toLevelExp, mkAppearAnimations, animDelay, onFinishCb) {
  local isNewLevel = wasExp + addExp >= toLevelExp
  if (toLevelExp <= 0)
    toLevelExp = wasExp + addExp
  return {
    size = flex()
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    onHover = @(on) cursors.tooltip.state(on
      ? "".concat(::loc("debriefing/expAdded"), colon, addExp) : null)
    children = [
      {
        size = flex()
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = [
          txt(::loc("levelInfo", { level = wasLevel + 1 })).__update({
            opacity = isNewLevel ? 0 : 1
            animations = isNewLevel ? [ mkShowAnim(animDelay + UNLOCK_ADD_EXP_TIME - 0.1) ] : null
          })
          isNewLevel
            ? txt(::loc("debriefing/new_level")).__update({
                font = Fonts.medium_text
                color = soldierLvlColor
                transform = {}
                animations = mkAppearAnimations(animDelay + UNLOCK_ADD_EXP_TIME, function() {
                  sound_play("ui/debriefing/squad_progression_appear")
                })
              })
            : null
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          progressBar({
            value = wasExp.tofloat() / toLevelExp
            addValue = addExp.tofloat() / toLevelExp
            color = Color(150,150,150)
            addValueAnimations = [
              { prop = AnimProp.scale, from = [0, 1], to = [0, 1], play = true,
                duration = animDelay, trigger = "content_anim" }
              { prop = AnimProp.scale, from = [0, 1], to = [1, 1], play = true,
                duration = UNLOCK_ADD_EXP_TIME, easing = OutCubic, delay = animDelay,
                onFinish = onFinishCb, trigger = "content_anim" }
            ]
          })
          isNewLevel
            ? {
                rendObj = ROBJ_SOLID
                size = flex()
                margin = [smallPadding, 0]
                color = soldierLvlColor
                animations = [ mkHideAnim(animDelay + UNLOCK_ADD_EXP_TIME) ]
              }
            : null
        ]
      }
    ]
  }
}

local SQUAD_CARD_PARAMS = {
  squad = null
  animDelay = 0
  mkAppearAnimations = @(delay) null
  onFinishCb = null
}

local function mkSquadProgress(p = SQUAD_CARD_PARAMS) {
  p = SQUAD_CARD_PARAMS.__merge(p)

  local res = { content = null, duration = 0 }
  local squad = p.squad
  if (squad == null)
    return res

  local animDelay = p.animDelay
  local hasNewLevel = squad.wasExp + squad.exp >= squad.toLevelExp
  return {
    content = {
      size = [slotBaseSize[0], SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = gap
      behavior = Behaviors.Button
      onHover = @(on) cursors.tooltip.state(on ? mkSquadTooltipText(squad) : null)
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = gap
        children = [
          mkSquadIcon(squad?.icon, squadIconStyle).__update({
            transform = {}
            animations = p.mkAppearAnimations(animDelay, @() sound_play("ui/debriefing/new_equip"))
          })
          {
            size = flex()
            children = [
              txt(::loc(squad.nameLocId)).__update({
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                size = flex()
                font = Fonts.small_text
                color = activeTxtColor
                transform = {}
                animations = p.mkAppearAnimations(animDelay + 0.1)
              })
              mkProgress(squad?.wasLevel ?? 1,
                         squad?.wasExp ?? 0,
                         squad?.exp ?? 0,
                         squad?.toLevelExp ?? 0,
                         p.mkAppearAnimations,
                         animDelay,
                         p.onFinishCb)
            ]
          }
        ]
      }
    }
    duration = TIME_TO_NEXT_SQUAD + (hasNewLevel ? UNLOCK_ADD_EXP_TIME : 0)
  }
}

return mkSquadProgress
 