local {tooltip} = require("ui/style/cursors.nut")

local COUNT_VALUE_DELAY = 0.05

local function awardText(award) {
  local text = award?.id
    ? ::loc($"debriefing/awards/{award.id}/short", "")
    : ""
  return text.len()
    ? {
        rendObj = ROBJ_DTEXT
        size = [flex(), SIZE_TO_CONTENT]
        font = Fonts.small_text
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        text = text
      }
    : null
}

local awardValue = @(awardWatch) @() {
  watch = awardWatch
  rendObj = ROBJ_DTEXT
  font = Fonts.big_text
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  text = awardWatch.value ?? ""
}

local function mkCountTimersData(award, hasAnim) {
  local value = award?.value
  local canCount = hasAnim && (typeof value == "integer" || typeof value == "float")
  if (!canCount)
    return {
      curVal = Watched(value)
      countTimer = @() null
    }
  local curVal = Watched("")
  local current = 0.0
  local target = value.tointeger()
  local function countTimer() {
    local step = max((2 * target - current) / 30.0, target / 50.0)
    current = min(current + step, target)
    curVal(current.tointeger().tostring())
    if (current < target)
      ::gui_scene.setTimeout(COUNT_VALUE_DELAY, countTimer)
  }
  return {
    curVal = curVal
    countTimer = countTimer
  }
}

local mkStdAward = @(imagesList) ::kwarg(function(award, size = flex(), hasAnim = true,
  pauseTooltip = Watched(false), countDelay = 0) {
  local countTimersData = mkCountTimersData(award, hasAnim)
  local wrapCompleteFlag = false
  return {
    size = size
    behavior = Behaviors.Button
    onHover = @(on) tooltip.state(on && !pauseTooltip.value
      ? ::loc($"debriefing/awards/{award.id}")
      : null)
    onAttach = function() {
      if (!wrapCompleteFlag) {
        wrapCompleteFlag = true
        ::gui_scene.setTimeout(COUNT_VALUE_DELAY + countDelay, countTimersData.countTimer)
      }
    }
    children = imagesList.map(@(img) {
      rendObj = ROBJ_IMAGE
      size = flex()
      keepAspect = true
      image = ::Picture(img)
    }).append(
      awardText(award)
      awardValue(countTimersData.curVal)
    )
  }
})

local mkDefaultAward = mkStdAward(["ui/skin#awards/award_bg_shield_bronse.png"])

local awardsCfg = {
  kill = mkStdAward(["ui/skin#awards/award_bg_badge_ultra_silver.png", "ui/skin#awards/kill_silver.png"])
  tankKill = mkStdAward(["ui/skin#awards/award_bg_badge_ultra_silver.png"])
  planeKill = mkStdAward(["ui/skin#awards/award_bg_badge_ultra_silver.png"])
  headshot = mkStdAward(["ui/skin#awards/award_bg_badge_ultra_silver.png", "ui/skin#awards/longrange_silver.png"])
  grenade_kill = mkStdAward(["ui/skin#awards/award_bg_shield_silver.png"])
  melee_kill = mkStdAward(["ui/skin#awards/award_bg_badge_ultra_red.png", "ui/skin#awards/melee_silver.png"])
  machinegunner_kill = mkStdAward(["ui/skin#awards/award_bg_shield_silver.png"])
  long_range_kill = mkStdAward(["ui/skin#awards/award_bg_badge_hight_red.png", "ui/skin#awards/longrange_gold.png"])
  capture = mkStdAward(["ui/skin#awards/award_bg_shield_bronse.png"])
  double_kill = mkStdAward(["ui/skin#awards/award_bg_shield_red.png"])
  triple_kill = mkStdAward(["ui/skin#awards/award_bg_shield_red.png"])
  multi_kill = mkStdAward(["ui/skin#awards/award_bg_shield_red.png", "ui/skin#awards/kill_gold.png"])
  semiauto_kills = mkDefaultAward
}

local function mkAward(options) {
  local ctor = awardsCfg?[options?.award.id] ?? mkDefaultAward
  return ctor(options)
}

return {
  make = mkAward
  awardsCfg = awardsCfg
}
 