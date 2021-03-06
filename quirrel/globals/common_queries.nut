local find_player_by_connidQuery = ::ecs.SqQuery("find_player_by_connidQuery", {comps_ro=[["connid", ::ecs.TYPE_INT]], comps_rq=["player"]})
local function find_player_by_connid(filter_connid){
  return find_player_by_connidQuery.perform(@(eid, comp) eid, "eq(connid,{0})".subst(filter_connid))
}

local find_player_that_possessQuery = ::ecs.SqQuery("find_player_that_possessQuery", {comps_ro=[["possessed", ::ecs.TYPE_EID],["disconnected", ::ecs.TYPE_BOOL]], comps_rq = ["player"]})

local function find_any_player_that_possess(possessed_eid){
  if (possessed_eid == INVALID_ENTITY_ID)
    return INVALID_ENTITY_ID
  return find_player_that_possessQuery.perform(@(eid, comp) eid, "eq(possessed,{0}:eid)".subst(possessed_eid)) ?? INVALID_ENTITY_ID
}

local function find_connected_player_that_possess(possessed_eid){
  if (possessed_eid == INVALID_ENTITY_ID)
    return INVALID_ENTITY_ID
  return find_player_that_possessQuery.perform(@(eid, comp) eid, "and(eq(possessed,{0}:eid),eq(disconnected,false))".subst(possessed_eid)) ?? INVALID_ENTITY_ID
}

local find_local_player_compsQuery = ::ecs.SqQuery("find_local_player_compsQuery", {comps_ro=[["is_local", ::ecs.TYPE_BOOL]], comps_rq = ["player"]}, "is_local")
local function find_local_player(){
  return find_local_player_compsQuery.perform(@(eid, comp) eid)
}

local get_controlledHeroQuery = ::ecs.SqQuery("get_controlled_heroQuery",  {comps_ro=[["possessed", ::ecs.TYPE_EID],["is_local", ::ecs.TYPE_BOOL]], comps_rq=["player"]}, "is_local")
local function get_controlled_hero(){
  return get_controlledHeroQuery.perform(@(eid, comp) comp["possessed"]) ?? INVALID_ENTITY_ID
}

local get_watchedHeroQuery = ::ecs.SqQuery("get_watched_heroQuery",  {comps_ro=[["watchedByPlr", ::ecs.TYPE_EID]]})
local function get_watched_hero(){
  local local_player = find_local_player()
  return get_watchedHeroQuery.perform(@(eid, comp) eid, $"eq(watchedByPlr,{local_player}:eid)") ?? INVALID_ENTITY_ID
}


local get_teamQuery = ::ecs.SqQuery("get_teamQuery",  {comps_ro = [["team.id", ::ecs.TYPE_INT]]})
local function get_team_eid(team_id){
  return get_teamQuery.perform(@(eid, comp) eid, "eq(team.id,{0})".subst(team_id)) ?? INVALID_ENTITY_ID
}

local find_local_player_team_Query = ::ecs.SqQuery("find_local_player_team_Query", {comps_ro=[["is_local", ::ecs.TYPE_BOOL],["team", ::ecs.TYPE_INT]], comps_rq = ["player"]}, "is_local")
local function get_local_player_team(){
  return find_local_player_team_Query.perform(@(eid, comp) comp["team"])
}

return {
  find_player_by_connid = find_player_by_connid
  find_any_player_that_possess = find_any_player_that_possess
  find_connected_player_that_possess = find_connected_player_that_possess
  find_local_player = find_local_player
  get_controlled_hero = get_controlled_hero
  get_team_eid = get_team_eid
  get_watched_hero = get_watched_hero
  get_local_player_team = get_local_player_team
}
 