local { DBGLEVEL } = require("dagor.system")
local { isEqual } = require("std/underscore.nut")
local { Point2, Point3 } = require("dagor.math")
local {
  vehicleInVehiclesScene, itemInArmory, soldierInSoldiers, currentNewItem, scene
} = require("enlisted/enlist/showState.nut")
local { curCampItems } = require("enlisted/enlist/soldiers/model/state.nut")
local { curSquadSoldiersReady } = require("enlisted/enlist/soldiers/model/readySoldiers.nut")
local {
  selectedSquadSoldiers, selectedSquadVehicle
} = require("enlisted/enlist/soldiers/model/chooseSquadsState.nut")
local {EventLevelLoaded} = require("gameevents")
local { createSoldier, createSoldierKwarg } = require("soldier_tools.nut")
local frp = require("std/frp.nut")
local fadeToBlack = require("enlist/fadeToBlack.nut").fade
local transformItem = require("transformItem.nut")

local composedScene = ::Computed(@() selectedSquadSoldiers.value ? "squad" : scene.value)

/*
  TODO:
  - rework:
    - create scene and resources by scene + what to watch in watch and how. to make possible creation of vehicle + squad, as well
  - we want to show weapon \ weapon mods if weapon is selected or we want to choose new weapon
  ? if you are wating too long and not touching mouse\keyboard\gamepad - start scenic cameras
  - scenic cameras should start not from first, but random one
*/

//!----- quick and dirty set cameras ---
local setCameraQuery = ::ecs.SqQuery("setCameraQuery", {
  comps_rw = [
    ["transform", ::ecs.TYPE_MATRIX],
    ["fov", ::ecs.TYPE_FLOAT],
    ["menu_cam.target", ::ecs.TYPE_EID],
    ["menu_cam.dirInited", ::ecs.TYPE_BOOL],
    ["menu_cam.initialDir", ::ecs.TYPE_POINT3],
    ["menu_cam.offset", ::ecs.TYPE_POINT3],
    ["menu_cam.offsetMult", ::ecs.TYPE_POINT3],
    ["menu_cam.limitYaw", ::ecs.TYPE_POINT2],
    ["menu_cam.limitPitch", ::ecs.TYPE_POINT2],
    ["menu_cam.shouldRotateTarget", ::ecs.TYPE_BOOL],
  ],
  comps_rq = ["camera.active"], comps_no=["scene"]})
