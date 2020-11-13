local { Point3 } = require("dagor.math")
local { RqCancelContextCommand, RequestSquadMateOrder } = require("gameevents")
local { CmdWallposterPreview } = require("wallposterevents")
local { pieMenuItems, showPieMenu } = require("ui/hud/state/pie_menu_state.nut")
local { controlledHeroEid, isDowned, isAlive, hp, maxHp } = require("ui/hud/state/hero_state_es.nut")
local { inVehicle } = require("ui/hud/state/vehicle_state.nut")
local { weaponsList } = require("ui/hud/state/hero_state.nut")
local weaponSlots = require("globals/weapon_slots.nut")
local { requestAmmoTimeout } = require("state/requestAmmoState.nut")
local { localPlayerSquadMembers } = require("state/squad_members.nut")
local { playerEvents } = require("ui/hud/state/eventlog.nut")
local { isLeaderNeedsAmmo, hasSpaceForMagazine, isCompatibleWeapon } = require("enlisted/ui/hud/state/hero_squad.nut")
local { artilleryIsReady, artilleryIsAvailable, artilleryAvailableTimeLeft, isHeroRadioman, wasArtilleryAvailableForSquad
} = require("enlisted/ui/hud/state/artillery.nut")
local { wallPostersMaxCount, wallPostersCurCount, wallPosters } = require("enlisted/ui/hud/state/wallposter.nut")
local { showWallposterMenu } = require("enlisted/ui/hud/state/wallposter_menu.nut")
local { localPlayerEid } = require("ui/hud/state/local_player.nut")
local { get_controlled_hero } = require("globals/common_queries.nut")
local { secondsToStringLoc } = require("utils/time.nut")
local colorize = require("enlist/colorize.nut")
local {ESMO_BRING_AMMO, ESMO_ARTILLERY, ESMO_HEAL} = require("ai")

local pieMenuTextItemCtor = require("components/pieMenuTextItemCtor.nut")


local noMembersColor = 0xFFFF6060

local hasActive = ::Computed(@() (localPlayerSquadMembers.value ?? [])
  .reduce(@(res, m) m.eid != controlledHeroEid.value && m.isAlive ? res + 1 : res, 0)
  > 0)
local noActive = ::Computed(@() !hasActive.value)
local noMembersText = ::Computed(@() hasActive.value ? null
  : colorize(noMembersColor, ::loc("msg/noAliveMembersToOrder")))

local sendCmd = @(orderType)
  ::ecs.g_entity_mgr.sendEvent(::ecs.get_comp_val(controlledHeroEid.value, "squad_member.squad", INVALID_ENTITY_ID),
    RequestSquadMateOrder(orderType, Point3(), INVALID_ENTITY_ID))

local showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })

local addTextCtor = @(cmd) cmd.__update({ ctor = pieMenuTextItemCtor(cmd) })


local cmdFollowMe = addTextCtor({
  action = @() ::ecs.g_entity_mgr.sendEvent(controlledHeroEid.value, RqCancelContextCommand(true))
  text = ::Computed(@() ::loc("squad_orders/follow"))
  disabledtext = noMembersText
  closeOnClick = true
  available = hasActive
  isBlocked = noActive
})


local canRequestAmmo = ::Computed(@() isLeaderNeedsAmmo.value && requestAmmoTimeout.value <= 0 && hasActive.value)
local cantRequestAmmoText = ::Computed(@() (isLeaderNeedsAmmo.value && requestAmmoTimeout.value > 0
    ? ::loc("msg/canRequestIn", { time = secondsToStringLoc(requestAmmoTimeout.value) })
    : null))

local function requestAmmoReason() {
  if (inVehicle.value)
    return ::loc("msg/cannotRequestAmmoFromVehicle")
  if (!weaponsList.value?[weaponSlots.EWS_PRIMARY]?.itemPropsId)
    return ::loc("msg/hasNoWeaponForAmmoRequest")
  if (!isCompatibleWeapon.value)
    return ::loc("msg/cantRequestAmmoForThisWeapon")
  if (!hasSpaceForMagazine.value)
    return ::loc("msg/hasNoSpaceForMagazine")
  return ::loc("msg/hasAmmo")
}

local cmdBringAmmo = addTextCtor({
  action = @() sendCmd(ESMO_BRING_AMMO)
  disabledAction = @() showMsg(isLeaderNeedsAmmo.value
    ? ::loc("msg/canRequestIn", { time = secondsToStringLoc(requestAmmoTimeout.value) })
    : requestAmmoReason())
  text = ::Computed(@() "\n".concat(::loc("squad_orders/bring_ammo"), cantRequestAmmoText.value ?? ""))
  disabledtext = ::Computed(@() noMembersText.value ?? cantRequestAmmoText.value ?? ::loc("pieMenu/actionUnavailable"))
  closeOnClick = true
  available = canRequestAmmo
  isBlocked = noActive
})


