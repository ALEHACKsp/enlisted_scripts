local { watchedHeroEid } = require("ui/hud/state/hero_state_es.nut")
local { localPlayerEid, localPlayerTeam } = require("local_player.nut")
local remap_nick = require("globals/remap_nick.nut")


//===============heroes stats===============
local heroesTrackComps = [
  ["team", ::ecs.TYPE_INT],
  ["isAlive", ::ecs.TYPE_BOOL],
  ["isDowned", ::ecs.TYPE_BOOL],
  ["possessedByPlr", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
  ["human_anim.vehicleSelected", ::ecs.TYPE_EID, INVALID_ENTITY_ID]
]


local teammatesHeroes = Watched({})

local function deleteEid(eid, state){
  if (eid in state.value)
    delete state[eid]
}

::ecs.register_es("human_teammates_stats_ui_es",
  {
    [["onChange","onInit"]] = function(evt, eid, comp){
      if (localPlayerTeam.value != comp["team"]){
        deleteEid(eid, teammatesHeroes)
        return
      }
      else{
        local res = {}
        foreach (i in heroesTrackComps)
          res[i[0]] <- comp[i[0]]
        teammatesHeroes.update(@(value) value[eid] <- res)
      }
    },
    function onDestroy(evt, eid, comp){
      deleteEid(eid, teammatesHeroes)
    }
  },
  {comps_track = heroesTrackComps}
)

//===============player teammates stats===============

local players = persist("players", @() Watched({}))

local playerCompsTrack = [
  ["team", ::ecs.TYPE_INT],
  ["is_local", ::ecs.TYPE_BOOL, false],
  ["disconnected", ::ecs.TYPE_BOOL],
  ["possessed", ::ecs.TYPE_EID],
  ["name", ::ecs.TYPE_STRING]
]

::ecs.register_es("human_teammates_players_ui_es",
  {
    [["onInit", "onChange"]] = function(evt, eid, comp){
      if (comp["is_local"] || comp["team"] != localPlayerTeam.value){
        deleteEid(eid, players)
        return
      }
      else {
        local res = {}
        foreach (i in playerCompsTrack){
          local compName = i[0]
          res[compName] <- comp[compName]
        }
        players.update(@(value) value[eid] <- res)
      }
    },
    function onDestroy(evt, eid, comp){
      deleteEid(eid, players)
    }
  },
  {comps_track = playerCompsTrack, comps_rq = ["player"]}
)

//===============join in out result===============
local teammatesPlayersOut = Computed(function(){
  local res = players.value.filter(@(info) info.team == localPlayerTeam.value)
  local localPlayerEidV = localPlayerEid.value
  if (localPlayerEidV in res)
    delete res[localPlayerEidV]
  local heroes = teammatesHeroes.value
  foreach (eid, playerInfo in res){
    local possessed = playerInfo.possessed
    playerInfo.isAlive <-  possessed in heroes ? heroes[possessed].isAlive : false
  }
  return res
})

local teammatesAvatars = Computed(function(){
  local res = teammatesHeroes.value.filter(@(info) info.team == localPlayerTeam.value)
  local localHeroEid = watchedHeroEid.value
  if (localHeroEid in res)
    delete res[localHeroEid]
  local playersVal = players.value
  foreach (eid, heroInfo in res){
    local possessedByPlr = heroInfo.possessedByPlr
    heroInfo.name <- possessedByPlr in playersVal ? remap_nick(playersVal[possessedByPlr].name) : null
    heroInfo.disconnected <- possessedByPlr in playersVal ? playersVal[possessedByPlr].disconnected : true
  }
  return res
})

local teammatesConnectedNum = ::Computed(function() {
  local val = teammatesPlayersOut.value
  local teamMembersNum = 0
  foreach (k,v in val){
    if (!(v?.disconnected ?? true))
      teamMembersNum++
  }
  return teamMembersNum
})

local teammatesAliveNum = ::Computed(function(){
  local val = teammatesPlayersOut.value
  local teamMembersNum = 0
  foreach (k,v in val){
    if (!(v?.disconnected ?? true) && v.isAlive)
      teamMembersNum++
  }
  return teamMembersNum
})

return {
  teammatesAvatars = teammatesAvatars
  teammatesConnectedNum = teammatesConnectedNum
  teammatesAliveNum = teammatesAliveNum
}

 