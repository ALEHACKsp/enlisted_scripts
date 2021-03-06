local style = require("ui/hud/style.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local heroVehicleState = require("ui/hud/state/vehicle_hp.nut").hero
local {vehicleTurrets, showVehicleWeapons, turretHotkeys} = require("vehicle_turret_state.nut")
local weaponWidget = require("player_weapon_widget.nut")
local { isGamepad } = require("ui/control/active_controls.nut")
local vehicleMainGunBullet = require("ui/hud/state/vehicle_bullet_name.nut")
local mkBulletTypeIcon = require("ui/hud/components/mkBulletTypeIcon.nut")

local healthBar = require("mk_health_bar.nut")
local { textListFromAction, buildElems } = require("ui/control/formatInputBinding.nut")
local { mkShortHudHintFromList } = require("ui/hud/components/controlHudHint.nut")

local barWidth = sw(7)
local barHeight = sh(1)
local barBlockHeight = ::hdpx(22)
local gap = ::hdpx(5)
local vehicleWeaponWidth = ::hdpx(320)

local mkControlText = @(text) {
  text = text,
  font = Fonts.medium_text,
  color = style.HUD_TIPS_HOTKEY_FG,
  rendObj = ROBJ_DTEXT padding = hdpx(4)
}

const eventTypeToText = false
local makeTurretControlTip = @(hotkey) function() {
  local textList = textListFromAction(hotkey, isGamepad.value ? 1 : 0, eventTypeToText)
  local controlElems = buildElems(textList, { textFunc = mkControlText, compact = true })
  return mkShortHudHintFromList(controlElems)
}

local defaultTurretControlTips = ["Vehicle.Shoot", "Vehicle.ShootTurret01", "Vehicle.ShootTurret02", "Vehicle.ShootTurret03"]
  .map(makeTurretControlTip)
local turretControlTips = persist("turretControlTips", @() Watched([]))
local switchToBulletTip = makeTurretControlTip("Vehicle.NextBulletType")

turretHotkeys.subscribe(@(hotkeys) turretControlTips(hotkeys.len() > 0 ? hotkeys.map(makeTurretControlTip) : defaultTurretControlTips))

local iconBlockWidth = ::hdpx(230).tointeger()
local function turretIconCtor(weapon, baseWidth, baseHeight) {
  local width = iconBlockWidth
  local height = (0.8 * baseHeight).tointeger()
  local size = [width, height]
  local bulletIcon = mkBulletTypeIcon(weapon, size)
  return {
    size = size
    rendObj = ROBJ_IMAGE
    imageHalign = ALIGN_RIGHT
    imageValign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    image = bulletIcon.image
    color = bulletIcon.color
    keepAspect = true
  }
}

local function vehicleTurretBlock(turret, idx) {
  if (!turret.isMain)
    return weaponWidget({
      width = vehicleWeaponWidth
      weapon = turret.__merge({ instant = true, showZeroAmmo = true })
      hotkey = turretControlTips.value?[idx]
      iconCtor = turretIconCtor
    })

  return function() {
    local curBulletType = vehicleMainGunBullet.value.bulletType
    local nextBulletType = vehicleMainGunBullet.value.nextBulletType
    local nextBulletIdx = turret.bulletTypes.findindex(@(bt) bt.type == nextBulletType) ?? 0
    local switchToBulletIdx = (nextBulletIdx + 1) % (turret.bulletTypes.len() || 1)
    local children = turret.bulletTypes.map(function(bt, btIdx) {
      local isCurrent = curBulletType == bt.type
      local weapon = turret.__merge({
        isCurrent = isCurrent
        isNext = nextBulletType == bt.type
        name = $"{bt.type}/name/short"
        bulletType = bt.type
        curAmmo = turret.ammoByBullet?[btIdx] ?? turret.curAmmo
        instant = true
      })
      return weaponWidget({
        width = vehicleWeaponWidth
        height = hdpx(60)
        weapon = weapon
        hotkey = isCurrent ? turretControlTips.value?[idx]
          : btIdx == switchToBulletIdx ? switchToBulletTip
          : null
        iconCtor = turretIconCtor
      })
    })
    return {
      watch = vehicleMainGunBullet
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      gap = gap
      children = children
    }
  }
}

local mkFaIcon = @(faId, color) {
  rendObj = ROBJ_STEXT
  font = Fonts.fontawesome
  color = color
  minHeight = fontH(100)
  text = fa[faId]
}

local isBurn = ::Computed(@() heroVehicleState.value.isBurn)
local function vehicleHpEffects() {
  local res = { watch = isBurn }
  if (!isBurn.value)
    return res
  return res.__update(mkFaIcon("fire", style.FAIL_TEXT_COLOR))
}

local hitAnimTrigger = "vehicle_hit"
local lastVehicleData = null
local function saveLastVehicleData() {
  lastVehicleData = {
    vehicle = heroVehicleState.value.vehicle
    hp = heroVehicleState.value.hp
  }
}
saveLastVehicleData()
heroVehicleState.subscribe(function(v) {
  if (v.vehicle == lastVehicleData.vehicle && v.hp == lastVehicleData.hp)
    return
  if (v.vehicle == lastVehicleData.vehicle)
    ::anim_start(hitAnimTrigger)
  saveLastVehicleData()
})

local function vehicleHp() {
  local res = { watch = heroVehicleState }
  local { vehicle, hp, maxHp } = heroVehicleState.value
  if (vehicle == INVALID_ENTITY_ID)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gap
    children = [
      hp >= maxHp ? null : mkFaIcon("gear", style.DEFAULT_TEXT_COLOR)
      {
        size = [barWidth, barHeight]
        children = healthBar({ hp = heroVehicleState.value.hp, maxHp = heroVehicleState.value.maxHp,
          hitTrigger = hitAnimTrigger, colorFg = style.DEFAULT_TEXT_COLOR })
      }
    ]
  })
}

return function() {
  local turrets = showVehicleWeapons.value ? {
    flow = FLOW_VERTICAL
    gap = gap
    children = vehicleTurrets.value.turrets.map(vehicleTurretBlock)
  } : null

  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = hdpx(30)
    size = SIZE_TO_CONTENT
    watch = [vehicleTurrets, showVehicleWeapons]

    children = [
      turrets
      {
        size = [SIZE_TO_CONTENT, barBlockHeight]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = gap
        children = [
          vehicleHpEffects
          vehicleHp
        ]
      }
    ]
  }
} 