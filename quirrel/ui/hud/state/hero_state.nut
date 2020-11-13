                                                                                               


local {CmdTrackHeroWeapons} = require("gameevents")
local {tostring_r} = require("std/string.nut")
local {Point2} = require("dagor.math")

local weaponEquipStates = require("globals/weapon_equip_states.nut")
local weaponSlots = require("globals/weapon_slots.nut")
local weaponSlotNames = require("globals/weapon_slot_names.nut")
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {inventoryItems} = require("ui/hud/state/inventory_items_es.nut")
local activeGrenadeEid = ::Watched(INVALID_ENTITY_ID)
local {is_item_potentially_useful, is_item_useful, INVALID_ITEM_ID} = require("humaninv")

local heroState = {
  //Attention! do not anything here! it is too broad and should be splitted into separate files
  curWeapon = Watched(null)
  needReload = Watched(false)
  weaponsList = Watched([])  //should be array of tables  [{ weaponName = "mp-40" curAmmo = 10 totalAmmo = 100 maxLoadedAmmo=20 }]
  fastThrowExclusive = Watched(false)
  activeGrenadeEid = activeGrenadeEid
}

heroState.weaponsList.subscribe(function(_) {
  local hasChanges = false
  foreach(item in inventoryItems.value) {
    local eid = item.eid
    local heroEid = watchedHeroEid.value ?? INVALID_ENTITY_ID
    local isUseful = is_item_useful(heroEid, eid)
    local isPotentiallyUseful = is_item_potentially_useful(heroEid, eid)
    hasChanges = hasChanges || item.isUseful != isUseful || item.isPotentiallyUseful != isPotentiallyUseful
    item.isUseful = isUseful
    item.isPotentiallyUseful = isPotentiallyUseful
  }
  if (hasChanges)
    inventoryItems.trigger()
})

console.register_command(function() {
                            if (heroState.weaponsList.value != null) {
                              foreach (w in heroState.weaponsList.value) {
                                vlog(tostring_r(w))
                              }
                            }
                          },
                          "hud.logWeaponList"
                        )
console.register_command(@() heroState.curWeapon.update({name="Knife" curAmmo=0 totalAmmo = 0 maxAmmo=0 isCurrent=true isReloadable=false}),"hud.setKnife")
console.register_command(@(ammo=10, totalAmmo=200) heroState.curWeapon.update({name="MP-40" curAmmo=ammo totalAmmo=totalAmmo maxAmmo=32 isCurrent=true}),"hud.setGun")
console.register_command(function(ammo=3) {
                          heroState.weaponsList.update(
                            [
                              {name="machineGun" curAmmo=10 totalAmmo = ammo maxAmmo=32 },
                              {name="muskete" curAmmo=1 totalAmmo=ammo maxAmmo=1 },
                              {name="knife" maxAmmo=0 isReloadable=false totalAmmo=ammo},
                            ]
                          )},"hud.mockWeaponsList")




local function onHeroWeapons(list) {
  heroState.weaponsList(list)
  if (type(list) != "array" || list.len() == 0)
    return
  local weapon = list.findvalue(@(w) w.isCurrent)
  if (weapon == null)
    return

  heroState.curWeapon(weapon)
  local curAmmo = weapon.curAmmo
  local maxLoadedAmmo = ::max(weapon.maxAmmo, 1)
  local fullness = curAmmo.tofloat()/maxLoadedAmmo
  heroState.needReload((fullness < 0.1 || (maxLoadedAmmo > 1 && curAmmo==1))
    && weapon.totalAmmo > curAmmo && !weapon.isReloading)
}



