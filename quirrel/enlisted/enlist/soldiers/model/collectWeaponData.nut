local DataBlock = require("DataBlock")
local { Point2 } = require("dagor.math")
local { round_by_value } = require("std/math.nut")

local cachedBlocks = {}
local zeroPoint2 = Point2(0.0, 0.0)

local TYPE_INT = 1
local TYPE_FLOAT = 2
local TYPE_POINT2 = 3
local TYPE_ARRAY = 4
local TYPE_STRING = 5

local ITEM_DATA_FIELDS = {
  ["item.weight"] = TYPE_FLOAT,
  ["item.healAmount"] = TYPE_FLOAT,
  ["item.reviveAmount"] = TYPE_FLOAT,
  ["gun.shotFreq"] = TYPE_FLOAT,
  ["gun.shotFreqRndK"] = TYPE_FLOAT,
  ["gun.kineticDamageMult"] = TYPE_FLOAT,
  ["gun.recoilAmount"] = TYPE_FLOAT,
  ["gun.recoilDirAmount"] = TYPE_FLOAT,
  ["gun_spread.maxDeltaAngle"] = TYPE_FLOAT,
  ["gun.shells"] = TYPE_ARRAY,
  ["gun.ammoHolders"] = TYPE_ARRAY,
  ["gun.reloadTime"] = TYPE_FLOAT,
  ["gun.firingModeNames"] = TYPE_ARRAY,
  magazine_type = TYPE_STRING,
}

local SHELLS_DATA_FIELDS = {
  bullets = TYPE_INT
  caliber = TYPE_FLOAT
  speed = TYPE_FLOAT
  maxDistance = TYPE_FLOAT
  hitPowerMult = TYPE_FLOAT
  cartridgeMass = TYPE_FLOAT
  reloadTime = TYPE_FLOAT
  explodeHitPower = TYPE_FLOAT
  explodeArmorPower = TYPE_FLOAT
  spawn = { minCount = TYPE_INT, maxCount = TYPE_INT }
  armorpower = {
    ArmorPower0m = TYPE_POINT2,    ArmorPower100m = TYPE_POINT2,
    ArmorPower500m = TYPE_POINT2,  ArmorPower1000m = TYPE_POINT2,
    ArmorPower1500m = TYPE_POINT2, ArmorPower7000m = TYPE_POINT2
  }
  hitpower = {
    HitPower10m = TYPE_POINT2,  HitPower40m = TYPE_POINT2,  HitPower100m = TYPE_POINT2,
    HitPower150m = TYPE_POINT2, HitPower200m = TYPE_POINT2, HitPower300m = TYPE_POINT2,
    HitPower350m = TYPE_POINT2, HitPower400m = TYPE_POINT2, HitPower450m = TYPE_POINT2,
    HitPower600m = TYPE_POINT2, HitPower650m = TYPE_POINT2, HitPower1000m = TYPE_POINT2,
    HitPower1500m = TYPE_POINT2
  }
}

local HOLDERS_DATA_FIELDS = {
  bullets = TYPE_INT
  reloadTime = TYPE_FLOAT
}

local function readTemplate(template, scheme) {
  if (template == null || typeof scheme != "table")
    return null

  local res = {}
  foreach (key, val in scheme) {
    local value
    switch (val) {
      case TYPE_INT:
        value = template.getCompValNullable(key)
        if (value != null)
          value = value.tointeger()
        break
      case TYPE_FLOAT:
        value = template.getCompValNullable(key)
        if (value != null)
          value = value.tofloat()
        break
      case TYPE_POINT2:
        local point = template.getCompValNullable(key)
        if (point != null && (point?.x ?? 0) != 0 && (point?.y ?? 0) != 0)
          value = Point2(point.x, point.y)
        break
      case TYPE_ARRAY:
        value = template.getCompValNullable(key)?.getAll()
        break
      case TYPE_STRING:
        value = template.getCompValNullable(key)
        if (::type(value) != "string")
          value = null
        break
    }
    if (value != null)
      res[key] <- value
  }
  return res
}

local function readBlock(blockData, scheme) {
  if (blockData == null || typeof scheme != "table")
    return null

  local res = {}
  foreach (key, val in scheme) {
    local value
    switch (val) {
      case TYPE_INT:
        value = blockData.getInt(key, 0) || null
        break
      case TYPE_FLOAT:
        value = blockData.getReal(key, 0.0) || null
        break
      case TYPE_POINT2:
        value = blockData.getPoint2(key, zeroPoint2)
        if (value.x == 0.0 && value.y == 0.0)
          value = null
        break
      default:
        foreach (blk in (blockData % key) ?? []) {
          local data = readBlock(blk, val)
          if (data != null)
            value = (value ?? {}).__update(data)
        }
    }
    if (value != null)
      res[key] <- value
  }
  return res
}

