require ecs
require ecs.common
require DagorSystem
require game.es.events
require game.es.vehicle.vehicle_events

def get_item_sub_template(itemTemplate; slot) : string
  let tpl = getTemplateByName(itemTemplate)
  if tpl == null
    logerr("Cannot create an equipment: template '{itemTemplate}' is not found for the slot '{slot}'")
    return ""

  return get_string(getTemplateComponent(tpl, "item.recreateInEquipment"), "base_vis_item")

[event(unicast)]
struct EventOnAllItemsCreated {}

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def spawn_soldier(evt: Event; eid: EntityId; var soldierComponents: Object; var equipmentLeftToCreate: int&)
  var equipment           & = *getRW_ecs_object(soldierComponents, "human_equipment.initialEquip")
  var equipmentComponents & = *getRW_ecs_object(soldierComponents, "human_equipment.initialEquipComponents")

  equipmentLeftToCreate = length(equipment)

  let spawnerEid = eid
  for kv in equipment
    let gametempate = kv.key
    let slot := string(*get_ecs_string(kv.value))
    let addTemplate = get_item_sub_template(gametempate, slot)

    var finalizeCreation <- @ <| (itemEid: EntityId)
      ecs::query(spawnerEid) <| $[es](var equipmentEids: Object; var equipmentLeftToCreate: int&)
        set(equipmentEids, slot, itemEid)
        equipmentLeftToCreate -= 1
        if equipmentLeftToCreate <= 0
          sendEvent(spawnerEid, [[EventOnAllItemsCreated]])

    createEntity("{gametempate}+{addTemplate}", finalizeCreation) <| $(var init: ComponentsInitializer)
      let components = get_ecs_object(equipmentComponents, gametempate)
      if components != null
        let tpl = getTemplateByName(gametempate)
        for comp in *components
          if templateHasComponent(tpl, comp.key)
            set(init, comp.key, comp.value)

  clear(equipment)
  clear(equipmentComponents)

def init_item_container(eid)
  ecs::query(eid) <| $[es](var itemContainer: EidList)
    for itemEid in itemContainer
      ecs::query(itemEid) <| $[es](var item_dot_lastOwner: EntityId&)
        item_dot_lastOwner = eid

[es (tag=server, on_event=EventOnAllItemsCreated)]
def spawn_soldier_done(evt: Event;
                       eid: EntityId;
                       soldierTemplate: string;
                       soldierComponents: Object;
                       playerEid: EntityId;
                       squadEid: EntityId;
                       useVechicle: EntityId;
                       soldierIndexInSquad: int;
                       shouldBePossessed: bool)
  let spawnerEid = eid
  var finalizeCreation <- @ <| (soldierEid: EntityId)
    ecs::query(spawnerEid) <| $[es](equipmentEids: Object)
      for item in equipmentEids
        let itemEid = *get_Eid(item.value)
        sendEventImmediate(soldierEid, [[CmdEquipItemDirect itemEid=itemEid, slot=item.key, allowReorderSlots=false]])
        ecs::query(itemEid) <| $[es](var skeleton_attach_dot_attached: bool&;
                                     var slot_attach_dot_attachedTo: EntityId&;
                                     var skeleton_attach_dot_attachedTo: EntityId&;
                                     var slot_attach_dot_inAttachedList: EntityId&)
          slot_attach_dot_attachedTo = soldierEid
          skeleton_attach_dot_attached = true
          skeleton_attach_dot_attachedTo  = soldierEid
          slot_attach_dot_inAttachedList = soldierEid
        ecs::query(itemEid) <| $[es](footprintType: int)
          let itemFootprintType = footprintType
          ecs::query(soldierEid) <| $[es](var footprintType: int&)
            footprintType = itemFootprintType
      if shouldBePossessed
        sendEventImmediate(playerEid, [[CmdPossessEntity possessedEid=soldierEid]])
        ecs::query(squadEid) <| $[es](var squad_dot_leader: EntityId&) { squad_dot_leader = soldierEid; }

      init_item_container(soldierEid)

      if useVechicle != INVALID_ENTITY_ID
        sendEventImmediate(playerEid, [[CmdUseVehiceOnSpawn possessed=soldierEid, squad=squadEid, vehicle=useVechicle, seatOrderNo=soldierIndexInSquad]])

    destroyEntity(spawnerEid)

  let tpl = getTemplateByName(soldierTemplate)
  createEntity(soldierTemplate, finalizeCreation) <| $(var init: ComponentsInitializer)
    for comp in soldierComponents
      if templateHasComponent(tpl, comp.key)
        set(init, comp.key, comp.value)
