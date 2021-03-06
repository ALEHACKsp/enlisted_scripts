local {
  gap, activeBgColor, hoverBgColor, defBgColor, slotBaseSize, disabledTxtColor,
  blockedTxtColor, deadTxtColor, listCtors
} = require("enlisted/enlist/viewConst.nut")
local { statusIconLocked } =  require("enlisted/style/statusIcon.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local { autoscrollText } = require("enlisted/enlist/components/defcomps.nut")
local { withTooltip } = require("ui/style/cursors.nut")
local {
  classIcon, levelBlock, tierText, photo, classTooltip, rankingTooltip,
  calcExperienceData, experienceTooltip
} = require("components/soldiersUiComps.nut")
local { perkLevelsGrid } = require("model/perks/perksExp.nut")
local {
  getItemNameByGameTemplate, getObjectName
} = require("enlisted/enlist/soldiers/itemsInfo.nut")

local DISABLED_ITEM = { tint = ::Color(40, 40, 40, 120), picSaturate = 0.0 }

local iconDead = Picture("ui/skin#lb_deaths")

local function listSquadColor(flags, selected, idx, isFaded, hasAlertStyle, isDead) {
  if (isDead)
    return Color(40,10,10,180)

  local add = hasAlertStyle ? Color(30,0,0,0)
    : isFaded ? Color(30,30,30,30)
    : 0
  return selected ? activeBgColor
    : flags & S_HOVER
      ? hoverBgColor
      : add + defBgColor
}

local sClassIconSize = hdpx(22).tointeger()
local makeClassIcon = @(soldier, color, isDead = false) isDead
  ? {
      rendObj = ROBJ_IMAGE
      size = [sClassIconSize, sClassIconSize]
      vplace = ALIGN_CENTER
      image = iconDead
      tint = color
    }
  : withTooltip(
      {
        size = [SIZE_TO_CONTENT, flex()]
        children = classIcon(soldier?.sClass, sClassIconSize, soldier?.sClassRare)
          .__update({color = color vplace = ALIGN_CENTER})
      },
      soldier?.customClassTooltip == null
        ? classTooltip(soldier?.sClass)
        : soldier?.customClassTooltip)

local warningMark = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_STEXT
  font = Fonts.fontawesome
  fontSize = ::hdpx(11)
  color = statusIconLocked
  text = fa["warning"]
  validateStaticText = false
  animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1.0, play = true, loop = true, easing = CosineFull }]
}

local mkDropSoldierInfoBlock = @(soldierInfo, squadInfo, nameColor, textColor, group) { //!!FIX ME: Why it here?
  size = flex()
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = ::loc(squadInfo.titleLocId)
        color = textColor
        font = Fonts.tiny_text
      }
    }
    autoscrollText({
      text = getObjectName(soldierInfo)
      color = nameColor
      group = group
    })
  ]
}

local function mkWeaponRow(soldierInfo, weaponColor, group, override = {}) {
  local primaryWeapon = soldierInfo?.primaryWeapon
  local weaponName = primaryWeapon != null
    ? getItemNameByGameTemplate(primaryWeapon?.gametemplate) ?? primaryWeapon?.name
    : getItemNameByGameTemplate((soldierInfo?.weapons ?? [])
        .findvalue(@(v, idx) idx < 3 && (v?.templateName ?? "") != "")?.templateName)
  return autoscrollText({
    text = weaponName
    color = weaponColor
    vplace = ALIGN_BOTTOM
    group = group
  }.__update(override))
}

local mkWeaponRowWithWarning = @(soldierInfo, weaponColor, group, override = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = ::hdpx(2)
  children = [
    warningMark
    mkWeaponRow(soldierInfo, weaponColor, group, override)
  ]
}

local mkSoldierInfoBlock = function(soldierInfo, nameColor, weaponRow, group) {
  local {
    guid = "", perksCount = 0, perksLimit = 0, level = 1, maxLevel = 1
  } = soldierInfo
  local perksLevel = min(level, maxLevel)
  perksLimit = perksLimit <= 0 ? perksLevel : min(perksLevel, perksLimit)
  return {
    size = flex()
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    children = [
      guid != ""
        ? autoscrollText({
          text = getObjectName(soldierInfo)
          color = nameColor
          group = group
        })
        : null
      weaponRow
      withTooltip(@()
        levelBlock({
          curLevel = perksCount
          leftLevel = max(perksLimit - perksCount, 0)
          lockedLevel = max(maxLevel - perksLimit, 0)
          fontSize = hdpx(8)
          hasLeftLevelBlink = true
          guid = guid
        }).__update({ margin = [gap, 0] }),
        experienceTooltip(calcExperienceData(soldierInfo, perkLevelsGrid.value)))
    ]
  }
}

local function soldierCard(soldierInfo, idx = 0, group = null, sf = 0, isSelected = false,
  isFaded = false, isDead = false, size = slotBaseSize, isClassRestricted = false,
  hasAlertStyle = false, hasWeaponWarning = false, addChild = null, squadInfo = null, updStyle = {},
  isDisarmed = false
) {
  local canSpawn = soldierInfo?.canSpawn ?? true
  local isBlocked = isDead || !canSpawn

  local textColor = isBlocked
    ? @(...) deadTxtColor
    : isFaded
      ? listCtors.txtDisabledColor
      : listCtors.weaponColor

  local nameColor = isBlocked
    ? @(...) deadTxtColor
    : isFaded
      ? listCtors.weaponColor
      : listCtors.nameColor

  local weaponRow = isDisarmed
    ? mkWeaponRow(soldierInfo, disabledTxtColor, group, { text = ::loc("delivery/withoutWeapon") })
    : (hasWeaponWarning
        ? mkWeaponRowWithWarning
        : mkWeaponRow)(soldierInfo, textColor(sf, isSelected), group)
  local tier = soldierInfo?.tier ?? 1

  return {
    key = $"{soldierInfo.guid}"
    size = size
    rendObj = ROBJ_SOLID
    color = listSquadColor(sf, isSelected, idx, isFaded, hasAlertStyle, isBlocked)
    clipChildren = true
    group = group
    flow = FLOW_HORIZONTAL
    gap = gap
    padding = [0, 0, 0, gap]

    children = [
      makeClassIcon(soldierInfo,
        isClassRestricted
          ? blockedTxtColor
          : textColor(sf, isSelected),
        isDead)
      withTooltip({
        children = [
          {
            size = [SIZE_TO_CONTENT, size[1]]
            padding = gap
            rendObj = ROBJ_IMAGE
            image = ::Picture(photo(soldierInfo?.guid, soldierInfo?.country))
          }.__update(isFaded || isBlocked ? DISABLED_ITEM : {})
          tierText(tier).__update({ margin = [0, hdpx(2)] })
        ]
      }, rankingTooltip(tier))
      {
        size = flex()
        children = [
          squadInfo == null
            ? mkSoldierInfoBlock(soldierInfo, nameColor(sf, isSelected), weaponRow, group)
            : mkDropSoldierInfoBlock(soldierInfo, squadInfo, nameColor(sf, isSelected), textColor(sf, isSelected), group)
          {
            size = flex()
            padding = hdpx(2)
            children = addChild?(soldierInfo, isSelected)
          }
        ]
      }
    ]
  }.__update(updStyle)
}

return ::kwarg(soldierCard) 