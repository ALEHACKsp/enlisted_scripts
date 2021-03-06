                    
                        
                                                                                                                                               
                                                                                                 
  

                              
local state = make_persists(persist, {
  localPlayerKills = Watched(0)
  localPlayerDeaths = Watched(0)
  localPlayerHeadshots = Watched(0)
  localPlayerAwards = Watched([])
  localPlayerKillRating = Watched(0.0)
  localPlayerKillRatingChange = Watched(0.0)
  localPlayerWinRating = Watched(0.0)
  localPlayerWinRatingChange = Watched(0.0)
  localPlayersBattlesPlayed = Watched(-1)
  localPlayerNamePrefixIcon = Watched("")
})

local function trackScores(evt,eid,comp){
  if (comp["is_local"]) {
    state.localPlayerKills.update(comp["scoring_player.kills"])
    state.localPlayerDeaths.update(comp["scoring_player.deaths"])
    state.localPlayerHeadshots.update(comp["scoring_player.headshots"])
    state.localPlayersBattlesPlayed.update(comp["scoring_player.battlesPlayed"])

    state.localPlayerKillRating.update(comp["scoring_player.killRating"])
    state.localPlayerKillRatingChange.update(comp["scoring_player.killRatingChange"])
    state.localPlayerWinRating.update(comp["scoring_player.winRating"])
    state.localPlayerWinRatingChange.update(comp["scoring_player.winRatingChange"])
    state.localPlayerNamePrefixIcon(comp["namePrefixIcon"])
  }
}
::ecs.register_es("local_player_scores_ui_es",
  { onChange = trackScores onInit = trackScores},
  {
    comps_track = [
      ["is_local", ::ecs.TYPE_BOOL],
      ["scoring_player.battlesPlayed", ::ecs.TYPE_INT, 0],
      ["scoring_player.kills", ::ecs.TYPE_INT, 0],
      ["scoring_player.deaths", ::ecs.TYPE_INT, 0],
      ["scoring_player.headshots", ::ecs.TYPE_INT, 0],
      ["scoring_player.killRating", ::ecs.TYPE_FLOAT, -1.0],
      ["scoring_player.killRatingChange", ::ecs.TYPE_FLOAT, 0.0],
      ["scoring_player.winRating", ::ecs.TYPE_FLOAT, -1.0],
      ["scoring_player.winRatingChange", ::ecs.TYPE_FLOAT, 0.0],
      ["namePrefixIcon", ::ecs.TYPE_STRING, ""],
    ],
    comps_rq = ["player"],
  }
)

///=========player awards=====
  //awards are ECS ARRAY of something that looks like table but is not
  //you can't just work with array - it is PITA and probably not supportd

local function trackAwards(evt,eid,comp){
  if (comp.is_local) {
    state.localPlayerAwards.update(comp["awards"].getAll())
  }
}

::ecs.register_es("local_player_awards_ui_es",
  { onChange = trackAwards onInit = trackAwards},
  {
    comps_track = [["is_local", ::ecs.TYPE_BOOL], ["awards", ::ecs.TYPE_ARRAY]],
    comps_rq = ["player"],
  }
)

return state
 