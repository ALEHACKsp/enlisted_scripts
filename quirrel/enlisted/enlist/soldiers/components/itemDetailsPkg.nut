local { fabs } = require("math")
local {
  defTxtColor, activeTxtColor, fadedTxtColor, textBgBlurColor, smallPadding, bigPadding,
  msgHighlightedTxtColor, inventoryItemDetailsWidth
} = require("enlisted/enlist/viewConst.nut")
local { floatToStringRounded } = require("std/string.nut")
local { round_by_value } = require("std/math.nut")
local colorize = require("enlist/colorize.nut")
local { getWeaponData, applyUpgrades } = require("enlisted/enlist/soldiers/model/collectWeaponData.nut")
local upgrades = require("enlisted/enlist/soldiers/model/config/upgradesConfig.nut")
local { levelBlock } = require("soldiersUiComps.nut")

const GOOD_COLOR = 0xFF3DB613
const BAD_COLOR = 0xFFB63D13

local blur = @(children) {
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = textBgBlurColor
  children = children
  padding = smallPadding
  flow = FLOW_HORIZONTAL
}

local mkTextRow = @(header, value) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_DTEXT
      text = header
      color = defTxtColor
    }
    { size = flex() }
    {
      rendObj = ROBJ_TEXTAREA
      text = value
      behavior = Behaviors.TextArea
      color = defTxtColor
    }
  ]
}

local DETAILS_LIST = [
  { key = "caliber", measure = "mm", mult = 1000, precision = 0.01 }
  { key = "hitPowerMult", precision = 0.1 }
  { key = "explodeHitPower", precision = 0.1 }
  { key = "hitpower", measure = "meters", precision = 0.1, baseKey = "hitPowerMult" }
  { key = "armorpower", measure = "meters", altMeasure = "mm", precision = 0.1 }
  { key = "speed", measure = "m/sec" }
  { key = "rateOfFire", measure = "shots/min" }
  { key = "gun.reloadTime", measure = "sec", precision = 0.1 }
  { key = "recoilAmountVert", isPositive = false }
  { key = "recoilAmountHor", isPositive = false }

  { key = "bullets"
    rowCtor = @(val, weapData, setup) val <= 0 ? null
      : mkTextRow(::loc($"itemDetails/bullets"),
        ::loc(weapData?.magazine_type ?? "magazine_type/default",
          { count = val, countColored = colorize(activeTxtColor, val) }))
  }
  { key = "item.healAmount", precision = 0.1 }
  { key = "item.reviveAmount", precision = 0.1 }
  { key = "item.weight", measure = "grams", mult = 1000, altLimit = 1.0, altMeasure = "kg", precision = 0.1 }
  { key = "cartridgeMass", measure = "grams", mult = 1000, altLimit = 1.0, altMeasure = "kg", precision = 0.1 }
  { key = "gun.firingModeNames",
    rowCtor = @(val, weapData, setup) val.len() == 0 ? null
      : mkTextRow(::loc($"itemDetails/gun.firingModeNames"),
        ", ".join(val.map(@(name) ::loc($"firing_mode/{name}"))))
  }
]

local getValueColor = @(val, baseVal, isPositive = true)
  fabs(val - baseVal) < 0.001 * fabs(val + baseVal) ? activeTxtColor
    : val > baseVal == isPositive ? GOOD_COLOR
    : BAD_COLOR

local function mkDetailsLine(val, baseVal, setup) {
  local { key, mult = 1, measure = "", altLimit = 0.0, altMeasure = "", precision = 1, isPositive = true } = setup
  local color = getValueColor(val, baseVal, isPositive)
  if (altLimit != 0.0 && val >= altLimit)
    measure = altMeasure
  else
    val *= mult
  local valColor = colorize(color, floatToStringRounded(val, precision))
  val = round_by_value(val, precision).tointeger()
  return mkTextRow(::loc($"itemDetails/{key}"),
    measure != "" ? "{0}{1}".subst(valColor, ::loc($"itemDetails/{measure}", { val = val })) : valColor)
}

