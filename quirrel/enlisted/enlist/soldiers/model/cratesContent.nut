local armyEffects = require("armyEffects.nut")
local { get_crates_content } = require("enlisted/enlist/meta/clientApi.nut")

local cratesContent = ::Watched({})
local requested = {}

armyEffects.subscribe(@(_) cratesContent({}))

local function requestCratesContent(armyId, crates) {
  if ((armyId ?? "") == "")
    return
  local armyCrates = cratesContent.value?[armyId]
  if (armyId not in requested)
    requested[armyId] <- {}
  local armyRequested = requested[armyId]
  local toRequest = crates.filter(@(c) c not in armyCrates && c not in armyRequested)
  if (toRequest.len() == 0)
    return

  toRequest.each(@(c) armyRequested[c] <- true)
  get_crates_content(armyId, toRequest, function(res) {
    toRequest.each(function(c) { if (c in armyRequested) delete armyRequested[c] })
    if ("content" in res)
      cratesContent(@(cc) cc[armyId] <- (cc?[armyId] ?? {}).__merge(res.content))
  })
}

local function getCrateContentComp(armyId, crateId) {
  requestCratesContent(armyId, [crateId])
  local res = ::Computed(@() cratesContent.value?[armyId][crateId])
  res.subscribe(function(r) {
    if (r == null)
      requestCratesContent(armyId, [crateId])
  })
  return res
}

local function collectItemsContent(armyContent, cratesList) {
  local resItems = {}
  foreach(cId in cratesList)
    foreach(tpl in armyContent?[cId].items ?? [])
      resItems[tpl] <- true
  return resItems
}

local function getCratesListItemsComp(armyIdWatch, cratesListWatch) {
  requestCratesContent(armyIdWatch.value, cratesListWatch.value)
  local res = ::Computed(@() collectItemsContent(cratesContent.value?[armyIdWatch.value], cratesListWatch.value))
  res.subscribe(@(r) requestCratesContent(armyIdWatch.value, cratesListWatch.value)) //request filter duplicate or already received crates
  return res
}

return {
  getCrateContentComp = getCrateContentComp
  getCratesListItemsComp = getCratesListItemsComp
} 