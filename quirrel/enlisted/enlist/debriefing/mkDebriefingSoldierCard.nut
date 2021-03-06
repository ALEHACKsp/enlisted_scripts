local { sound_play } = require("sound")
local { getObjectName } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local {
  soldierExpColor, soldierCardSize, activeBgColor, defBgColor, smallPadding
} = require("enlisted/enlist/viewConst.nut")
local {
  mkLevelIcon, photo
} = require("enlisted/enlist/soldiers/components/soldiersUiComps.nut")

local SHOW_CARD_DELAY = 0.5
local EXP_RISE_DELAY = 0.9
local LVL_RISE_DELAY = 0.6

local getExpProgressValue = @(exp, nextExp)
  nextExp > 0 ? ::clamp(exp.tofloat() / nextExp, 0, 1) : 0

local mkAddLevelBlock = @(lvlAdded, delay, delay1, animCtor) {
  flow = FLOW_HORIZONTAL
  children = array(lvlAdded)
    .map(@(v, i) mkLevelIcon().__update({
      transform = {}
      animations = animCtor(delay + delay1 + LVL_RISE_DELAY * i - 0.2,
        @() sound_play("ui/debriefing/squad_star"))
    }))
}

local mkExpAnim = @(w1, w2, delay, duration, cb = null) {
  prop = AnimProp.scale, easing = OutQuad, from = [w1, 1], to = [w2, 1],
  delay = delay, duration = duration, play = true, trigger = "content_anim",
  onFinish = cb
}

local function getExpAnimations(w1, w2, lvlAdded, delay, delay1, delay2, cb) {
  local res = [ mkExpAnim(w1, w1, 0, delay) ]
  local cbDelay = cb != null ? 0.2 : 0

  if (lvlAdded <= 0)
    return res.append( mkExpAnim(w1, w2, delay, delay1 + cbDelay, cb) )

  local riseDelay
  res.append( mkExpAnim(w1, 1, delay, delay1) )
  for (local i = 0; i < lvlAdded - 1; i++) {
    riseDelay = delay + delay1 + LVL_RISE_DELAY * i
    res.append( mkExpAnim(0, 1, riseDelay, LVL_RISE_DELAY) )
  }

  riseDelay = delay + delay1 + cbDelay + LVL_RISE_DELAY * (lvlAdded - 1)
  return res.append( mkExpAnim(0, w2, riseDelay, delay2, cb) )
}

local mkExpRiseBlock = @(w1, w2, lvlAdded, delay, delay1, delay2, cb) {
  rendObj = ROBJ_BOX
  size = [flex(), hdpx(7)]
  margin = smallPadding
  vplace = ALIGN_BOTTOM
  fillColor = defBgColor
  borderColor = activeBgColor
  children = {
    rendObj = ROBJ_SOLID
    size = [pw(100), flex()]
    color = activeBgColor
    transform = { pivot = [0, 0], scale = [w2, 1] }
    animations = getExpAnimations(w1, w2, lvlAdded, delay, delay1, delay2, cb)
  }
}

local SOLDIER_CARD_PARAMS = {
  stat = null
  info = null
  animDelay = 0
  mkAppearAnimations = @(delay) null
  nextAnimCb = null
}
local function mkSoldierCard (params = SOLDIER_CARD_PARAMS) {
  params = SOLDIER_CARD_PARAMS.__merge(params)

  local cb = params.nextAnimCb
  local aDelay = params.animDelay
  local maxLevel = params?.stat.maxLevel ?? params?.info.maxLevel ?? 1
  local wasLevel = min(params?.stat.wasExp.level ?? 0, maxLevel)
  local newLevel = min(params?.stat.newExp.level ?? 0, maxLevel)
  local wasExp = params?.stat.wasExp.exp ?? 0
  local newExp = params?.stat.newExp.exp ?? 0
  local wasNextLvlExp = params?.stat.wasExp.nextExp ?? wasExp
  local newNextLvlExp = params?.stat.newExp.nextExp ?? newExp

  local w1 = getExpProgressValue(wasExp, wasNextLvlExp)
  local w2 = getExpProgressValue(newExp, newNextLvlExp)
  local lvlAdded = newLevel - wasLevel

  local delay1 = wasNextLvlExp == 0 ? 0
    : lvlAdded <= 0 ? EXP_RISE_DELAY * (newExp - wasExp) / wasNextLvlExp
    : EXP_RISE_DELAY * (wasNextLvlExp - wasExp) / wasNextLvlExp

  local delay2 = (!newNextLvlExp || lvlAdded <= 0) ? 0
    : EXP_RISE_DELAY * newExp / newNextLvlExp

  delay1 = ::max(delay1, EXP_RISE_DELAY / 4)
  delay2 = ::max(delay2, EXP_RISE_DELAY / 4)
  return {
    content = {
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      children = [
        {
          children = [
            {
              rendObj = ROBJ_IMAGE
              size = soldierCardSize
              flow = FLOW_VERTICAL
              halign = ALIGN_CENTER
              valign = ALIGN_BOTTOM
              imageValign = ALIGN_TOP
              image = ::Picture(photo(params?.info.guid ?? "", params?.info.country))
              children = [
                mkAddLevelBlock(lvlAdded, aDelay + SHOW_CARD_DELAY, delay1, params.mkAppearAnimations)
                mkExpRiseBlock(w1, w2, lvlAdded, aDelay + SHOW_CARD_DELAY, delay1, delay2, cb)
              ]
            }
            lvlAdded > 0 ? {
              rendObj = ROBJ_BOX
              size = flex()
              borderColor = soldierExpColor
              animations = [
                { prop = AnimProp.opacity, from = 0, to = 0, play = true,
                  duration = aDelay + delay1 + 0.3, trigger = "content_anim" }
                { prop = AnimProp.opacity, from = 0, to = 1, play = true,
                  delay = aDelay + delay1 + 0.3, duration = 0.3, trigger = "content_anim" }
              ]
            } : null
          ]
        }
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [flex(), SIZE_TO_CONTENT]
          font = Fonts.small_text
          vplace = ALIGN_CENTER
          halign = ALIGN_CENTER
          text = getObjectName(params?.info)
        }
      ]
      transform = {}
      animations = params.mkAppearAnimations(aDelay)
    }
    delay = delay1 + delay2 + ::max(0, EXP_RISE_DELAY * (lvlAdded - 1))
  }
}

return mkSoldierCard
 