local function mkDetailsRange(val, baseVal, setup) {
  if (::type(baseVal) != "array")
    baseVal = [baseVal]
  local { key, mult = 1, measure = "", altLimit = 0.0, altMeasure = "", precision = 1, isPositive = true } = setup
  local colors = val.map(@(v, idx) getValueColor(v, baseVal?[idx] ?? baseVal.top(), isPositive))
  if (altLimit != 0.0 && val.top() >= altLimit)
    measure = altMeasure
  else
    val = (clone val).map(@(v) v * mult)
  local valColorList = val.map(@(v, idx) colorize(colors[idx], floatToStringRounded(v, precision)))
  local valColor = "-".join(valColorList)
  local topVal = round_by_value(val.top(), precision).tointeger()
  return mkTextRow(::loc($"itemDetails/{key}"),
    measure != "" ? "{0}{1}".subst(valColor, ::loc($"itemDetails/{measure}", { val = topVal })) : valColor)
}

local function mkDetailsTable(tbl, setup, baseVal = 1.0) {
  local { key, mult = 1, measure = "", altMeasure = "", precision = 1 } = setup
  if (mult == 0 || baseVal == 0)
    return null
  local columns = tbl.values()
    .filter(@(p) (p?.x ?? 0) != 0 || (p?.y ?? 0) != 0)
    .sort(@(a, b) (a?.y ?? 0) <=> (b?.y ?? 0))
    .map(function(col) {
      local ref = col?.y ?? 0
      local refColor = colorize(activeTxtColor, ref)
      local val = (col?.x ?? 0) * baseVal * mult
      local valColor = colorize(activeTxtColor, floatToStringRounded(val, precision))
      val = round_by_value(val, precision).tointeger()
      return {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        padding = smallPadding
        children = [
          {
            rendObj = ROBJ_TEXTAREA
            text = measure != ""
              ? "{0}{1}".subst(refColor, ::loc($"itemDetails/{measure}", { val = ref }))
              : refColor
            behavior = Behaviors.TextArea
            color = defTxtColor
          }
          {
            rendObj = ROBJ_TEXTAREA
            text = altMeasure != ""
              ? "{0}{1}".subst(valColor, ::loc($"itemDetails/{altMeasure}", { val = val }))
              : valColor
            behavior = Behaviors.TextArea
            color = defTxtColor
          }
        ]
      }
    })
  return columns.len() <= 0 ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_DTEXT
        text = ::loc($"itemDetails/{key}")
        color = defTxtColor
      }
      {
        rendObj = ROBJ_FRAME
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = { rendObj = ROBJ_SOLID, size = [::hdpx(1), flex()], color = fadedTxtColor }
        color = fadedTxtColor
        children = columns
      }
    ]
  }
}

local function mkDetails(item) {
  local { upgradesId = null, upgradeIdx = 0, gametemplate = null } = item
  local weaponData = getWeaponData(gametemplate)
  local curUpgrades = ::Computed(@() upgrades.value?[upgradesId][upgradeIdx] ?? {})
  return function() {
    local res = { watch = curUpgrades }
    local upgradedData = applyUpgrades(weaponData, curUpgrades.value)
    local children = DETAILS_LIST
      .map(function(setup) {
        local val = upgradedData?[setup.key]
        return val == null || val == 0 ? null
          : "rowCtor" in setup ? setup.rowCtor(val, weaponData, setup)
          : ::type(val) == "table" ? mkDetailsTable(val, setup, upgradedData?[setup?.baseKey] ?? 1.0)
          : ::type(val) == "array" ? mkDetailsRange(val, weaponData[setup.key], setup)
          : mkDetailsLine(val, weaponData[setup.key], setup)
      })
      .filter(@(v) v != null)
    return children.len() == 0 ? res
      : res.__update(blur({
          size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
          gap = smallPadding
          flow = FLOW_VERTICAL
          children = children
        }))
  }
}

local UPGRADES_LIST = [
  { key = "gun.shotFreq", measure = "percent" }
  { key = "gun.kineticDamageMult", measure = "percent" }
  { key = "recoilVertBonus", measure = "percent", isPositive = false, locId = "itemDetails/recoilAmountVert" }
  { key = "recoilHorBonus", measure = "percent", isPositive = false, locId = "itemDetails/recoilAmountHor" }
  { key = "gun_spread.maxDeltaAngle", measure = "percent", isPositive = false }
]
  .map(@(u) { locId = $"itemDetails/upgrade/{u.key}" }.__update(u))

local function formatValue(val, setup) {
  local { locId, measure = "", mult = 1, precision = 1, isPositive = true } = setup
  val *= mult
  if (fabs(val) < precision)
    return null
  local rounded = floatToStringRounded(val, precision)
  local fullValue = "{0}{1}".subst(val > 0 ? $"+{rounded}" : rounded,
    measure == "" ? "" : ::loc($"itemDetails/{measure}", { val = val.tointeger() }))
  local color = val > 0 == isPositive ? GOOD_COLOR : BAD_COLOR
  return "{0} {1}".subst(::loc(locId), colorize(color, fullValue))
}