local function artillery_action() {
  if (isHeroRadioman.value)
    ::ecs.g_entity_mgr.sendEvent(get_controlled_hero(), ::ecs.event.CmdArtillerySelfOrder())
  else
    sendCmd(ESMO_ARTILLERY)
}

local cantRequestArtilleryText = ::Computed(@()
  (!isDowned.value && artilleryIsAvailable.value && artilleryAvailableTimeLeft.value > 0
    ? ::loc("artillery/cooldown", { timeLeft = secondsToStringLoc(artilleryAvailableTimeLeft.value) })
    : null))

local function showDisabledArtilleryHint() {
  if (!artilleryIsAvailable.value || isDowned.value)
    showMsg(::loc("msg/artilleryUnavailable"))
  else if (!artilleryIsReady.value)
    ::ecs.g_entity_mgr.sendEvent(localPlayerEid.value, ::ecs.event.CmdShowArtilleryCooldownHint())
}

local cmdArtillery = addTextCtor({
  action = @() artillery_action()
  disabledAction = @() showDisabledArtilleryHint()
  text = ::Computed(@() cantRequestArtilleryText.value ?? ::loc("squad_orders/artillery_strike"))
  disabledtext = ::Computed(@() (isHeroRadioman.value ? null : noMembersText.value)
    ?? cantRequestArtilleryText.value
    ?? ::loc("pieMenu/actionUnavailable"))
  closeOnClick = true
  available = ::Computed(@() !isDowned.value && artilleryIsReady.value
    && (isHeroRadioman.value || hasActive.value))
  isBlocked = ::Computed(@() !isHeroRadioman.value && !hasActive.value)
})


local healCount = ::Computed(@() (localPlayerSquadMembers.value ?? [])
  .reduce(@(res, m) m.eid != controlledHeroEid.value && m.isAlive ? res + m.targetHealCount : res, 0))
local reviveCount = ::Computed(@() (localPlayerSquadMembers.value ?? [])
  .reduce(@(res, m) m.eid != controlledHeroEid.value && m.isAlive ? res + m.targetReviveCount : res, 0))
local canRequestHeal = ::Computed(@() hasActive.value && isAlive.value
  && ((isDowned.value && reviveCount.value > 0)
    || ((hp.value ?? 0) < maxHp.value && healCount.value > 0)))
local textWithInfo = @(text, info) $"{text} ({info})"

local cmdHeal = addTextCtor({
  action = @() sendCmd(ESMO_HEAL)
  disabledAction = function() {
    if ((hp.value ?? 0) >= maxHp.value)
      showMsg(::loc("msg/noNeedHeal"))
    else if (!hasActive.value)
      showMsg(::loc("msg/noAliveMembersToOrder"))
    else if (isDowned.value ? reviveCount.value <= 0 : healCount.value <= 0)
      showMsg(::loc("msg/noMedkits"))
  }
  text = ::Computed(@() isDowned.value ? textWithInfo(::loc("squad_orders/revive_me"), reviveCount.value)
      : textWithInfo(::loc("squad_orders/heal_me"), healCount.value))
  disabledtext = ::Computed(@() noMembersText.value ?? ::loc("pieMenu/actionUnavailable"))
  available = canRequestHeal
  isBlocked = noActive
  closeOnClick = true
})

local cmdWallPoster = addTextCtor({
  action = @() (wallPosters.value.len() > 1) ?
    showWallposterMenu(true) : ::ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdWallposterPreview(true, 0))
  disabledAction = function() {
    if (wallPostersCurCount.value >= wallPostersMaxCount.value)
      showMsg(::loc("wallposter/nomore"))
  }
  text = ::Computed(@() textWithInfo(::loc("wallposter/place"), wallPostersMaxCount.value - wallPostersCurCount.value))
  disabledtext = ::loc("pieMenu/actionUnavailable")
  available = ::Computed(@() isAlive.value && !isDowned.value && (wallPostersMaxCount.value > 0) && (wallPostersCurCount.value < wallPostersMaxCount.value))
  isBlocked = ::Computed(@() !isAlive.value || isDowned.value)
  closeOnClick = true
})

local baseCmds = [
  cmdFollowMe
  cmdBringAmmo
  cmdHeal
]

local specialCmdsPlaces = 1
local specialCmds = ::Computed(function() {
  local res = []
  if (wasArtilleryAvailableForSquad.value)
    res.append(cmdArtillery)
  if (wallPostersMaxCount.value > 0)
    res.append(cmdWallPoster)

  if (res.len() < specialCmdsPlaces)
    res.resize(specialCmdsPlaces)
  return res
})

local curCmds = keepref(::Computed(@() (clone baseCmds).extend(specialCmds.value)))
pieMenuItems(curCmds.value)
curCmds.subscribe(function(v) {
  pieMenuItems(v)
  if (v.len() == 0)
    showPieMenu(false)
})
 