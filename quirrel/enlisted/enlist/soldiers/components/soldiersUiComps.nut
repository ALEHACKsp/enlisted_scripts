local fa = require("daRg/components/fontawesome.map.nut")
local { getRomanNumeral } = require("std/math.nut")
local {
  gap, defTxtColor, soldierExpColor, soldierLvlColor, soldierGainLvlColor,
  soldierLockedLvlColor, msgHighlightedTxtColor
} = require("enlisted/enlist/viewConst.nut")
local colorize = require("enlist/colorize.nut")
local { withTooltip } = require("ui/style/cursors.nut")
local soldierClasses = require("enlisted/enlist/soldiers/model/soldierClasses.nut")
local blinkingIcon = require("enlisted/enlist/components/blinkingIcon.nut")
local {
  getExpToNextLevel, perkLevelsGrid
} = require("enlisted/enlist/soldiers/model/perks/perksExp.nut")
local defcomps = require("enlisted/enlist/components/defcomps.nut")
local { soldierTiersCount } = require("enlisted/enlist/soldiers/model/config/trainingConfig.nut")

const MAX_SOLDIERS_ICONS = 6

local function photo(guid, country) {
  local sImageId = ((guid ?? "").hash() % MAX_SOLDIERS_ICONS) + 1
  return country != null
    ? "ui/soldiers/{0}/soldier_{1}.jpg".subst(country, sImageId)
    : "ui/soldiers/soldier_default.jpg"
}

local newPerksIcon = @(soldierGuid, isSelected, unseenCount) function() {
  local ret = { watch = unseenCount }
  if (unseenCount.value > 0)
    ret.__update(blinkingIcon("arrow-up", unseenCount.value, isSelected))
  return ret
}

local mkLevelIcon = @(fontSize = ::hdpx(10), color = soldierExpColor, fName = "star") {
  rendObj = ROBJ_STEXT
  validateStaticText = false
  text = fa[fName]
  font = Fonts.fontawesome
  fontSize = fontSize
  color = color
}

local mkIconBar = @(level, color, fontSize, fName = "star-o", hasBlink = false)
  mkLevelIcon(fontSize, fName).__update({
    key = $"l{level}fnm{fName}b{hasBlink}"
    text = "".join(array(level, fa[fName]))
    color = color
    animations = hasBlink
      ? [ { prop = AnimProp.opacity, from = 0.5, to = 1, duration = 0.7, play = true, loop = true, easing = Blink} ]
      : null
  })

local mkHiddenAnim = @(p = {})
  { prop = AnimProp.opacity, from = 0, to = 0, duration = 0.1, play = true }.__update(p)

local mkAnimatedLevelIcon = function(guid, color, fontSize) {
    local trigger = $"{guid}lvl_anim"
    return {
      children = [
        mkLevelIcon(fontSize, color, "star-o")
        mkLevelIcon(fontSize, color, "star").__update({
          transform = {}
          animations = [
            mkHiddenAnim({ duration = 0.9, play = false, trigger })
            { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4,
              easing = InOutCubic, delay = 0.8, trigger }
            { prop = AnimProp.scale, from = [3,3], to = [1,1], duration = 0.8,
              easing = InOutCubic, delay = 0.8, trigger }
          ]
        })
      ]
    }
  }

local levelBlock = ::kwarg(@(
  curLevel, gainLevel = 0, leftLevel = 0, lockedLevel = 0, fontSize = hdpx(12),
  hasLeftLevelBlink = false, guid = ""
) {
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  children = [
    curLevel > 2
      ? mkIconBar(curLevel - 2, soldierExpColor, fontSize, "star")
      : null
    curLevel > 1
      ? mkAnimatedLevelIcon(guid, soldierExpColor, fontSize)
      : null

    gainLevel > 0 ? mkIconBar(gainLevel, soldierGainLvlColor, fontSize) : null
    leftLevel > 0 ? mkIconBar(leftLevel, soldierExpColor, fontSize, "star-o", hasLeftLevelBlink) : null
    lockedLevel > 0 ? mkIconBar(lockedLevel, soldierLockedLvlColor, fontSize) : null
  ]
  animations = [ mkHiddenAnim() ]
})

local getClassById = @(sClassId)
  soldierClasses?[sClassId] ?? soldierClasses.unknown

