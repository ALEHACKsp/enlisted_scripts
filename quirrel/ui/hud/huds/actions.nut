  
                                                                    
  

local {pickupItemName, pickupItemEid, useActionEid, lookAtEid, useActionAvailable} = require("ui/hud/state/actions_state.nut")
local {inVehicle, inPlane, planeTas} = require("ui/hud/state/vehicle_state.nut")
local {DEFAULT_TEXT_COLOR} = require("ui/hud/style.nut")
local {tipCmp} = require("tips/tipComponent.nut")
local {teammatesAliveNum} = require("ui/hud/state/human_teammates.nut")
local {sendItemHint} = require("ui/hud/huds/send_quick_chat_msg.nut")
local {isAlive, controlledHeroEid, watchedHeroEid, isDowned} = require("ui/hud/state/hero_state_es.nut")
local isMachinegunner = require("ui/hud/state/machinegunner_state.nut")
local {localPlayerEid, localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {round_by_value} = require("std/math.nut")
local remap_nick = require("globals/remap_nick.nut")
local {sound_play} = require("sound")
local {is_fast_pickup_item} = require("humaninv")
local {
  ACTION_USE, ACTION_EXTINGUISH, ACTION_REPAIR, ACTION_REQUEST_AMMO, ACTION_RECOVER, ACTION_PICK_UP, ACTION_SWITCH_WEAPONS,
  ACTION_OPEN_DOOR, ACTION_CLOSE_DOOR, ACTION_REMOVE_SPRAY, ACTION_DENIED_TOO_MUCH_WEIGHT, ACTION_THROW_BACK,
  ACTION_LOOT_BODY, ACTION_OPEN_WINDOW, ACTION_CLOSE_WINDOW, ACTION_REVIVE_TEAMMATE, ACTION_REFILL_AMMO,
  ACTION_REFILL_DENIED_EMPTY_BOX
  } =  require("hud_actions")

local showTeamQuickHint = Watched(true)
local showTeamEnemyHint = Watched(true)
local teamHintsQuery = ::ecs.SqQuery("teamHintsQuery", {comps_ro =[["team.id", ::ecs.TYPE_INT],["team.showQuickHint", ::ecs.TYPE_BOOL, true], ["team.showEnemyHint", ::ecs.TYPE_BOOL, true]]})

localPlayerEid.subscribe(function(v) {
  if ( v != INVALID_ENTITY_ID ) {
    teamHintsQuery.perform(function (eid, comp) {
        showTeamQuickHint(comp["team.showQuickHint"])
        showTeamEnemyHint(comp["team.showEnemyHint"])
      },
      $"eq(team.id, {localPlayerTeam.value})"
    )
  }
})

local function getItemPrice(entity_eid) {
    local price = ::ecs.get_comp_val(entity_eid, "coinPricePerGame")
    if (price) {
      local discount = ::ecs.get_comp_val(localPlayerEid.value, "coinsGameMult") ?? 1.0;
      return round_by_value(price * discount, 1).tointeger()
    }
    return price
}

local function getPlayerItemOwnerName(entity_eid) {
    local playerItemOwner = ::ecs.get_comp_val(entity_eid, "playerItemOwner")
    return playerItemOwner ? remap_nick(::ecs.get_comp_val(playerItemOwner, "name")) : ::loc("teammate")
}


local pickupkeyId = "Inventory.Pickup"
local forcedPickupkeyId = "Inventory.ForcedPickup"
local usekeyId = "Human.Use"
local meleeKeyId = "Human.Melee"
local extinguishkeyId = "Human.VehicleMaintenance"
local actionsMap = {
  [ACTION_USE] = {
                    textf = function (item) {
                              local customPrompt = ::ecs.get_comp_val(item.useEid, "item.customUsePrompt", "")
                              if (customPrompt && customPrompt.len() > 0)
                                return ::loc(customPrompt, "Press to use")
                              else
                                return ::loc("hud/use", "Press to use")
                            }
                    key = usekeyId
  },
  [ACTION_EXTINGUISH] = {text = ::loc("hud/extinguish", "Hold to extinguish") key = extinguishkeyId},
  [ACTION_REPAIR] = {text = ::loc("hud/repair", "Hold to repair") key = extinguishkeyId},
  [ACTION_REQUEST_AMMO] = {text = ::loc("hud/request_ammo", "Request ammo") key = usekeyId},
  [ACTION_REFILL_AMMO] = {text = ::loc("resupply/ammo_refill", "Refill ammo") key = pickupkeyId},
  [ACTION_PICK_UP] = {
                        keyf = @(item) is_fast_pickup_item(item.eid) ? pickupkeyId : forcedPickupkeyId ,
                        textf = function (item) {
                          local count = ::ecs.get_comp_val(item.eid, "item.count")
                          local altText = ::loc($"{item.itemName}/pickup", {count = count, price = getItemPrice(item.eid), nickname = getPlayerItemOwnerName(item.eid)}, "")
                          if (altText && altText.len() > 0)
                            return altText
                          return is_fast_pickup_item(item.eid)
                            ? ::loc("hud/pickup", "Pickup {item}", item)
                            : ::loc("hud/replaceItem", "Switch to {item}", item)
                        }
                      },
  [ACTION_RECOVER] = {text = ::loc("hud/recover", "Recover"), key = usekeyId},
  [ACTION_SWITCH_WEAPONS] = {
                              keyf = @(item) is_fast_pickup_item(item.eid) ? pickupkeyId : forcedPickupkeyId ,
                              textf = @(params) ::loc("hud/switch_weapons", "Switch weapon to {item}", params)
                             },
  [ACTION_OPEN_DOOR] = {text = ::loc("hud/open_door", "Open door"), key=usekeyId},
  [ACTION_CLOSE_DOOR] = {text = ::loc("hud/close_door", "Close door"), key=usekeyId},
  [ACTION_REMOVE_SPRAY] = {text = ::loc("hud/remove_spray", "Remove spray"), key=usekeyId},
  [ACTION_THROW_BACK] = {text = ::loc("hud/throw_back", "Throw grenade back"), key=meleeKeyId},
  [ACTION_DENIED_TOO_MUCH_WEIGHT] = {
    textf = function(params) {
      params.item = params.item.subst({ nickname = getPlayerItemOwnerName(params.eid) })
      return ::loc("hud/too_much_weight_pickip", "Can't pickup {item} - too much weight", params)
    }
    textColor = Color(120, 120, 120, 120)
  },
  [ACTION_LOOT_BODY] = {text = ::loc("hud/loot_body", "Loot body") key = usekeyId},
  [ACTION_OPEN_WINDOW] = {text = ::loc("hud/open_window", "Open window"), key=usekeyId},
  [ACTION_CLOSE_WINDOW] = {text = ::loc("hud/close_window", "Close window"), key=usekeyId},
  [ACTION_REVIVE_TEAMMATE] = {text = ::loc("hud/revive_teammate", "Revive teammate"), key=usekeyId},
  [ACTION_REFILL_DENIED_EMPTY_BOX] = {
    text = ::loc("resupply/ammo_crate_empty", "The ammunition crate is empty")
    textColor = Color(120, 120, 120, 120)
  },
}

local triggerBlinkAnimations = {}
local listnerForPickupAction = {
  eventHandlers = {["Inventory.Pickup"] = @(...) ::anim_start(triggerBlinkAnimations),}
}
local blinkAnimations = [
  { prop=AnimProp.translate, from=[0,0], to=[hdpx(20),0], duration=0.7, trigger = triggerBlinkAnimations, easing=Shake4, onEnter = @() sound_play("ui/enlist/login_fail")}
]

local showExitAction = ::Computed(@() !inPlane.value || planeTas.value < 1.0 )

local function mainAction() {
  local res = {
    size = SIZE_TO_CONTENT
    watch = [isDowned, pickupItemEid, pickupItemName, useActionAvailable, inVehicle, showExitAction, useActionEid]
  }
  if (isDowned.value)
    return res

  local children = []
  local curAction = useActionAvailable.value
  local actScheme = actionsMap?[curAction]
  local text = actScheme?.text
  local isVisible = true
  if (text == null && "textf" in actScheme) {
    text = actScheme.textf({ eid=pickupItemEid.value, item=::loc(pickupItemName.value), itemName=pickupItemName.value, useEid=useActionEid.value })
  }
  local key = actScheme?.key
  if (key == null && "keyf" in actScheme) {
    key = actScheme.keyf({ eid=pickupItemEid.value })
  }
  if (curAction == ACTION_USE && inVehicle.value) {
    text = ::loc("hud/leaveVehicle")
    isVisible = showExitAction.value
  }

  children = !isVisible ? [] : [tipCmp({
    text = text
    inputId = key
    textColor = actScheme?.textColor ?? DEFAULT_TEXT_COLOR
    extraAnimations = blinkAnimations
  })]

  if (curAction == ACTION_SWITCH_WEAPONS || key == forcedPickupkeyId)
    children.append(listnerForPickupAction)
  return res.__update({ children = children  })
}

local function getUseActionEntityName(entity_eid) {
  local vehicleTag = ::ecs.get_comp_val(entity_eid, "vehicle", null)
  if (vehicleTag != null)
    return !inVehicle.value ? "hud/teammates_vehicle_hint" : null
  local reviveEntity = ::ecs.get_comp_val(entity_eid, "reviveEntity", null)
  if (reviveEntity != null)
    return "hud/respawn_altar_hint"
  local stationaryGunTag = ::ecs.get_comp_val(entity_eid, "stationary_gun", null)
  if (stationaryGunTag != null)
    return !isMachinegunner.value ? "hud/stationary_gun_hint" : null
  return null
}

local function sendTeamHint(useHintEid, event){
  if (pickupItemEid.value != INVALID_ENTITY_ID) {
    local playerItemOwner = ::ecs.get_comp_val(pickupItemEid.value, "playerItemOwner")
    local nickname = playerItemOwner ? remap_nick(::ecs.get_comp_val(playerItemOwner, "name")) : ::loc("teammate")
    sendItemHint(pickupItemName.value, pickupItemEid.value,
      ::ecs.get_comp_val(pickupItemEid.value, "item.count"), nickname)
    return
  }
  if (useHintEid != INVALID_ENTITY_ID) {
    local name = getUseActionEntityName(useHintEid)
    if (name != null) {
      sendItemHint(name, useHintEid, 1, "")
      return
    }
  }
  ::ecs.g_entity_mgr.sendEvent(controlledHeroEid.value, ::ecs.event.CmdSetMarkMain({plEid = localPlayerEid.value}))
}

local function localTeamHint(){
  local children = {}
  local useHintEid = INVALID_ENTITY_ID;
  if ((pickupItemName.value ?? "") != "" && teammatesAliveNum.value > 0) {
    local playerItemOwner = ::ecs.get_comp_val(pickupItemEid.value, "playerItemOwner")
    local nickname = playerItemOwner ? remap_nick(::ecs.get_comp_val(playerItemOwner, "name")) : ::loc("teammate")
    children = tipCmp({
      text = ::loc("squad/send_item_hint", {item = ::loc(pickupItemName.value),
                                            count=::ecs.get_comp_val(pickupItemEid.value, "item.count"),
                                            nickname=nickname})
      inputId = "HUD.QuickHint"
      textColor = DEFAULT_TEXT_COLOR
    })
  } else {
    useHintEid = useActionEid.value != INVALID_ENTITY_ID ? useActionEid.value : lookAtEid.value;
    if (useHintEid && teammatesAliveNum.value > 0) {
      local name = getUseActionEntityName(useHintEid)
      if (name != null) {
        children = tipCmp({
          text = ::loc("squad/send_item_hint", {item = ::loc(name), count=1, nickname = ::loc("teammate")})
          inputId = "HUD.QuickHint"
          textColor = DEFAULT_TEXT_COLOR
        })
      }
    }
  }
  children.__update({eventHandlers = {["HUD.QuickHint"] = ::curry(sendTeamHint)(useHintEid)}})
  return {
    children = showTeamQuickHint.value ? children : null
    watch = [showTeamQuickHint, teammatesAliveNum, pickupItemName, pickupItemEid, useActionEid, lookAtEid, inVehicle, isMachinegunner]
    size = SIZE_TO_CONTENT
  }
}

local function setEnemyHint(event){
  ::ecs.g_entity_mgr.sendEvent(controlledHeroEid.value, ::ecs.event.CmdSetMarkEnemy({plEid = localPlayerEid.value}))
}
local teamEnemyHint = { eventHandlers = {["HUD.SetMarkEnemy"] = setEnemyHint}}

local function localTeamEnemyHint(){
  return {
    watch = [showTeamEnemyHint]
    children = showTeamEnemyHint.value ? teamEnemyHint : null
    size = SIZE_TO_CONTENT
  }
}

local mkActionsRoot = @(actions) @() {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM

  watch = [isAlive, controlledHeroEid, watchedHeroEid]
  children = (isAlive.value && controlledHeroEid.value == watchedHeroEid.value)
    ? {
        size=SIZE_TO_CONTENT
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = actions
      }
    : null
}

return {
  mkActionsRoot = mkActionsRoot
  mainAction = mainAction
  localTeamHint = localTeamHint
  localTeamEnemyHint = localTeamEnemyHint

  allActions = mkActionsRoot([mainAction, localTeamHint, localTeamEnemyHint])
} 