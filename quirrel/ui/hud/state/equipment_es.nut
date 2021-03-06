local {EventHeroChanged} = require("gameevents")
local {Point2} = require("dagor.math")
local {watchedHeroEid} = require("hero_state_es.nut")
local emptyArray = []

local equipment = Watched({})
local get_item_info_query = ::ecs.SqQuery("get_item_info_query", {
  comps_ro = [
    ["item.iconOffset", ::ecs.TYPE_POINT2, Point2(0,0)],
    ["item.name", ::ecs.TYPE_STRING, ""],
    ["animchar.res", ::ecs.TYPE_STRING, ""],
    ["item.iconYaw", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconPitch", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconRoll", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconScale", ::ecs.TYPE_FLOAT, 1.0],
    ["item.volume", ::ecs.TYPE_FLOAT, 0.0],
    ["item.weight", ::ecs.TYPE_FLOAT, 0.0],
    ["animchar.objTexReplace", ::ecs.TYPE_OBJECT, null],
  ]
})

local get_heroslots_info_query = ::ecs.SqQuery("get_heroslots_info_query", {
  comps_ro = [
    ["human_equipment.slots", ::ecs.TYPE_OBJECT],
    ["human_inventory.capacity", ::ecs.TYPE_FLOAT, 0.0]
  ],
  comps_rq = ["watchedByPlr"]
})

local function get_item_info(item_eid) {
  return get_item_info_query.perform(item_eid, function(eid, comp) {
    local iconOffs = comp["item.iconOffset"]
    local equipmentSlots = ::ecs.get_comp_val(eid, "item.equipToSlots")?.getAll?()

    local objTexReplace = comp["animchar.objTexReplace"] ?? []
    local objTexReplaceS = []
    foreach(from, to in objTexReplace)
      objTexReplaceS.append("objTexReplace:t={0};objTexReplace:t={1};".subst(from, to))

    return {
      eid = eid
      equipmentSlots = equipmentSlots ?? emptyArray
      itemName = comp["item.name"]
      desc = comp["item.name"]
      iconName = comp["animchar.res"]
      iconYaw = comp["item.iconYaw"]
      iconPitch = comp["item.iconPitch"]
      iconRoll = comp["item.iconRoll"]
      iconOffsX = iconOffs.x
      iconOffsY = iconOffs.y
      iconScale = comp["item.iconScale"]
      volume = comp["item.volume"],
      weight = comp["item.weight"],
      objTexReplace = "".join(objTexReplaceS),
    }
  })
}


local function updateEquipment(eid, comp) {
  local slots = comp["human_equipment.slots"]
  local res = {}
  if (slots != null) {
    foreach (slotName, slotObj in slots) {
      local itemEid = slotObj?.item ?? INVALID_ENTITY_ID
      if (itemEid == INVALID_ENTITY_ID) {
        res[slotName] <- {}
        continue
      }
      local itemTbl = get_item_info(itemEid) ?? {}
      if (itemTbl != null)
        res[slotName] <- itemTbl
    }
  }
  equipment(res)
}

::ecs.register_es("hero_equipment_script_es", {
    [["onInit", EventHeroChanged, "onChange"]] = @(evt, eid, comp) updateEquipment(eid, comp),
  },
  { comps_track = [
      ["human_equipment.slots", ::ecs.TYPE_OBJECT],
      ["human_inventory.capacity", ::ecs.TYPE_FLOAT, 0.0],
    ],
    comps_rq = ["watchedByPlr"]
  }
)

local function onSlotsAttach(evt, eid, comp) {
  local heroEidV = watchedHeroEid.value
  if (comp["slot_attach.attachedTo"] == heroEidV)
    get_heroslots_info_query.perform(heroEidV, updateEquipment)
}

::ecs.register_es("slot_attach_script_es", {
    [["onInit","onDestroy"]] = onSlotsAttach,
  },
  {
    comps_ro = [["slot_attach.attachedTo", ::ecs.TYPE_EID]]
  }
)
return {equipment} 