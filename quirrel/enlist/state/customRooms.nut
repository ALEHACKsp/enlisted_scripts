local {room, roomIsLobby, setMemberAttributes} = require("enlist/state/roomState.nut")
local {matchingTeam} = require("enlist/quickMatchQueue.nut")


local publicAttribs = keepref(Computed(@() matchingTeam.value != null ? {team = matchingTeam.value} : {}))

// Uncomment this function and delete previous when add new states to synchronize
/*
local publicAttribs = frp.combine( { team = quickMatchQueue.team },
                        function(_) {
                          local result = {}
                          if (_.team != null)
                            result["team"] <- _.team
                          return result
                        })
*/

local function syncAttribs() {
  if (publicAttribs.value.len() > 0) {
    setMemberAttributes({ public = publicAttribs.value },
                                  function(response) {})
  }
}

roomIsLobby.subscribe(function(val) {
  if (val)
    syncAttribs()
})

publicAttribs.subscribe(function(attribs) {
  if (room != null && roomIsLobby.value)
    syncAttribs()
})

return {
  publicAttribs
}
 