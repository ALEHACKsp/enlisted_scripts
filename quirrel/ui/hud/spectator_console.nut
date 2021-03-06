local rand = require("std/rand.nut")
local findNextSpectatorHumanTargetQuery = ::ecs.SqQuery("findNextSpectatorTargetQuery", {comps_rq=["human"], comps_ro=["isAlive"]}, "isAlive")
local findNextSpectatorTargetQuery = ::ecs.SqQuery("findNextSpectatorTargetQuery", {comps_rq=["transform", "camera.lookDir", "camera.look_at"]})

console.register_command(function(){
  local humans = ::ecs.query_map(findNextSpectatorHumanTargetQuery,@(eid, comp) eid)
  console.command("camera.spectate {0}".subst(rand.chooseRandom(humans)))
},"spectate.randomHuman")

console.register_command(function(){
  local ents = ::ecs.query_map(findNextSpectatorTargetQuery,@(eid, comp) eid)
  console.command("camera.spectate {0}".subst(rand.chooseRandom(ents)))
},"spectate.randomEntity")

local lastSpectated = 0
local function switchSpectate(delta, query){
  local ents = ::ecs.query_map(query, @(eid, comp) eid).sort()
  if (ents.len()==0)
    return
  local lastSpectatedIdx = ents.indexof(lastSpectated) ?? 0
  lastSpectatedIdx = lastSpectatedIdx + delta
  if (lastSpectatedIdx > ents.len()-1)
    lastSpectatedIdx = 0
  if (lastSpectatedIdx < 0)
    lastSpectatedIdx = ents.len()-1
  lastSpectated = ents[lastSpectatedIdx]
  console.command("camera.spectate {0}".subst(ents[lastSpectatedIdx]))
}

console.register_command(@() switchSpectate(1, findNextSpectatorHumanTargetQuery),"spectate.nextHuman")
console.register_command(@() switchSpectate(-1, findNextSpectatorHumanTargetQuery),"spectate.prevHuman")
console.register_command(@() switchSpectate(1, findNextSpectatorTargetQuery),"spectate.next")
console.register_command(@() switchSpectate(-1, findNextSpectatorTargetQuery),"spectate.prev")
console.register_command(@() console.command("camera.spectate 0"), "spectate.stop") 