local itemIconQuery = ::ecs.SqQuery("itemIconQuery", {
  comps_ro = [
    ["animchar.res", ::ecs.TYPE_STRING, ""],
    ["item.iconYaw", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconPitch", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconRoll", ::ecs.TYPE_FLOAT, 0.0],
    ["item.iconOffset", ::ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["item.iconScale", ::ecs.TYPE_FLOAT, 1.0],
  ]
})

local function setIconParams(itemEid, dst) {
  itemIconQuery.perform(itemEid, function (eid, comp) {
    dst.__update({
      iconName = comp["animchar.res"]
      iconYaw = comp["item.iconYaw"]
      iconPitch = comp["item.iconPitch"]
      iconRoll = comp["item.iconRoll"]
      iconOffsX = comp["item.iconOffset"].x
      iconOffsY = comp["item.iconOffset"].y
      iconScale = comp["item.iconScale"]
    })
  })
}

local function setIconParamsByTemplate(itemEid, dst) {
  if (itemEid == INVALID_ENTITY_ID)
    return
  local itemTempl = ::ecs.get_comp_val(itemEid, "item.template") ?? ::ecs.get_comp_val(itemEid, "item.ammoTemplate")
  if (itemTempl == null)
    return
  local templ = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(itemTempl)
  if (templ == null)
    return
  local iconOffset = templ.getCompValNullable("item.iconOffset") ?? Point2(0.0, 0.0)
  dst.__update({
    iconName = templ.getCompValNullable("animchar.res") ?? ""
    iconYaw = templ.getCompValNullable("item.iconYaw") ?? 0.0
    iconPitch = templ.getCompValNullable("item.iconPitch") ?? 0.0
    iconRoll = templ.getCompValNullable("item.iconRoll") ?? 0.0
    iconOffsX = iconOffset.x
    iconOffsY = iconOffset.y
    iconScale = templ.getCompValNullable("item.iconScale") ?? 1.0
  })
}

local gunQuery = ::ecs.SqQuery("gunQuery", {
  comps_ro = [
    ["gun.propsId", ::ecs.TYPE_INT, -1],
    ["gun.maxAmmo", ::ecs.TYPE_INT, 0],
    ["gun.serverAmmo", ::ecs.TYPE_INT, 0],
    ["gun.totalAmmo", ::ecs.TYPE_INT, 0],
    ["gun.disableAmmoUnload", ::ecs.TYPE_TAG, null],
    ["ammo_holder.itemPropsId", ::ecs.TYPE_INT, -1],
    ["gun.wishAmmoItemType", ::ecs.TYPE_INT, INVALID_ITEM_ID],
    ["gun.ammoHolderEid", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["gun.firingModeName", ::ecs.TYPE_STRING, ""],
    ["gun.reloadable", ::ecs.TYPE_BOOL, false],
    ["gun_mods.slots", ::ecs.TYPE_OBJECT, null],
    ["gun_anim.reloadProgress", ::ecs.TYPE_FLOAT, -1.0],
    ["item.name", ::ecs.TYPE_STRING, ""],
    ["item.weapSlots", ::ecs.TYPE_ARRAY, null],
    ["item.id", ::ecs.TYPE_INT, INVALID_ITEM_ID],
    ["item.weapType", ::ecs.TYPE_STRING, null],
    ["grenade_thrower.projectileEntity", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
  ]
})
local weapon_proto = {
  isReloadable = false
  isCurrent = false
  isHolstering = false
  isEquiping = false
  isWeapon = false
  name = ""
  totalAmmo = 0
  curAmmo = 0
  maxAmmo = 0
}


local function trackHeroWeapons(evt, eid, comp) {
  local isChanging = comp["human_net_phys.weapEquipCurState"] == weaponEquipStates.EES_HOLSTERING ||
                     comp["human_net_phys.weapEquipCurState"] == weaponEquipStates.EES_EQUIPING

  local weaponDescs = []
  weaponDescs.resize(weaponSlots.EWS_NUM, null)

  for (local i = 0; i < weaponSlots.EWS_NUM; ++i) {
    local validWeaponSlots = null
    local itemId = null
    local gunMods = null
    local gunEid = comp["human_weap.gunEids"][i]
    gunQuery.perform(gunEid, function (eid, gunComp) {
      validWeaponSlots = gunComp["item.weapSlots"]?.getAll() ?? []
      itemId = gunComp["item.id"]
      gunMods = gunComp["gun_mods.slots"]
    });
    local desc = gunQuery.perform(::ecs.get_comp_val(gunEid, "subsidiaryGunEid", gunEid), function (eid, gunComp) {
      local isCurrentSlot = i == comp["human_weap.currentGunSlot"]
      local isReloadable = gunComp["gun.propsId"] >= 0 && i != weaponSlots.EWS_GRENADE ? gunComp["gun.reloadable"] : false
      local weaponDesc = {
        totalAmmo = gunComp["gun.totalAmmo"]
        name = gunComp["item.name"]
        curAmmo = gunComp["gun.serverAmmo"]
        maxAmmo = gunComp["gun.maxAmmo"]
        itemPropsId = itemId
        firingMode = gunComp["gun.firingModeName"]
        isReloadable = isReloadable
        isUnloadable = gunComp["gun.disableAmmoUnload"] == null
        isReloading = gunComp["gun_anim.reloadProgress"] > 0.0
        isCurrent = isCurrentSlot
        isHolstering = isChanging && isCurrentSlot
        isEquiping = isChanging && comp["human_net_phys.weapEquipNextSlot"] == i
        isWeapon = validWeaponSlots.len() > 0
        hasSwitchableWeaponMods = false
        validWeaponSlots = validWeaponSlots
        grenadeType = null
        weapType = gunComp["item.weapType"]
        mods = {}
      }

      if (isReloadable) {
        weaponDesc.ammo <- {
          itemPropsId = gunComp["ammo_holder.itemPropsId"]
          name = ::ecs.get_comp_val(gunComp["gun.ammoHolderEid"], "item.name") ?? ""
        }
        setIconParamsByTemplate(gunComp["gun.ammoHolderEid"], weaponDesc.ammo)
      }
      if (i == weaponSlots.EWS_GRENADE){
        heroState.activeGrenadeEid(gunComp["grenade_thrower.projectileEntity"])
      }

      if (gunComp["gun.wishAmmoItemType"] != INVALID_ITEM_ID && i == weaponSlots.EWS_GRENADE) {
        local grenEid = INVALID_ENTITY_ID;
        foreach (itemEid in comp["itemContainer"]) {
          local itemPropsId = ::ecs.get_comp_val(itemEid, "item.id", INVALID_ITEM_ID)
          if (itemPropsId == gunComp["gun.wishAmmoItemType"]) {
            grenEid = itemEid
            break
          }
        }
        weaponDesc.name = ::ecs.get_comp_val(grenEid, "item.name", "")
        weaponDesc.grenadeType = ::ecs.get_comp_val(grenEid, "item.grenadeType", null)
        weaponDesc.itemPropsId = gunComp["gun.wishAmmoItemType"]

        setIconParams(grenEid, weaponDesc)
      }
      else
        setIconParams(gunEid, weaponDesc)

      if (gunMods != null) {
        local iconAttachments = []
        foreach (slot, slotTag in comp["human_weap.gunModsBySlot"][i]) {
          local modEid = comp["human_weap.gunMods"][i]
          weaponDesc.mods[slot] <- {
            itemPropsId = ::ecs.get_comp_val(modEid, "item.id")
            array_tags = gunMods?[slot]?.getAll()?.keys() ?? []
            attachedItemName = ::ecs.get_comp_val(modEid, "item.name", "")
            attachedItemModSlotName = ::ecs.get_comp_val(modEid, "gunAttachable.gunSlotName", "")
            attachedItemModTag = ::ecs.get_comp_val(modEid, "gunAttachable.slotTag", "")
            isActivated = ::ecs.get_comp_val(modEid, "weapon_mod.active", false)
            isWeapon = ::ecs.get_comp_val(modEid, "gun", null) ? true : false
          }
          setIconParamsByTemplate(modEid, weaponDesc.mods[slot])
          local mod = weaponDesc.mods[slot]
          if (mod.isWeapon) {
            iconAttachments.append({
              animchar = mod.iconName
              slot = mod.attachedItemModSlotName
              active = mod.isActivated
              scale = 2.0 /* We want to emphasize attachments */
            })
            weaponDesc.hasSwitchableWeaponMods = true
          }
        }
        if (iconAttachments.len() > 0)
          weaponDesc.__update({
            iconAttachments = iconAttachments
          })
      }

      return weaponDesc
    })
    weaponDescs[i] = (desc == null) ? clone weapon_proto : desc
    weaponDescs[i].currentWeaponSlotName <- weaponSlotNames[i]
  }
  onHeroWeapons(weaponDescs)
}

::ecs.register_es("hero_state_weapons_ui_es",
  {
    [["onInit", ::ecs.EventComponentChanged,"onDestroy", CmdTrackHeroWeapons]] = trackHeroWeapons,
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [
      ["human_weap.gunModsBySlot", ::ecs.TYPE_ARRAY],
      ["human_weap.gunEids", ::ecs.TYPE_EID_LIST],
      ["human_weap.gunMods", ::ecs.TYPE_EID_LIST],
      ["human_weap.currentGunSlot", ::ecs.TYPE_INT],
      ["human_net_phys.weapEquipCurState", ::ecs.TYPE_INT],
      ["human_net_phys.weapEquipNextSlot", ::ecs.TYPE_INT],
      ["itemContainer", ::ecs.TYPE_EID_LIST],
    ]
  }
)

//these are awful workarounds for incorrect weapons update above.
//We should listen ONLY to weapon entities instead of all code that listens to hero above here
::ecs.register_es("hero_state_mod_ui_es",
  {
    onInit = @(evt, eid, comp) ::ecs.g_entity_mgr.sendEvent(watchedHeroEid.value, CmdTrackHeroWeapons())
  },
  {
    comps_rq = ["weaponMod"]
  }
)
::ecs.register_es("hero_state_fast_throw_mode_es",
  {
    [["onInit", "onChange"]] = @(evt, eid, comp) heroState.fastThrowExclusive(comp["human_weap.fastThrowExclusive"])
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["human_weap.fastThrowExclusive", ::ecs.TYPE_BOOL]]
  }
)
local function trackWeapon(evt, eid, comp) {
  local hero = watchedHeroEid.value
  if (comp["gun.owner"] == hero)
    ::ecs.g_entity_mgr.sendEvent(hero, CmdTrackHeroWeapons())
}

::ecs.register_es("hero_state_melee_workaround_ui_es",
  {
    onInit = trackWeapon
  },
  {
    comps_ro = [["gun.owner", ::ecs.TYPE_EID]]
    comps_rq = [["gun.melee", ::ecs.TYPE_BOOL]]
  }
)

::ecs.register_es("hero_state_gun_workaround_ui_es",
  {
    [["onInit", "onChange","onDestroy"]] = trackWeapon,
  },
  {
    comps_rq = ["gun"]
    comps_track = [
      ["gun.owner", ::ecs.TYPE_EID],
      ["gun.firingModeIndex", ::ecs.TYPE_INT],
      ["gun.serverAmmo", ::ecs.TYPE_INT],
      ["gun.totalAmmo", ::ecs.TYPE_INT],
      ["ammo_holder.itemPropsId", ::ecs.TYPE_INT],
      ["gun.wishAmmoItemType", ::ecs.TYPE_INT],
      ["gun.ammoHolderEid", ::ecs.TYPE_EID]
    ]
  }
)

::ecs.register_es("hero_state_subsidiary_gun_ui_es",
  {
    [[::ecs.EventComponentsAppear, ::ecs.EventComponentsDisappear, "onChange"]] = trackWeapon,
  },
  {
    comps_rq = ["gun"]
    comps_ro = [["gun.owner", ::ecs.TYPE_EID]]
    comps_track = [
      ["subsidiaryGunEid", ::ecs.TYPE_EID]
    ]
})

return heroState
 