local mkUnknownClassIcon = @(iSize) {
  rendObj = ROBJ_DTEXT
  size = [iSize.tointeger(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  text = "?"
  font = Fonts.medium_text
  color = defTxtColor
}

local function classIcon(sClass, iSize, sClassRare = null, forceColor = null) {
  if (sClass == null)
    return mkUnknownClassIcon(iSize)

  local sClassCfg = getClassById(sClass)
  local sClassImg = sClassCfg?.iconsByRare[sClassRare] ?? sClassCfg.icon
  local sClassColor = forceColor ?? sClassCfg?.colorsByRare[sClassRare] ?? defTxtColor
  return {
    rendObj = ROBJ_IMAGE
    size = [iSize, iSize]
    color = sClassColor
    image = ::Picture("ui/skin#{0}:{1}:{1}:K".subst(sClassImg, iSize.tointeger()))
  }
}

local function className(sClass, sClassRare = null) {
  local sClassCfg = getClassById(sClass)
  local locId = sClassCfg.locId
  local sClassColor = sClassCfg?.colorsByRare[sClassRare] ?? defTxtColor
  return defcomps.note({
    text = sClassRare != null
      ? ::loc($"{locId}_rare_{sClassRare}", ::loc(locId))
      : ::loc(locId)
    vplace = ALIGN_CENTER
    color = sClassColor
  })
}

local tierText = @(tier) defcomps.note({
    font = Fonts.small_text
    text = getRomanNumeral(tier)
    color = soldierLvlColor
  })

local function calcExperienceData(soldier, levelsGrid) {
  local { perksCount = 0, perksLimit = 0, level = 1, maxLevel = 1, exp = 0 } = soldier
  local expToNextLevel = getExpToNextLevel(level, maxLevel, levelsGrid) || 1
  local perksLevel = min(level, maxLevel)
  perksLimit = perksLimit <= 0 ? perksLevel : min(perksLevel, perksLimit)
  return { level, maxLevel, exp, expToNextLevel, perksCount, perksLevel, perksLimit }
}

local classTooltip = @(sClass)
  "{0}\n{1}".subst(::loc($"soldierClass/{sClass}"), ::loc($"soldierClass/{sClass}/desc"))

local rankingTooltip = @(curRank) ::loc("tooltip/soldierRanking", {
  current = colorize(msgHighlightedTxtColor, getRomanNumeral(curRank))
  max = colorize(msgHighlightedTxtColor, getRomanNumeral(soldierTiersCount.value + 1))
})

local experienceTooltip = ::kwarg(function(
  level, maxLevel, exp, expToNextLevel, perksCount, perksLevel, perksLimit
) {
  local limitLoc = perksCount >= maxLevel ? ""
    : perksLimit <= 0 && perksCount >= perksLevel ? ::loc("hint/perksLevelLimit", { count = perksLevel })
    : perksLimit > 0 && perksCount >= perksLimit ? ::loc("hint/perksResearchLimit", { count = perksLimit })
    : ""
  return ::loc(level < maxLevel ? "hint/soldierLevel" : "hint/soldierMaxLevel", {
    level = colorize(msgHighlightedTxtColor, level - 1)
    maxLevel = maxLevel - 1
    exp = colorize(msgHighlightedTxtColor, exp)
    expToNextLevel = expToNextLevel
    limit = limitLoc
  })
})

local levelBlockWithProgress = @(soldierWatch, perksWatch, override = {}) function() {
  local { guid } = soldierWatch.value
  local levelData = calcExperienceData(soldierWatch.value.__merge(perksWatch.value ?? {}), perkLevelsGrid.value)
  local { maxLevel, exp, expToNextLevel, perksCount, perksLimit } = levelData
  local expProgress = expToNextLevel > 0 ? 100.0 * exp / expToNextLevel : 0
  return withTooltip({
    key = guid
    watch = [soldierWatch, perksWatch, perkLevelsGrid]
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = gap
    children = [
      levelBlock({
        curLevel = perksCount
        leftLevel = max(perksLimit - perksCount, 0)
        lockedLevel = max(maxLevel - perksLimit, 0)
        hasLeftLevelBlink = true
        guid = guid
      })
      {
        size = [flex(), hdpx(5)]
        minWidth = hdpx(120)
        children = [
          { size = flex(), rendObj = ROBJ_SOLID,  color = Color(154, 158, 177) }
          { size = [pw(expProgress), flex()], rendObj = ROBJ_SOLID,  color = Color(47, 137, 211) }
        ]
      }
    ]
  }.__update(override), experienceTooltip(levelData))
}

return {
  photo // TODO rename method to more specific
  newPerksIcon
  levelBlock
  levelBlockWithProgress
  classIcon
  className
  tierText
  calcExperienceData
  classTooltip
  rankingTooltip
  experienceTooltip
  mkLevelIcon
}
 