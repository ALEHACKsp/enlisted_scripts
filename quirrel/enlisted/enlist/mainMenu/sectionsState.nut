local {scenesList} = require("enlist/navState.nut")

local sectionsSorted = ::Watched([])
//check for uniquness. actually we can simply use only idx as id and that's all
sectionsSorted.subscribe(function(sections){
  local found = {}
  foreach (k, v in sections) {
    if (v?.id==null)
      v.id<-k
    if (v.id in found){
      assert(false, "id of sections should be unique")
      v.id<-k
    }
    found[v.id] <- null
  }
})

local curSection = persist("curSection", @() Watched(null))
local curSectionDetails = ::Computed(@() scenesList.value.len() > 0 ? null
  : sectionsSorted.value.findvalue(@(s) s?.id == curSection.value))

local function setCurSection(id) {
  local section = sectionsSorted.value.findvalue(@(s) s?.id == id)
  if (section == null)
    return
  curSection(id)
}

return {
  sectionsSorted,
  curSectionDetails,
  curSection = ::Computed(@() curSection.value),
  setCurSection
}
 