local function mkUpgradeGroup(groupId, level, idx, upgrade) {
  if ((upgrade?.len() ?? 0) == 0)
    return null
  local list = []
  UPGRADES_LIST.each(function(setup) {
    local formated = (setup.key in upgrade) ? formatValue(upgrade?[setup.key], setup) : null
    if (formated != null)
      list.append(formated)
  })
  return list.len() <= 0 ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      {
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          {
            rendObj = ROBJ_DTEXT
            text = ::loc($"itemDetails/group/{groupId}_{idx}")
            color = activeTxtColor
          }
          levelBlock({ curLevel = level, leftLevel = idx - level })
        ]
      }
      {
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        text = ", ".join(list)
        behavior = Behaviors.TextArea
        color = defTxtColor
      }
    ]
  }
}

local calcBonus = @(prevWd, curWd, key)
  !(key in curWd) || (prevWd?[key] ?? 0) == 0 ? 0
    : curWd[key].tofloat() / prevWd[key] - 1.0

local function prepareUpgrades(curUpgrades, prevUpgrades, weaponData) {
  local res = clone curUpgrades
  foreach(key, value in prevUpgrades)
    res[key] <- (res?[key] ?? 0) - value

  if ("gun.recoilAmount" in weaponData) {
    local prevWd = applyUpgrades(weaponData, prevUpgrades)
    local curWd = applyUpgrades(weaponData, curUpgrades)
    local recoilVertBonus = 100 * calcBonus(prevWd, curWd, "recoilAmountVert")
    if (fabs(recoilVertBonus) >= 1)
      res.recoilVertBonus <- recoilVertBonus
    local recoilHorBonus = 100 * calcBonus(prevWd, curWd, "recoilAmountHor")
    if (fabs(recoilHorBonus) >= 1)
      res.recoilHorBonus <- recoilHorBonus
  }

  return res
}

local formatUpgrades = @(list) UPGRADES_LIST
  .map(@(setup) formatValue(list?[setup.key] ?? 0, setup))
  .filter(@(v) v != null)

local function mkUpgrades(item) {
  local { upgradesId = null, upgradeIdx = 0, gametemplate = null } = item
  if (upgradesId == null || gametemplate == null)
    return null

  local children = []
  local weaponData = getWeaponData(gametemplate)
  local allUpgrades = upgrades.value?[upgradesId] ?? []
  local curUpgrades = prepareUpgrades(allUpgrades?[upgradeIdx], {}, weaponData)
  local availableUpgrades = formatUpgrades(curUpgrades)
  if (availableUpgrades.len() > 0)
    children.append({
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      text = ", ".join(availableUpgrades)
      behavior = Behaviors.TextArea
      color = defTxtColor
    })

  local pendingUpgrades = []
  for (local idx = upgradeIdx + 1; idx < allUpgrades.len(); ++idx) {
    local diff = prepareUpgrades(allUpgrades[idx], allUpgrades?[idx-1] ?? {}, weaponData)
    local upgradeGroup = mkUpgradeGroup(upgradesId, upgradeIdx + 1, idx, diff)
    if (upgradeGroup != null)
      pendingUpgrades.append(upgradeGroup)
  }
  if (pendingUpgrades.len() > 0)
    children = children.append({
      rendObj = ROBJ_DTEXT
      text = ::loc("itemDetails/label/pendingUpgrades")
      color = msgHighlightedTxtColor
    }).extend(pendingUpgrades)

  return children.len() == 0 ? null : blur({
    size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
    gap = bigPadding
    flow = FLOW_VERTICAL
    children = children
  })
}

local function diffUpgrades(item) {
  local { upgradesId = null, upgradeIdx = 0, gametemplate = null } = item
  if (upgradesId == null || gametemplate == null)
    return null
  local weaponData = getWeaponData(gametemplate)
  local allUpgrades = upgrades.value?[upgradesId] ?? []
  local curUpgrades = prepareUpgrades(allUpgrades?[upgradeIdx + 1], allUpgrades?[upgradeIdx], weaponData)
  return formatUpgrades(curUpgrades)
}

return {
  blur = blur
  mkDetails = mkDetails
  mkUpgrades = mkUpgrades
  diffUpgrades = diffUpgrades
}
 