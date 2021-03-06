local {CmdUse} = require("gameevents")
local weaponSlots = require("globals/weapon_slots.nut")
local { get_sync_time } = require("net")

const REQUEST_AMMO_CD = 10.0

local function onRequestAmmo(evt, eid, comp) {
  if (!comp["isAlive"] || comp["isDowned"])
    return
  local slots = [weaponSlots.EWS_PRIMARY]
  local requesterEid = evt[0]
  local squadEid = ::ecs.get_comp_val(requesterEid, "squad_member.squad", INVALID_ENTITY_ID)
  if (squadEid != comp["squad_member.squad"])
    return
  local requestAmmoAllowTime = ::ecs.get_comp_val(requesterEid, "requestAmmoAllowTime") ?? 0.0
  if (requestAmmoAllowTime > get_sync_time())
    return
  if (!::ecs.get_comp_val(squadEid, "squad.isLeaderNeedsAmmo", true))
    return

  local itemContainer = ::ecs.get_comp_val(requesterEid, "itemContainer")
  local ammoProtoToTemplateMap = ::ecs.get_comp_val(requesterEid, "ammoProtoToTemplateMap")
  local weapInfo = ::ecs.get_comp_val(requesterEid, "human_weap.weapInfo")
  local gunEids = ::ecs.get_comp_val(requesterEid, "human_weap.gunEids").getAll()

  local items = itemContainer.getAll().map(@(itemEid) {
      eid = itemEid,
      template = ::ecs.g_entity_mgr.getEntityTemplateName(itemEid),
      proto = ::ecs.get_comp_val(itemEid, "item.proto")
    })

  local ammoCount = {}
  foreach (slot in slots) {
    local weap = weapInfo[slot]
    local ammo = weap?["numReserveAmmo"] ?? 0
    if (::ecs.get_comp_val(gunEids[slot], "gun.serverAmmo", 0) > 0)
      ammo -= 1
    local reserveAmmoType = weap?["reserveAmmoType"]
    if (reserveAmmoType != null)
      ammoCount[reserveAmmoType] <- ammo
  }

  foreach (item in items) {
    if (ammoCount?[item.proto] != null)
      ammoCount[item.proto]--
  }

  ammoCount = ammoCount.filter(@(ammo) ammo > 0)

  foreach (proto, ammo in ammoCount) {
    local item = ammoProtoToTemplateMap?[proto]
    if (item) {
      ::ecs.g_entity_mgr.createEntity("{0}".subst(item.template), { ["item.lastOwner"] = ::ecs.EntityId(requesterEid) },
        function(ammoEid) {
          ::ecs.get_comp_val(requesterEid, "itemContainer").append(::ecs.EntityId(ammoEid))
        })
      ::ecs.set_comp_val(requesterEid, "requestAmmoAllowTime", get_sync_time() + REQUEST_AMMO_CD)
      break
    }
  }
}

::ecs.register_es("squad_request_ammo_es",
  {
    [CmdUse] = onRequestAmmo
  },
  {
    comps_ro = [
      ["squad_member.squad", ::ecs.TYPE_EID],
      ["isAlive", ::ecs.TYPE_BOOL],
      ["isDowned", ::ecs.TYPE_BOOL],
    ]
    comps_rq = ["human"]
  },
  {tags="server"}
)
 