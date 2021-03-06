require("enlisted/enlist/soldiers/model/onlyInEnlistVm.nut")("squadsConfig")
local squadsPresentation = require("enlisted/globals/squadsPresentation.nut")
local serverConfigs = require("enlisted/enlist/configs/configs.nut").configs

local ordered = ::Computed(@() (serverConfigs.value?.squads_config ?? {})
  .map(@(list, armyId) list.map(function(squad, sIdx) {
        local squadPres = squadsPresentation?[armyId][squad?.id] ?? {}
        return squad.__merge(squadPres, { index = sIdx })
      }
    )
  )
)

local byId = ::Computed(@() ordered.value.map(function(list) {
  local res = {}
  foreach (squad in list)
    res[squad.id] <- squad
  return res
}))

return {
  squadsCfgOrdered = ordered
  squadsCfgById = byId
} 