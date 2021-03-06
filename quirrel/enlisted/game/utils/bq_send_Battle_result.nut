local { send_event_bq_with_header = null } = require_optional("bigquery")
local { logerr } = require("dagor.debug")

local function sendBqBattleResult(userId, soldiersStats, expReward, armyData, armyId) {
  if (send_event_bq_with_header == null) {
    logerr("Missing bigquery module. Allowed on dedicated only.")
    return
  }
  local { armyExp, squadsExp, soldiersExp } = expReward
  local hasPrem = (armyData?.premiumExpMul ?? 1.0) > 1

  //send army result
  send_event_bq_with_header("game_events_bq", {
    event_type = "army_battle_result",
    user_id    = userId,                      // int
    army       = armyId,                      // string
    exp        = armyExp,                     // int
    prem       = hasPrem,                     // bool
    activity   = armyData?.activity ?? 0.0    // float
  })

  foreach(squad in (armyData?.squads ?? [])) {
    //send squads result
    local squadId = squad?.squadId
    local premSquad = (squad?.battleExpBonus ?? 0) > 0
    if (squadId in squadsExp)
      send_event_bq_with_header("game_events_bq", {
        event_type = "squad_battle_result",
        user_id    = userId,                        // int
        army       = armyId,                        // string
        squad_id   = squadId,                       // string
        exp        = squadsExp[squadId],  // int
        expBonus   = squad?.expBonus ?? 0.0,        // float
        premSquad  = premSquad,                     // bool
        prem       = hasPrem                        // bool
      })

    local classBonus = armyData?.classBonus ?? {}
    foreach (soldier in (squad?.squad ?? [])) {
      local guid = soldier?.guid
      if (!(guid in soldiersExp))
        continue

      local { time, score } = soldiersStats[guid]
      local { sClass = "", level = 1 } = soldier
      send_event_bq_with_header("game_events_bq", {
        event_type       = "soldier_battle_result",
        user_id          = userId,                       // int
        army             = armyId,                       // string
        squad_id         = squadId,                      // string
        soldier_class    = sClass,                       // string
        soldier_level    = level,                        // int
        soldier_time     = time,                         // float
        score            = score,                        // int
        exp              = soldiersExp[guid],  // int
        expBonus         = classBonus?[sClass] ?? 0.0,   // float
        premSquad        = premSquad,                    // bool
        prem             = hasPrem                       // bool
      })
    }
  }
}

return sendBqBattleResult 