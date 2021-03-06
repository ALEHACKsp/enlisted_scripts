                                       
                                                                                                                                              
                                                                         
                                                                                                                       
                                              
                                                                                                                                                                             
                                                                                                    
            
                                                                                           
                                                                                                                                                                                                
                                                                                                                                                                                                     
  


local playerPlace = {
  place = 0,
  totalTeams = 0,
  killerName = "",
  killerNamePrefixIcon = "",

  killRating = 0.0,
  killRatingChange = 0.0,
  killRatingHistory = [],
  winRatingHistory = [],
  winRating = 0.0,
  winRatingChange = 0.0,
  kills = 0,
  deaths = -1,
  awards = {},
  team = -1,
}

local extractionDebriefing = {
  kills = 0,
  deaths = -1,
  awards = {},
  team = -1,
}

local killReport = {
//player_and_playerpossesed
  victim_eid = 0
  victim_team = -1
  victim_squad = -1
  victim_player_eid = 0
  victim_name = ""
  //player_and_playerpossesed
  killer_eid = 0
  killer_team = -1
  killer_squad = -1
  killer_player_eid = 0
  killer_name = ""
  nodeType=0, damageType=0, gunName=""
}

return {
  broadcastEvents = {
    EventStreamerModeToggle = null
    CmdUpdateOptics = null

    EventZoneStartCapture = {eid=-1, team=-1},
    EventZoneStartDecapture = {eid=-1, team=-1},
    EventZoneHalfCaptured = {eid=-1, team=-1},
    EventTeamStartDecapture = {eid=-1, team=-1},
    EventTeamEndDecapture = {eid=-1, team=-1},
  },

  unicastEvents = {
    CmdChatMessage = {mode="team", text="", qmsg=null},
    EventSqChatMessage = {team = "", name="", sender=0, text="", qmsg=null},
    CmdRequestRespawn = {squadId = 0, memberId = 0, spawnGroup = 0},
    CmdCancelRequestRespawn = {squadId = 0, memberId = 0},
    EventTeamItemHint = null,
    EventOnPlayerDebriefing = playerPlace,
    EventOnPlayerPlace = playerPlace,
    EventOnExtractionDebriefing = extractionDebriefing,
    EventEntityActivate = {activate=false},
    EventEntityAboutToDeactivate = null,
    EventBotSpawned = {eid=0},
    EventOnBorderBattleArea = {leaving=false},
    EventOnBorderOldBattleArea = {leaving=false},

    EventStartCameraTracks = null,
    EventStopCameraTracks = null,

    CmdCreateMapPoint = {x=0.0,z=0.0},
    CmdSetMarkMain = {plEid = 0},
    CmdSetMarkEnemy = {plEid = 0},

    EventPlayerBotKilledEntity = { victim = 0, killer = 0 },

    CmdTrackHeroVehicle = null,
    CmdTrackVehicleWithWatched = null,
    EventKillReport = killReport,

    OnModsChanged = null,
    CmdToggleDoor = { openerEid = 0},

    EventRebuiltInventory = null,//workaround for non updating inventory
    CmdEnableDedicatedLogger = { on = true },
    EventOnSpawnError = {reason=""},
    EventLocalPlayerNameChanged = null,

    CmdSendAward = {award=0},
    CmdAddAward = {award=0},

    CmdHeroLogExEvent = { _event = "", _key = "" },
    EventTurretAmmoDepleted = null,
  }
}
 