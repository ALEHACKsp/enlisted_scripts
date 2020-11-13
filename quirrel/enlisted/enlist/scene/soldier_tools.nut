local { logerr } = require("dagor.debug")
local { Point3, Point4 } = require("dagor.math")
local {
  curCampSoldiers, objInfoByGuid, getSoldierItem, getSoldierItemSlots, getSoldierLook,
  getModSlots
} = require("enlisted/enlist/soldiers/model/state.nut")
local { getIdleAnimState } = require("animation_utils.nut")
local weaponSlots = require("globals/weapon_slots.nut")
local weaponSlotNames = require("globals/weapon_slot_names.nut")
local curGenFaces = require("enlisted/faceGen/gen_faces.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")
local {
  allItemTemplates, findItemTemplate
} = require("enlisted/enlist/soldiers/model/all_items_templates.nut")

local function setEquipment(eid, equipment) {
  local equipSlots = ::ecs.get_comp_val(eid, "human_equipment.slots").getAll()

  local animcharDisabledParams = []
  foreach (slot, eq in equipment){
    if (!eq || !eq.template)
      continue
    local template = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(eq.template)
    animcharDisabledParams.extend(template?.getCompValNullable("disabledFaceGenParams").getAll() ?? [])
  }

  foreach (slot, eq in equipment) {
    if (equipSlots[slot].item != null && equipSlots[slot].item != INVALID_ENTITY_ID)
      ::ecs.g_entity_mgr.destroyEntity(equipSlots[slot].item)

    if (!eq || !eq.template)
      continue

    local eqSlot = slot
    local function onCreateEquip(equipEid) {
      local sl = ::ecs.get_comp_val(eid, "human_equipment.slots")
      if (sl?[eqSlot] != null) {
        sl[eqSlot].item = equipEid
        ::ecs.set_comp_val(eid, "human_equipment.slots", sl)
      }
      else
        ::ecs.g_entity_mgr.destroyEntity(equipEid)
    }
    local comps = {
      ["slot_attach.attachedTo"] = [eid, ::ecs.TYPE_EID],
      ["paintColor"] = eq.paintColor
    }
    if (slot == "face") {
      comps["updatable"] <- true
      local template = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(eq.template)
      local animchar = template?.getCompValNullable("animchar.res") ?? null
      if (animchar && curGenFaces?[animchar] != null && eq?.faceId != null) {
        comps["animcharParams"] <- curGenFaces[animchar][eq.faceId.tostring()]
        foreach (param in animcharDisabledParams)
          if (comps?["animcharParams"][param] != null)
            delete comps["animcharParams"][param]
      }
    }
    if(eq.template && eq.template!="")
      ::ecs.g_entity_mgr.createEntity(eq.template, comps, onCreateEquip)
  }
}

local weaponSlotIds = ["primary", "secondary", "side"]

local function getWearInfos(soldierGuid, scheme) {
  local eInfos = []
  foreach (itemInfo in getSoldierItemSlots(soldierGuid)) {
    if (itemInfo.slotType == "inventory" || weaponSlotIds.indexof(scheme?[itemInfo.slotType].ingameWeaponSlot) != null)
      continue

    local itemGuid = itemInfo.item.guid
    local info = objInfoByGuid.value?[itemGuid]
    if (info?.slot != null)
      eInfos.append(info)
  }
  return eInfos
}

local function getItemAnimationBlacklist(soldierGuid, scheme) {
  local itemTemplates = []
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  local armyId = getLinkedArmyName(curCampSoldiers.value?[soldierGuid] ?? {})
  foreach(slotType, slot in scheme) {
    local item = getSoldierItem(soldierGuid, slotType)
    if ("gametemplate" in item) {
      local itemTemplateId = item.gametemplate
      local itemTemplate = db.getTemplateByName(itemTemplateId)
      if (itemTemplate != null)
        itemTemplates.append(itemTemplate)
    }
  }
  local eInfos = getWearInfos(soldierGuid, scheme)
  foreach (eInfo in eInfos) {
    local itemTemplate = db.getTemplateByName(eInfo.gametemplate)
    if (itemTemplate != null)
      itemTemplates.append(itemTemplate)
  }
  local soldierLook = getSoldierLook(soldierGuid)
  if (soldierLook != null) {
    foreach (slot, tmpl in soldierLook?.items ?? {}) {
      local eInfo = findItemTemplate(allItemTemplates, armyId, tmpl)
      if (eInfo != null && eInfo?.slot != null) {
        local itemTemplate = db.getTemplateByName(eInfo.gametemplate)
        if (itemTemplate) {
          itemTemplates.append(itemTemplate)
        }
      }
    }
  }

  local animationBlacklist = {}
  foreach (itemTemplate in itemTemplates) {
    local itemAnimationBlacklist = itemTemplate.getCompValNullable("animationBlacklistForMenu") ?? null
    if (itemAnimationBlacklist == null)
      continue
    foreach (anim in itemAnimationBlacklist) {
      animationBlacklist[anim] <- true
    }
  }
  return animationBlacklist
}

local function getWeapTemplates(soldierGuid, scheme) {
  local weapTemplates = {primary="", secondary="", tertiary=""}
  foreach(slotType, slot in scheme) {
    if (weapTemplates?[slot?.ingameWeaponSlot] != "")
      continue
    local weapon = getSoldierItem(soldierGuid, slotType)
    if (!("gametemplate" in weapon))
      continue

    local tpl = weapon.gametemplate
    if (slot.ingameWeaponSlot == "primary")
      tpl = "+".concat(tpl, "menu_gun")
    weapTemplates[slot.ingameWeaponSlot] = tpl
  }
  return weapTemplates
}

