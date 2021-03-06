local u = require("std/underscore.nut")
local {clusterByRegionMap, getClusterByCode} = require("geo.nut")
local platform = require("platform")
local dagor_sys = require("dagor.system")

local matching_api = require("matching.api")
local matchingCli = require("enlist/matchingClient.nut")
local delayedActions = require("utils/delayedActions.nut")

local onlineSettings = require("enlist/options/onlineSettings.nut")
local {onlineSettingUpdated} = onlineSettings
local onlineSettingsSettings = onlineSettings.settings

local availableClustersDef = ["EU", "RU", "US", "JP"]
local debugClusters = dagor_sys.DBGLEVEL != 0 ? ["debug"] : []

local notify = @(...) log.log.acall([null].extend(vargv))

//set clusters from Matching
local matchingClusters = persist("matchingClusters3", @() Watched([]))
local function fetchClustersFromMatching() {
  local self = ::callee()
  if (!matchingCli.connected.value)
    return

  matchingCli.call("hmanager.fetch_clusters_list",
    function (response) {
      if (response.error != 0) {
        delayedActions.add(self, 5000) //exponential backoff here needed
      }
      else {
        log("clusters from matching server", response)
        matchingClusters.update(response.clusters)
      }
    }
  )
}

matchingClusters.subscribe(function(v){
  if(v.len()==0)
    delayedActions.add(fetchClustersFromMatching, 5000)
})

matchingCli.connected.subscribe(
  function(is_connected) {
    if (is_connected)
      fetchClustersFromMatching()
  }
)

fetchClustersFromMatching()

matching_api.subscribe("hmanager.notify_clusters_changed", function(...) { fetchClustersFromMatching() })
//set clusters from Matching
matchingClusters.subscribe(@(v) console_print("matchingClusters:", v) )
local availableClusters = Computed(function() {
  local available = matchingClusters.value.filter(@(v) v!="debug")
  if (available.len()==0)
    available = (clone availableClustersDef)
  return available.extend(debugClusters)
})

local function validateClusters(clusters, available){
  notify("validate clusters. clusters:", clusters, "available:", available)
  clusters = clusters.filter(@(has, cluster) has && available.indexof(cluster)!=null)
  if (clusters.len()==0){
    local country_code = platform.get_locale_country().toupper()
    log("Country code:", country_code)
    local localData = getClusterByCode({code=country_code, clusterByRegionMap=clusterByRegionMap})
    local cluster = localData.cluster
    log("tryselectCluster:", cluster, "localData:", localData, "available:", available)
    if (available.indexof(cluster) != null)
      clusters[cluster] <- true
  }
  if (clusters.len()==0 && available.len()>0)
    clusters[available[0]] <- true
  notify("result valid clusters:", clusters)
  return clusters
}
local clusters = persist("clusters", @() Watched(validateClusters({}, availableClusters.value)))

onlineSettingUpdated.subscribe(function(v) {
  if (!v)
    return
  console_print("online selectedClusters:", onlineSettingsSettings.value?["selectedClusters"])
  clusters(validateClusters(onlineSettingsSettings.value?["selectedClusters"] ?? {}, availableClusters.value))
})

availableClusters.subscribe(function(available) {
  clusters(validateClusters(clusters.value, available))
})

local oneOfSelectedClusters = ::Computed(function() {
  foreach(c, has in clusters.value)
    if (has)
      return c
  return matchingClusters.value?[0] ?? availableClustersDef[0]
})

clusters.subscribe(function(clustersVal) {
  local needSave = u.isEqual(onlineSettingsSettings.value?["selectedClusters"], clustersVal)
  log("onlineSettingsUpdated:", onlineSettingUpdated.value, "isEqual to current:", needSave, "toSave:", clustersVal)
  if (!onlineSettingUpdated.value || needSave)
    return
  onlineSettingsSettings(@(s) s["selectedClusters"] <- clustersVal.filter(@(has) has))
})


return {
  availableClusters = availableClusters
  clusters = clusters
  oneOfSelectedClusters = oneOfSelectedClusters
}
 