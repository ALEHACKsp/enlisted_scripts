require("enlisted/enlist/soldiers/model/onlyInEnlistVm.nut")("clientApi")

local ipc = require("ipc")
local ipc_hub = require("ui/ipc_hub.nut")
local profile = require("servProfile.nut")
local rand = require("std/rand.nut")()
local { updateAllConfigs } = require("enlisted/enlist/configs/configs.nut")

local requestData = persist("requestData", @() { id = rand.rint(), callbacks = {}})
local debugDelay = persist("debugDelay", @() ::Watched(0))

local function handleMessages(msg) {
  local result = msg.data?.result
  local cb = requestData.callbacks?[msg.id]
  if (!result) {
    local errorStr = msg.data?.error?.message ?? "unknown error"
    if (cb)
      cb({ error = errorStr })
    return
  }

  local isFullUpdate = result?.full ?? false
  if (isFullUpdate) {
    log("Full profile received")
    foreach (k,v in profile) {
      v.value.clear()
    }
  }

  foreach (k,v in profile) {
    local res = result?[k]
    if (res)
      v.value.__update(res)
  }

  foreach (k,v in profile)
    if (isFullUpdate || (result?[k] ?? {}).len() > 0)
      v.trigger()

  if (result?.configs != null)
    updateAllConfigs(result)

  if (cb) {
    delete requestData.callbacks[msg.id]
    cb(result)
  }
}

ipc_hub.subscribe("profile_srv.response", handleMessages)

local function requestImpl(data, cb = null) {
  requestData.id = requestData.id + 1
  local idStr = requestData.id.tostring()
  if (cb) {
    requestData.callbacks[idStr] <- cb
  }

  ipc.send({
    msg = "profile_srv.request"
    id = idStr
    data = data
  })
}

local request = requestImpl
local function updateDebugDelay() {
  request = (debugDelay.value <= 0) ? requestImpl
    : @(data, cb = null) ::gui_scene.setTimeout(debugDelay.value, @() requestImpl(data, cb))
}
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

console.register_command(@(delay) debugDelay(delay), "pserver.delay_requests")

