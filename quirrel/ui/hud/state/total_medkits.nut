local selfHealMedkits = Watched(0)
local selfReviveMedkits = Watched(0)

local function medkitsOnCountChange(evt, eid, comp) {
  selfHealMedkits(comp["total_kits.selfHeal"])
  selfReviveMedkits(comp["total_kits.selfRevive"])
}

local function medkitsOnDestroy(evt, eid, comp) {
  selfHealMedkits(0)
  selfReviveMedkits(0)
}

::ecs.register_es("total_medkits_ui",{
  [["onChange", "onInit"]] = medkitsOnCountChange,
  [::ecs.EventEntityDestroyed] = medkitsOnDestroy
}, {
  comps_track=[["total_kits.selfHeal", ::ecs.TYPE_INT], ["total_kits.selfRevive", ::ecs.TYPE_INT]],
  comps_rq=["watchedByPlr"]
})

return {
  selfHealMedkits = selfHealMedkits
  selfReviveMedkits = selfReviveMedkits
}
 