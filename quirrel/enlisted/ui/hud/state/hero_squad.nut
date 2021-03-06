
local squadEid = persist("squadEid", @() ::Watched(INVALID_ENTITY_ID))
local numAliveMembers = persist("numAliveMembers", @() ::Watched(-1))
local orderType = persist("orderType", @() ::Watched(0))
local hasPersonalOrder = persist("hasPersonalOrder", @() ::Watched(false))
local isLeaderNeedsAmmo = persist("isLeaderNeedsAmmo", @() ::Watched(false))
local hasSpaceForMagazine = persist("hasSpaceForMagazine", @() ::Watched(false))
local isCompatibleWeapon = persist("isCompatibleWeapon", @() ::Watched(false))


local function updateSquadEid(evt, eid, comp) {
  squadEid(comp["squad_member.squad"])
  local alive = -1
  if (squadEid.value != INVALID_ENTITY_ID)
    alive = ::ecs.get_comp_val(squadEid.value, "squad.numAliveMembers", -1)
  numAliveMembers(alive)
}

local function updateSquadParams(evt, eid, comp) {
  if (eid != squadEid.value && eid != INVALID_ENTITY_ID)
    return
  numAliveMembers(comp["squad.numAliveMembers"])
  orderType(comp["squad.orderType"])
  hasPersonalOrder(comp["squad.hasPersonalOrder"])
  isLeaderNeedsAmmo(comp["squad.isLeaderNeedsAmmo"])
  hasSpaceForMagazine(comp["order_ammo.hasSpaceForMagazine"])
  isCompatibleWeapon(comp["order_ammo.isCompatibleWeapon"])
}

::ecs.register_es("hero_squad_eid_es",
  {
    [["onInit", "onChange"]] = updateSquadEid,
  },
  { comps_track = [["squad_member.squad", ::ecs.TYPE_EID],]
    comps_rq = ["human_input"]
  })

::ecs.register_es("hero_squad_es",
  {
    [["onInit", "onChange"]] = updateSquadParams,
  },
  {
    comps_track = [
      ["order_ammo.hasSpaceForMagazine", ::ecs.TYPE_BOOL],
      ["order_ammo.isCompatibleWeapon", ::ecs.TYPE_BOOL],
      ["squad.numAliveMembers", ::ecs.TYPE_INT],
      ["squad.orderType", ::ecs.TYPE_INT],
      ["squad.hasPersonalOrder", ::ecs.TYPE_BOOL],
      ["squad.isLeaderNeedsAmmo", ::ecs.TYPE_BOOL],
    ]
  })

return {
  squadEid = squadEid
  heroSquadNumAliveMembers = numAliveMembers
  heroSquadOrderType = orderType
  hasPersonalOrder = hasPersonalOrder
  isLeaderNeedsAmmo = isLeaderNeedsAmmo
  hasSpaceForMagazine = hasSpaceForMagazine
  isCompatibleWeapon = isCompatibleWeapon
} 