return {
  profile = profile

  update_profile  = @(cb = null, token = null) request({ method = "get", token = token }, cb)
  get_all_configs = @(cb = null, token = null) request({ method = "get_all_configs", token = token }, cb)
  check_purchases = @() request({ method = "check_purchases" })

  equip_item = @(target, item, slot, index, cb = null) request({
    method = "equip_item"
    params = {
      target = target
      item = item
      slot = slot
      index = index ?? -1
  }}, cb)

  set_soldier_to_squad = @(soldier, ind, squad) request({
    method = "set_soldier_to_squad"
    params = {soldier = soldier, ind=ind, squad=squad}
  })

  set_vehicle_to_squad = @(vehicle, squad)  request({
    method = "set_vehicle_to_squad"
    params = {vehicle = vehicle, squad=squad}
  })

  set_squad_order = @(armyId, orderedGuids, cb = null) request({
    method = "set_squad_order"
    params = {armyId = armyId, orderedGuids = orderedGuids}
  }, cb)

  set_soldier_order = @(squad, orderedGuids, cb = null)  request({
    method = "set_soldier_order"
    params = {squad = squad, orderedGuids = orderedGuids}
  }, cb)

  set_reserve_order = @(armyId, orderedGuids, cb = null) request({
    method = "set_reserve_order"
    params = {armyId = armyId, orderedGuids = orderedGuids}
  }, cb)

  manage_squad_soldiers = @(armyId, squadGuid, squadSoldiers, reserveSoldiers, cb = null) request({
    method = "manage_squad_soldiers"
    params = {
      armyId = armyId, squadGuid = squadGuid,
      squadSoldiers = squadSoldiers, reserveSoldiers = reserveSoldiers
    }
  }, cb)

  swap_squad_and_reserve_soldiers = @(armyId, fromGuid, toGuid, cb = null) request({
    method = "swap_squad_and_reserve_soldiers"
    params = {armyId = armyId, fromGuid = fromGuid, toGuid = toGuid}
  }, cb)

  add_soldier_to_squad_from_reserve = @(armyId, squadGuid, soldierGuid, cb = null) request({
    method = "add_soldier_to_squad_from_reserve"
    params = { armyId = armyId, squadGuid = squadGuid, soldierGuid = soldierGuid }
  }, cb)

  move_soldier_to_reserve = @(armyId, soldierGuid, reserveIdx, cb = null) request({
    method = "move_soldier_to_reserve"
    params = { armyId = armyId, soldierGuid = soldierGuid, reserveIdx = reserveIdx }
  }, cb)

  dismiss_reserve_soldier = @(armyId, soldierGuid, cb = null) request({
    method = "dismiss_reserve_soldier"
    params = { armyId = armyId, soldierGuid = soldierGuid }
  }, cb)

  swap_items = @(soldier1, slot1, index1, soldier2, slot2, index2, cb = null) request({
    method = "swap_items"
    params = {
        soldier1 = soldier1,
        slot1 = slot1,
        index1 = index1 ?? -1,
        soldier2 = soldier2,
        slot2 = slot2,
        index2 = index2 ?? -1
    }
  }, cb)

  drop_items = @(armyId, dropCrateId, cb = null) request({
    method = "drop_items"
    params = { army = armyId, dropCrate = dropCrateId ?? "" }
  }, cb)

  get_crates_content = @(armyId, crates, cb) request({
    method = "get_crates_content"
    params = { armyId = armyId, crates = crates }
  }, cb)

  add_items_by_type = @(armyId, itemType, count, cb = null) request({
    method = "add_items_by_type"
    params = { armyId, itemType, count }
  }, cb)

  add_army_exp = @(armyId, exp, cb) request({
    method = "add_army_exp"
    params = { armyId = armyId, exp = exp }
  }, cb)

  buy_army_exp = @(armyId, exp, cost, cb = null) request({
    method = "buy_army_exp"
    params = { armyId = armyId, exp = exp, cost = cost }
  }, cb)

  buy_squad_exp = @(armyId, squadId, exp, cost, cb = null) request({
    method = "buy_squad_exp"
    params = { armyId = armyId, squadId = squadId, exp = exp, cost = cost }
  }, cb)

  buy_soldier_exp = @(guid, exp, cost, cb = null) request({
    method = "buy_soldier_exp"
    params = { guid = guid, exp = exp, cost = cost }
  }, cb)

  buy_soldier_max_level = @(guid, cost, cb = null) request({
    method = "buy_soldier_max_level"
    params = { guid = guid, cost = cost }
  }, cb)

  unlock_squad = @(armyId, squadId, cb) request({
    method = "unlock_squad"
    params = { armyId = armyId, squadId = squadId }
  }, cb)

  get_army_rewards = @(armyId, cb) request({
    method = "get_army_rewards"
    params = { armyId = armyId }
  }, cb)

  get_army_level_reward = @(armyId, unlockGuid, cb = null) request({
    method = "get_army_level_reward"
    params = { armyId = armyId, unlockGuid = unlockGuid }
  }, cb)

  barter_shop_item = @(armyId, shopItemGuid, payItems, cb = null) request({
    method = "barter_shop_item"
    params = {
      armyId = armyId
      shopItemGuid = shopItemGuid
      payItems = payItems
    }
  }, cb)

  buy_shop_item = @(armyId, shopItemGuid, currencyId, price, cb = null) request({
    method = "buy_shop_item"
    params = {
      armyId = armyId
      shopItemGuid = shopItemGuid
      currencyId = currencyId
      price = price
    }
  }, cb)

  reset_profile = @(cb) request({
    method = "reset_profile"
    params = {}
  }, cb)

  soldiers_regenerate_view = @(cb = null) request({
    method = "soldiers_regenerate_view"
    params = {}
  }, cb)

  begin_training = @(soldiers, cb) request({
    method = "begin_training"
    params = { soldiers = soldiers }
  }, cb)

  cancel_training = @(training, cb) request({
    method = "cancel_training"
    params = { training = training }
  }, cb)

  end_training = @(trainingGuid, cb) request({
    method = "end_training"
    params = { trainingGuid = trainingGuid }
  }, cb)

  buy_end_training = @(trainingGuid, cost, cb) request({
    method = "buy_end_training"
    params = { trainingGuid = trainingGuid, cost = cost }
  }, cb)

  add_exp_to_soldiers = @(list, cb) request({
    method = "add_exp_to_soldiers"
    params = { list = list }
  }, cb)

  get_perks_choice = @(soldierGuid, tierIdx, slotIdx, cb) request({
    method = "get_perks_choice"
    params = { soldierGuid = soldierGuid, tierIdx = tierIdx, slotIdx = slotIdx }
  }, cb)

  choose_perk = @(soldierGuid, tierIdx, slotIdx, perkId, cb) request({
    method = "choose_perk"
    params = { soldierGuid = soldierGuid, tierIdx = tierIdx, slotIdx = slotIdx, perkId = perkId }
  }, cb)

  change_perk_choice = @(soldierGuid, tierIdx, slotIdx, cost, cb) request({
    method = "change_perk_choice"
    params = { soldierGuid = soldierGuid, tierIdx = tierIdx, slotIdx = slotIdx, cost = cost }
  }, cb)

  add_army_squad_exp_by_id = @(armyId, exp, squadId, cb = null) request({
    method = "add_army_squad_exp_by_id"
    params = { armyId = armyId, exp = exp, squadId = squadId }
  }, cb)

  research = @(armyId, researchId, cb = null) request({
    method = "research"
    params = {armyId = armyId, researchId = researchId}
  }, cb)

  request_delivery = @(armyId, category, cb = null) request({
    method = "request_delivery"
    params = {armyId = armyId, category = category}
  }, cb)

  open_delivery = @(guid, cb = null) request({
    method = "open_delivery"
    params = {guid = guid}
  }, cb)

  purchase_delivery = @(guid, cost, cb = null) request({
    method = "purchase_delivery"
    params = {guid = guid, cost = cost}
  }, cb)

  disassemble_item = @(armyId, itemGuid, cb = null) request({
    method = "disassemble_item"
    params = { armyId = armyId, itemGuid = itemGuid }
  }, cb)

  upgrade_item = @(armyId, itemGuid, sacrificeItems, cb = null) request({
    method = "upgrade_item"
    params = { armyId = armyId, itemGuid = itemGuid, sacrificeItems = sacrificeItems }
  }, cb)

  gen_perks_points_statistics = @(tier, count, genId, cb) request({
    method = "gen_perks_points_statistics"
    params = {tier = tier, count = count, genId = genId }
  }, cb)

  get_squads_data_by_armies  = @(armies, cb) request({
    method = "get_squads_data_by_armies"
    params = {armies = armies}
  }, cb)

  get_squads_data_by_armies_jwt = @(armies, cb) request({
    method = "get_squads_data_by_armies_jwt"
    params = {armies = armies}
  }, cb)

  get_profile_data_jwt = @(armies, cb) request({
    method = "get_profile_data_jwt"
    params = {armies = armies}
  }, cb)

  gen_default_profile = @(armies, cb) request({
    method = "gen_default_profile"
    params = {armies = armies}
  }, cb)

  mark_as_seen = @(itemsGuids, soldiersGuids = [], cb = null) request({
    method = "mark_as_seen"
    params = {itemsGuids = itemsGuids, soldiersGuids = soldiersGuids}
  }, cb)

  reward_single_player_mission = @(missionId, armyId, squads, soldiers, cb = null) request({
    method = "reward_single_player_mission"
    params = {
      missionId = missionId,
      armyId = armyId,
      squads = squads,
      soldiers = soldiers
    }
  }, cb)

  cheat_premium_add = @(durationSec, cb = null) request({
    method = "cheat_premium_add"
    params = { duration = durationSec }
  }, cb)

  cheat_premium_remove = @(durationSec, cb = null) request({
    method = "cheat_premium_remove"
    params = { duration = durationSec }
  }, cb)
}
 