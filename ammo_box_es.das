require ecs
require ecs.common
require game.es.events
require game.es.inventory_common
require enlisted.game.es.enlisted_events
require game.utils.team
require HumanPhys

[private]
def is_owned_by_the_same_team(team; owner)
  var ownerTeam = TEAM_UNASSIGNED
  ecs::query(owner) <| $ [es] (team: int)
    ownerTeam = team
  return ownerTeam != TEAM_UNASSIGNED && team == ownerTeam

[private]
def is_ammo_for_gun(ammo_props_id; ammo_prop_ids)
  for ammoPropsId in ammo_prop_ids
    if ammoPropsId == ammo_props_id
      return true
  return false

[private]
def refill_ammo(requester; count; ammoTemplate; var itemContainer)
  for i in range(0, count)
    push_item_in_cont(requester, ammoTemplate, itemContainer)
  return count > 0

[private]
def get_empty_magazines_count(itemContainer; gunEid; maxMagazinesCount; team)
  var curMagazinesCount = 0
  ecs::query(gunEid) <| $ [es] (gun_dot_ammo_prop_ids: ecs::IntList; ownedByTeam: int)
    if ownedByTeam != team
      return
    for itemEid in itemContainer
      let ammoPropsId = get_int(itemEid, "item.ammoPropsId") ?? -1
      if ammoPropsId >= 0 && is_ammo_for_gun(ammoPropsId, gun_dot_ammo_prop_ids)
        curMagazinesCount++
  return max(maxMagazinesCount - curMagazinesCount, 0)

[private]
def try_to_refill_ammo(requester, ammoBoxOwner)
  var isAmmoRefilled = false
  ecs::query(requester) <| $ [es] (var itemContainer: EidList;
                                   human_weap_dot_weapInfo: ecs::Array;
                                   human_weap_dot_gunEids: ecs::EidList;
                                   team: int)
    if !is_owned_by_the_same_team(team, ammoBoxOwner)
      return
    for slotId in [[HUWeaponSlots[2] (HUWeaponSlots EWS_PRIMARY); (HUWeaponSlots EWS_SECONDARY)]]
      let weapInfo& = human_weap_dot_weapInfo[int(slotId)]
      let ammoTemplate = get_string(get_ecs_object(weapInfo), "reserveAmmoTemplate", "")
      if ammoTemplate == ""
        continue
      let gunEid  = human_weap_dot_gunEids[int(slotId)]
      let maxAmmo = get_int(get_ecs_object(weapInfo), "numReserveAmmo") ?? 0
      let emptyMagazinesCount = get_empty_magazines_count(itemContainer, gunEid, maxAmmo, team)
      isAmmoRefilled ||= refill_ammo(requester, emptyMagazinesCount, ammoTemplate, itemContainer)
  return isAmmoRefilled

[es (tag=server)]
def ammo_box_use_request_es_event_handler(evt: CmdUse; var ammoRefillCount: int&; buildByPlayer: ecs::EntityId)
  let requester = evt.requesterEid
  if !requester || ammoRefillCount <= 0
    return

  if !try_to_refill_ammo(requester, buildByPlayer)
    sendEvent(requester, [[CmdHeroLogEvent event="ammo_full", text="resupply/ammo_full"]])
    return

  ammoRefillCount -= 1

[es (tag=gameClient, track=ammoRefillCount)]
def destroy_markers_for_empty_box(evt: Event; ammoRefillCount: int; var minimap_dot_visibleForAll: bool&)
  if ammoRefillCount <= 0
    minimap_dot_visibleForAll = false

[es (tag=gameClient, track=ammoRefillCount)]
def apply_amimvars_for_empty_box_es(evt: Event; eid: ecs::EntityId; ammoRefillCount: int)
  if ammoRefillCount <= 0
    sendEvent(eid, [[EventApplyCustomAnimcharVars]])

[es (tag=server)]
def set_owned_by_team_to_gun(evt: EventEntityCreated; gun_dot_owner: EntityId; var ownedByTeam: int&)
  query(gun_dot_owner) <| $[es](team: int)
    ownedByTeam = team