local makePoint4 = @(v) Point4(v?[0] ?? 0, v?[1] ?? 0, v?[2] ?? 0, v?[3] ?? 1.0)
local function mkEquipment(soldierGuid, scheme){
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  local equipment = {}
  local armyId = getLinkedArmyName(curCampSoldiers.value?[soldierGuid] ?? {})

  local eInfos = getWearInfos(soldierGuid, scheme)
  foreach (eInfo in eInfos) {
    local links = eInfo?.links
    if (eInfo?.slot != null) {
      local itemTemplate = db.getTemplateByName(eInfo.gametemplate)
      if (itemTemplate) {
        local recreateName = itemTemplate.getCompValNullable("item.recreateInEquipment") ?? "base_vis_item"
        local templ = $"{recreateName}+{eInfo.gametemplate}"
        equipment[eInfo.slot] <- { template = templ, paintColor = makePoint4(eInfo?.paintColor ?? [1.0, 1.0, 1.0]),
                  faceId = eInfo.itemtype == "head" && links ? links.filter(@(v) v == "faceId").keys()?[0] : null}
      } else {
        logerr($"Equipment template {eInfo.gametemplate} not found")
      }
    }
  }

  local soldierLook = getSoldierLook(soldierGuid)
  if (soldierLook != null) {
    foreach (slot, tmpl in soldierLook?.items ?? {}) {
      local eInfo = findItemTemplate(allItemTemplates, armyId, tmpl)
      if (eInfo != null && eInfo?.slot != null) {
        local itemTemplate = db.getTemplateByName(eInfo.gametemplate)
        if (itemTemplate) {
          local recreateName = itemTemplate.getCompValNullable("item.recreateInEquipment") ?? "base_vis_item"
          local templ = $"{recreateName}+{eInfo.gametemplate}"
          equipment[eInfo.slot] <- { template = templ, paintColor = makePoint4(eInfo?.paintColor ?? [1.0, 1.0, 1.0]),
                      faceId = eInfo.itemtype == "head" ? soldierLook.faceId : null}
        } else {
          logerr($"Appearance template {eInfo.gametemplate} not found")
        }
      }
    }
  }

  if (equipment?.hair && (equipment?.head || equipment?.skined_helmet))
    equipment.hair <- null
  if (equipment?.backpack == null)
    equipment.backpack <- null

  return equipment
}

local function createSoldier(
  guid, transform, callback = null, extraTemplates = [], comps = {}, isDisarmed = false
) {
  local soldier = objInfoByGuid.value?[guid]
  if (soldier == null)
    return INVALID_ENTITY_ID

  local scheme = isDisarmed ? {} : soldier?.equipScheme ?? {}
  local soldierItems = getSoldierItemSlots(guid)
  local weapTemplates = getWeapTemplates(guid, scheme)
  local equipment = mkEquipment(guid, scheme)

  local weapInfo = []
  weapInfo.resize(weaponSlots.EWS_NUM)

  local db = ::ecs.g_entity_mgr.getTemplateDB()
  for (local slotNo = 0; slotNo < weaponSlots.EWS_NUM; ++slotNo) {
    local weapon = {}
    weapInfo[slotNo] = weapon
    local slotName = weaponSlotNames[slotNo]
    local slots = getModSlots(
      objInfoByGuid.value?[soldierItems.findvalue(@(item) item.slotType == slotName)?.item.guid])
    foreach (slot in slots) {
      local slotTemplateId = objInfoByGuid.value?[slot.equipped].gametemplate
      local slotTemplate = slotTemplateId ? db.getTemplateByName(slotTemplateId) : null
      if (!slotTemplate)
        continue
      if ("gunMods" not in weapon)
        weapon.gunMods <- {}
      weapon.gunMods[slot.slotType] <- slotTemplate.getCompVal("gunAttachable.slotTag")
    }
  }

  local animationBlacklist = getItemAnimationBlacklist(guid, scheme)
  local guid_hash = guid.hash()
  local animation = getIdleAnimState(weapTemplates, animationBlacklist, guid_hash)
  local bodyHeight = soldier?.bodyScale?.height ?? 1.0
  local bodyWidth = soldier?.bodyScale?.width ?? 1.0
  local result_template = "+".join(["customizable_menu_animchar","human_weap"].extend(extraTemplates))
  return ::ecs.g_entity_mgr.createEntity(result_template, {
      ["transform"] = transform,
      ["guid"] = guid,
      ["guid_hash"] = guid_hash,
      ["animchar.animStateNames"] = [{lower = animation, upper = animation}, ::ecs.TYPE_OBJECT],
      ["human_weap.weapTemplates"] = [weapTemplates, ::ecs.TYPE_OBJECT],
      ["human_weap.weapInfo"] = [weapInfo, ::ecs.TYPE_ARRAY],
      ["animchar.scale"] = bodyHeight,
      ["animchar.depScale"] = Point3(bodyWidth, bodyHeight, bodyWidth),
      ["animchar.transformScale"] = Point3(bodyWidth, 1.0, bodyWidth),
      ["appearance.rndSeed"] = (soldier?["appearanceSeed"] ?? 0)
    }.__merge(comps),
    function(newEid) {
      callback?(newEid)
      setEquipment(newEid, equipment)
    }
  )
}


return {
  setEquipment
  createSoldier
  createSoldierKwarg = ::kwarg(createSoldier)
} 