local function extractBlockData(blockPath, scheme) {
  if (blockPath == null)
    return null

  local value = cachedBlocks?[blockPath]
  if (value != null)
    return value

  local blockData = DataBlock()
  blockData.load(blockPath)
  value = readBlock(blockData, scheme)
  cachedBlocks[blockPath] <- value
  return value
}

local RATE_OF_FIRE_KEYS = ["single_reload.prepareTime", "single_reload.loopTime", "single_reload.postTime"]

local function processShotFreq(itemData) {
  local shotTime = itemData?["gun.shotFreq"]
  if (shotTime == null)
    return
  shotTime = 1.0 / (shotTime ?? 1.0)
    + RATE_OF_FIRE_KEYS.reduce(@(tm, key) tm + (itemData?[key] ?? 0.0), 0.0)
    + (itemData?.bullets == 1 ? itemData?.reloadTime ?? 0.0 : 0.0)
  local rateOfFire = 60.0 / shotTime
  local roundValue = rateOfFire < 100 ? 1 : 10  // beautify big values
  itemData.rateOfFire <- round_by_value(rateOfFire, roundValue).tointeger()

  local rndK = itemData?["gun.shotFreqRndK"] ?? 0
  local rateOfFireMin = round_by_value(rateOfFire / (1.0 + rndK), roundValue).tointeger()
  if (rateOfFireMin != itemData.rateOfFire)
    itemData.rateOfFire = [
      rateOfFireMin
      itemData.rateOfFire
    ]
}

local function processHitPower(itemData) {
  if (itemData == null)
    return
  local hitPowerMult = (itemData?.hitPowerMult ?? 0.0) * (itemData?.spawn.maxCount ?? 1.0)
  if (hitPowerMult > 0)
    itemData.hitPowerMult <- hitPowerMult
}

local function processRecoil(itemData) {
  if (itemData == null)
    return
  local recoilAmount = itemData?["gun.recoilAmount"] ?? 0.0
  local recoilDirAmount = itemData?["gun.recoilDirAmount"] ?? 0.0
  itemData.recoilAmountVert <- 1000 * recoilAmount * recoilDirAmount
  itemData.recoilAmountHor <- 1000 * recoilAmount * (1.0 - recoilDirAmount)
}

local function processWeaponData(weaponData) {
  processShotFreq(weaponData)
  processHitPower(weaponData)
  processRecoil(weaponData)
}

local function getWeaponData(templateId) {
  local tmplDB = ::ecs.g_entity_mgr.getTemplateDB()
  local template = tmplDB.getTemplateByName(templateId)
  local weaponId = template?.getCompValNullable("item.weapTemplate")
  if (weaponId != null && weaponId != templateId)
    template = tmplDB.getTemplateByName(weaponId)

  local itemData = readTemplate(template, ITEM_DATA_FIELDS)
  if (itemData == null)
    return null
  local shellsData = extractBlockData(itemData?["gun.shells"][0], SHELLS_DATA_FIELDS)
  if (shellsData != null)
    itemData = itemData.__update(shellsData)
  local holdersData = extractBlockData(itemData?["gun.ammoHolders"][0], HOLDERS_DATA_FIELDS)
  if (holdersData != null)
    itemData = itemData.__update(holdersData)

  processWeaponData(itemData)
  return itemData
}

local mkMulByPercent = @(field) function(weaponData, value) {
  if (field in weaponData)
    weaponData[field] *= 1.0 + 0.01 * value
}

local upgradesUpdate = {
  ["gun.kineticDamageMult"] = mkMulByPercent("hitPowerMult"),
  ["gun.shotFreq"] = mkMulByPercent("gun.shotFreq"),
  ["gun.recoilAmount"] = mkMulByPercent("gun.recoilAmount"),
  ["gun.recoilDirAmount"] = mkMulByPercent("gun.recoilDirAmount"),
}

local function applyUpgrades(weaponData, upgrades) {
  local res = clone weaponData
  foreach(key, value in upgrades ?? {})
    upgradesUpdate?[key](res, value)
  processWeaponData(res)
  return res
}

return {
  getWeaponData = getWeaponData
  applyUpgrades = applyUpgrades
} 