local setDofQuery = ::ecs.SqQuery("setDofQuery", {comps_rw = [["post_fx", ::ecs.TYPE_OBJECT]]})
local findScenicCamQuery = ::ecs.SqQuery("findScenicCamQuery", {
  comps_ro = [
    ["transform", ::ecs.TYPE_MATRIX],
    ["fov", ::ecs.TYPE_FLOAT],
    ["menu_cam.target", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["menu_cam.offset", ::ecs.TYPE_POINT3, Point3(0.0, 0.0, 0.0)],
    ["menu_cam.offsetMult", ::ecs.TYPE_POINT3, Point3(0.0, 0.0, 0.0)],
    ["menu_cam.limitYaw", ::ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["menu_cam.limitPitch", ::ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["menu_cam.shouldRotateTarget", ::ecs.TYPE_BOOL, false],
    ["scene", ::ecs.TYPE_STRING]
  ]})
local findScenicDofDistQuery = ::ecs.SqQuery("findScenicDofDistQuery", {comps_ro = [
    ["dof.on", ::ecs.TYPE_BOOL],
    ["scene", ::ecs.TYPE_STRING],
    ["dof.nearDofStart", ::ecs.TYPE_FLOAT],
    ["dof.nearDofEnd", ::ecs.TYPE_FLOAT],
    ["dof.nearDofAmountPercent", ::ecs.TYPE_FLOAT],
    ["dof.farDofStart", ::ecs.TYPE_FLOAT],
    ["dof.farDofEnd", ::ecs.TYPE_FLOAT],
    ["dof.farDofAmountPercent", ::ecs.TYPE_FLOAT],
  ]})

local function setDofDist(dof_comp){
  setDofQuery.perform(function(eid, post_fx_comp){
    post_fx_comp.post_fx["dof.on"] = dof_comp["dof.on"]
    post_fx_comp.post_fx["dof.nearDofStart"] = dof_comp["dof.nearDofStart"]
    post_fx_comp.post_fx["dof.nearDofEnd"] = dof_comp["dof.nearDofEnd"]
    post_fx_comp.post_fx["dof.nearDofAmountPercent"] = dof_comp["dof.nearDofAmountPercent"]
    post_fx_comp.post_fx["dof.farDofStart"] = dof_comp["dof.farDofStart"]
    post_fx_comp.post_fx["dof.farDofEnd"] = dof_comp["dof.farDofEnd"]
    post_fx_comp.post_fx["dof.farDofAmountPercent"] = dof_comp["dof.farDofAmountPercent"]
  })
}

local function setCamera(cameraComps){
  setCameraQuery.perform(function(eid, comp){
    foreach (k, v in cameraComps)
      if (k in comp)
        comp[k] = v
  })
}


//!----- quick and dirty create entities for preview ---

local function createEntity(template, transform, callback = null, extraTemplates=[]){
  if (template) {
    template = "+".join([template].extend(extraTemplates))
    return ::ecs.g_entity_mgr.createEntity(template, {transform = transform}, callback)
  }
  return INVALID_ENTITY_ID
}

local logg = DBGLEVEL !=0 ? ::log_for_user : ::log.log
local function makeWeaponTemplate(template){
  if (template == null)
    return null

  local templ = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  local itemTemplate = templ?.getCompValNullable("item.template") ?? templ?.getCompValNullable("item.ammoTemplate")
  if (itemTemplate==null){
    if (templ?.getCompValNullable("animchar.res") != null)
      itemTemplate = template
    else {
      logg("Incorrect template found for weapon meta-template:", template)
      return null
    }
  }
  return ::ecs.makeTemplate({baseTemplate = itemTemplate ?? template, addTemplates = ["item_in_world", "menu_item"]})
}

local function makeWeaponTransform(template, transform){
  if (template == null)
    return transform
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  local templ = db.getTemplateByName(template)
  local baseTemplate = templ?.getCompValNullable("item.template") ?? templ?.getCompValNullable("item.ammoTemplate") ?? template
  if (baseTemplate == null)
    return transform
  local dropTm = db.getTemplateByName(baseTemplate)?.getCompValNullable("dropTm")
  return dropTm != null ? transform * dropTm.inverse() : transform
}

local function setCameraTargetInScene(newScene, targetEid){
  if (composedScene.value != newScene)
    return
  setCamera({["menu_cam.target"] = targetEid})
}

local function resetCameraDirection(){
  setCamera({["menu_cam.dirInited"] = false})
}

local cameraTarget = persist("cameraTarget", @() ::Watched(INVALID_ENTITY_ID))
local isFadeDone = persist("isFadeDone", @() ::Watched(false))

local visibleScene = ::Watched(composedScene.value)

local function makeShowScene(sceneDesc, name){
  local compName = sceneDesc.compName
  local transformItemFunc = sceneDesc?.transformItemFunc ?? transformItem
  local createEntityFunc = sceneDesc?.createEntityFunc ?? createEntity
  local shouldResetCameraDirection = sceneDesc?.shouldResetCameraDirection ?? false
  local query = ::ecs.SqQuery("query{0}".subst(compName), {comps_ro=[["transform", ::ecs.TYPE_MATRIX]], comps_rw = [compName]})
  local watch = sceneDesc.watch
  local visibleWatch = Computed(@() visibleScene.value == name ? watch.value : null)
  local isSceneFading = Computed(@() visibleScene.value == name && !isFadeDone.value)
  local function updateEntity(...) {
    local data = visibleWatch.value
    if (isSceneFading.value)
      return
    local function update(baseEid, comp){
      ::ecs.g_entity_mgr.destroyEntity(comp[compName])
      local observedEid = createEntityFunc(data, transformItemFunc(comp["transform"], data))
      comp[compName] = observedEid

      cameraTarget(observedEid)
      if (shouldResetCameraDirection)
        resetCameraDirection()
    }
    query.perform(update)
  }
  local showScene = sceneDesc.__merge({
    visibleWatch = visibleWatch
    isSceneFading = isSceneFading
    query = query
    updateInScene = updateEntity
  })
  visibleWatch.subscribe(updateEntity)
  isSceneFading.subscribe(updateEntity)
  frp.subscribe(showScene?.slaveWatches ?? [], @(_) visibleScene.value == name ? updateEntity() : null)
  return showScene
}


local objectsToObserve = {
  soldiers = {
    compName = "menu_char_to_control",
    createEntityFunc = createSoldier
    watch = soldierInSoldiers
    slaveWatches = [curCampItems]
  },
  soldier_in_middle = {
    compName = "menu_char_to_control",
    createEntityFunc = @(guid, transform, callback = null)
      createSoldierKwarg({ guid, transform, callback, isDisarmed = true })
    watch = soldierInSoldiers
    slaveWatches = [curCampItems]
  },
  vehicles = {
    compName = "menu_vehicle_to_control",
    transformItemFunc = @(transform, ...) transform
    watch = vehicleInVehiclesScene
  },
  aircrafts = {
    compName = "menu_aircraft_to_control",
    transformItemFunc = @(transform, ...) transform
    watch = vehicleInVehiclesScene
  },
  armory = {
    compName = "menu_weapon_to_control",
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), makeWeaponTransform(template, transform), callback)

    watch = itemInArmory
    shouldResetCameraDirection = true
  },
  new_items = {
    compName = "menu_new_items_to_control",
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), makeWeaponTransform(template, transform), callback)

    watch = currentNewItem
    shouldResetCameraDirection = true
  }
}.map(makeShowScene)

frp.combine([cameraTarget, isFadeDone, composedScene], @(v) v[1] ? setCameraTargetInScene(v[2], v[0]) : null)

