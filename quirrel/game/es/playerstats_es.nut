local {userstatsAdd} = require("game/utils/userstats.nut")
local {EventOnPlayerLooted} = require("lootevents")

local function onPlayerLooted(evt, eid, comp) {
  local evt_type = evt[0]
  local evt_region = evt[1]
  local awardParams = {
    userid = comp.userid,
    mode = evt_region
  }
  if (evt_type != "item") // item is our default
    userstatsAdd(comp.userstats, comp.userstats_mode, "looted_{0}".subst(evt_type), awardParams)
  userstatsAdd(comp.userstats, comp.userstats_mode, "looted_item", awardParams)
}
::ecs.register_es("playerstats_es", {
  [EventOnPlayerLooted] = onPlayerLooted,
}, {
  comps_rw = [ ["userstats", ::ecs.TYPE_OBJECT], ["userstats_mode", ::ecs.TYPE_OBJECT] ]
  comps_ro = [ ["userid", ::ecs.TYPE_INT64], ]
})

 