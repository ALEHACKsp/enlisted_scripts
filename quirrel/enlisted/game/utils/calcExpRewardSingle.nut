local function updateStatsForExpCalc(s) {
  s.score <- 100
}

local function calcExpReward(soldiersStats, armyData, armiesState, playerArmy, connectedTime) {
  local squadsExp = {}
  foreach (squad in armyData?.squads ?? []) {
    local squadId = squad?.squadId
    if (squadId != null && (squad?.squad ?? []).findvalue(@(s) s.guid in soldiersStats) != null)
      squadsExp[squadId] <- { exp = 0 }
  }
  return {
    armyExp = 0
    squadsExp = squadsExp
    soldiersExp = soldiersStats.map(@(_) { exp = 0 })
  }
}

return {
  calcExpReward = calcExpReward
  updateStatsForExpCalc = updateStatsForExpCalc
} 