local function processScene(...) {
  local curScene = composedScene.value
  if (!curScene)
    return
  isFadeDone(false)
  local cameraNotFound = true
  findScenicCamQuery.perform(function(eid,comp) {
    if (comp.scene != curScene)
      return
    cameraNotFound = false
    local cameraComps = {
      ["menu_cam.dirInited"] = false,
      ["menu_cam.initialDir"] = comp.transform.getcol(2),
    }
    foreach (k, v in comp)
      cameraComps[k] <- v
    fadeToBlack({fadein=0.33, fadeout=0.4 cb = function() {
      setCamera(cameraComps)
      visibleScene(curScene)
      findScenicDofDistQuery.perform(@(dof_eid, dof_comp) dof_comp.scene == curScene ? setDofDist(dof_comp) : null)
      isFadeDone(true)
    }})
  })
  if (cameraNotFound)
    isFadeDone(true)
}
composedScene.subscribe(processScene)

local gettransforms = @(query) ::ecs.query_map(query, @(eid, comp) [comp["transform"], comp["priority_order"]]).sort(@(a,b) a[1]<=>b[1]).map(@(v) v[0])
local destroyEntityByQuery = @(query) query.perform(function(eid, comp) {::ecs.g_entity_mgr.destroyEntity(eid)})

/*
  background objects in squads
  todo:
   - add animated cameras
*/

local lastShownSquadToPlace = []
local currentSquadToPlace = ::Computed(function() {
  local newSquad = selectedSquadSoldiers.value
  if (!newSquad && soldierInSoldiers.value)
    return null

  newSquad = newSquad ?? curSquadSoldiersReady.value
  if (!isEqual(lastShownSquadToPlace, newSquad))
    lastShownSquadToPlace = newSquad
  return lastShownSquadToPlace
})
local vehicleToPlace = ::Computed(function() {
  local vehicle = selectedSquadSoldiers.value
    ? selectedSquadVehicle.value
    : vehicleInVehiclesScene.value
  return vehicle ? [vehicle] : null
})

local squadPlacesQuery = ::ecs.SqQuery("squadPlaces", {comps_ro=["transform", ["priority_order", ::ecs.TYPE_INT, 0]], comps_rq=["menu_soldier_respawnbase"]})
local vehiclesPlacesQuery = ::ecs.SqQuery("vehiclePlaces", {comps_ro=["transform", ["priority_order", ::ecs.TYPE_INT, 0]], comps_rq=["menu_vehicle_respawnbase"]})
local menuBackgroundSoldiersQuery = ::ecs.SqQuery("menuBackgroundSoldiersQuery", {comps_rq=["background_menu_soldier"]})
local menuBackgroundVehiclesQuery = ::ecs.SqQuery("menuVehiclesPlacesQuery", {comps_rq=["background_menu_vehicle"]})
local createdSoldiers = persist("createdSoldiers", @() ::Watched([]))
local createdVehicles = persist("createdVehicles", @() ::Watched([]))
//we duplicate state of created objects by creating with tag and store it in script.
//While it is enough to have it only in script it is not enough to have it in entities, because createEntity is Async and if state is changed in a one frame twice
//objects of first change will be not destroyed (they do not have tags). We can replace to createEntitySync, but this is not reponsive enough
// we can also create entitySync with just tag and than recreate it with tag+all other. That would work will look strange in code

local mkReplaceObjectsFunc = @(placesQuery, objectsQuery, createFunc, createdList)
  function replaceObjects(objects) {
    createdList.value.each(@(eid) ::ecs.g_entity_mgr.destroyEntity(eid))
    destroyEntityByQuery(objectsQuery)
    if (objects == null)
      return
    local places = gettransforms(placesQuery)
    createdList(objects
      .slice(0, min(places.len(), objects.len()))
      .map(@(obj, i) [obj, places[i]]) //zip two arrays
      .map(createFunc))
  }

local replaceSoldiers = mkReplaceObjectsFunc(squadPlacesQuery, menuBackgroundSoldiersQuery, @(v) createSoldierKwarg({guid = v[0]?.guid, transform=v[1], extraTemplates = ["background_menu_soldier"]}), createdSoldiers)
local replaceVehicles = mkReplaceObjectsFunc(vehiclesPlacesQuery, menuBackgroundVehiclesQuery, @(v) createEntity(v[0], v[1], null, ["background_menu_vehicle"]), createdVehicles)
local function currentSquadToPlaceReplace(...){
  fadeToBlack({fadein=0.2, fadeout=0.6 cb = function() {replaceSoldiers(currentSquadToPlace.value)}})
}
local function vehicleToPlaceReplace(...){
  fadeToBlack({fadein=0.2, fadeout=0.3 cb = function() {replaceVehicles(vehicleToPlace.value)}})
}
currentSquadToPlace.subscribe(currentSquadToPlaceReplace)
vehicleToPlace.subscribe(vehicleToPlaceReplace)

//trigger on level loaded
::ecs.register_es("setscene_es", {
    [EventLevelLoaded] = function(evt, eid, comp) {
      processScene()
      objectsToObserve.each(@(v) v.updateInScene())
      currentSquadToPlaceReplace()
      vehicleToPlaceReplace()
   }
})
 