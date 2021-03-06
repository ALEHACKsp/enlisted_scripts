local {TEAM_UNASSIGNED} = require("team")

local findCapzoneQuery = ::ecs.SqQuery("findCapzoneQuery", {comps_ro = [["groupName", ::ecs.TYPE_STRING],
                                      ["active", ::ecs.TYPE_BOOL],["capzone.progress", ::ecs.TYPE_FLOAT],
                                      ["capzone.mustBeCapturedByTeam", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
                                      ["capzone.capTeam", ::ecs.TYPE_INT]] comps_rq=["capzone"]})


local function allZonesInGroupCapturedByTeam(skipEid, teamId, groupName){
  local allZonesCapture = true
  findCapzoneQuery.perform(function(qEid, comps) {
    if (comps["active"] && (skipEid != qEid && groupName == comps["groupName"] &&
        ((teamId != comps["capzone.capTeam"] || comps["capzone.progress"] < 0.99) ||
         comps["capzone.mustBeCapturedByTeam"] != teamId)))
      allZonesCapture = false
  })
  return allZonesCapture
}

local function getLastGroupToCaptureByTeam(skipEid, teamId){
  local groupToCapture = null
  local isLast = true
  findCapzoneQuery.perform(function(qEid, comps) {
    if (comps["active"] && (skipEid != qEid &&
        ((teamId != comps["capzone.capTeam"] || comps["capzone.progress"] < 0.99) ||
         comps["capzone.mustBeCapturedByTeam"] != teamId))) {
      if (groupToCapture == null)
        groupToCapture = comps["groupName"]
      else if (groupToCapture != comps["groupName"])
        isLast = false
    }
  })
  return isLast ? groupToCapture : null
}

local function capZonesGroupMustChanged(checkAllZonesInGroup, eid, teamId, mustBeCapturedByTeam, groupName){
  return (checkAllZonesInGroup && allZonesInGroupCapturedByTeam(eid, teamId, groupName) && teamId == mustBeCapturedByTeam) || !checkAllZonesInGroup
}

return {allZonesInGroupCapturedByTeam = allZonesInGroupCapturedByTeam,
        getLastGroupToCaptureByTeam = getLastGroupToCaptureByTeam,
        capZonesGroupMustChanged = capZonesGroupMustChanged}
 