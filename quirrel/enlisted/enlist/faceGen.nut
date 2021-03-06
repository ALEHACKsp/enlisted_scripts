local Rand = require("std/rand.nut")
local curGenFaces = require("enlisted/faceGen/gen_faces.nut")
local animTreeGenFaces = require("enlisted/faceGen/animTree_gen_faces.nut")

local headsCompsQuery = ::ecs.SqQuery("headsCompsQuery", {comps_ro=["animcharParams", "collres.res","item.uniqueName"]})

local function genFaceConfig(faceConfig, rand){
  local face = {}
  local faceType = faceConfig["race"]
  face["lip_thickness"] <- rand.rfloat(0.7, 2.0);
  face["lip_size"] <-rand.rfloat(0.7, 1.5);
  face["low_lip_root_y"] <- rand.rfloat(0.0, 1.0);
  face["ears_angles"] <- rand.rfloat(0.0, 0.8);
  face["ears_size"] <- rand.rfloat(0.6, 1.3);
  face["eyes_angle"] <- rand.rfloat(-0.5, 0.5);
  face["nose_root_vert"] <- rand.rfloat(-1, 0.2);
  face["nose_root_rotate"] <- rand.rfloat(-0.5, 0.8);
  face["nose_fracture"] <- rand.rfloat(-0.3, 0.3);
  local nose_frac = rand.rint(-7,7)
  if (nose_frac == 0) {
    if (rand.rint(0,1) > 0)
      face["nose_fracture"] <- rand.rfloat(-1, -0.7);
    else
      face["nose_fracture"] <- rand.rfloat(0.7, 1);
  }
  face["nose_center_2_scale_x"] <-rand.rfloat(0.3, 2.0);
  face["nose_root_scale_diff"] <- rand.rfloat(0, 0.5);
  face["bottom_face_rot"] <- rand.rfloat(-0.5, 0.0);
  face["bottom_face_vert"] <- rand.rfloat(-1.0, 0.5);
  face["bottom_face_forw"] <- rand.rfloat(-3.4, 5);
  face["chin_face_vert"] <- rand.rfloat(-0.9, 1.0);
  face["chin_face_forw"] <-rand.rfloat(-1.0, 1);
  face["chin_face_rot"] <-rand.rfloat(-0.5, 1.0);
  face["chin_face_hor_scale"] <-rand.rfloat(0.3, 2);
  face["second_chin_face_hor_scale"] <-rand.rfloat(0.2, 2.2);
  face["cheeks_hor"] <- rand.rfloat(-2.0, 2.0); // изменяю
  face["cheeks_vert"] <- rand.rfloat(0, 2.0);
  face["forehead_pos_y"] <- rand.rfloat(-2, 2);
  face["forehead_scale"] <- rand.rfloat(0.6, 1.2);
  face["forehead_hor_scale"] <- rand.rfloat(0.4, 1.5);
  face["jaw_root_bottom_scale"] <- rand.rfloat(0.80, 1.0);
  if (faceType == 1) {
    face["lip_size"] <-rand.rfloat(0.6 1.8);
    face["lip_thickness"] <- rand.rfloat(0.0, 1.0);
    if (face["lip_size"] < 0.8)
      face["lip_thickness"] = 1 - ((1 - face["lip_size"]) * 3)
    face["eyes_angle"] <- rand.rfloat(0.00, 1.0);
    face["asia_eye"] <- face["eyes_angle"] / 2;
    face["nose_root_scale_diff"] <- rand.rfloat(0, 0.2);
    face["ears_angles"] <- rand.rfloat(0.0, 0.5);
  }
  if (faceType == 2) {
    face["lip_thickness"] <-rand.rfloat(0.5, 1.5);
    face["lip_size"] <-rand.rfloat(0.9, 1.5);
    face["nose_root_scale_diff"] <- rand.rfloat(0, 0.75);
    face["chin_face_rot"] <-rand.rfloat(-0.5, 0.5)
    face["ears_angles"] <- rand.rfloat(0.0, 0.5);
    face["jaw_root_bottom_scale"] <- rand.rfloat(0.50, 1.0);
  }
  foreach (param, value in faceConfig)
    if (param != "race")
      face[param] = rand.rfloat(value["x"],value["y"])
  return face
}

local function safeFaceToJson(data){
  local json = require("json")
  local io = require("io")
  local file = io.file("EUFaces.json", "wt+")
  file.writestring(json.to_string(data, true))
  file.close()
  log("Saved to EUFaces.json")
}

console.register_command(function(asset, num) {
  local rand = Rand()
  log("These face parameters will change")
  local data =  {}
  foreach(nameOfAsset, value in curGenFaces)
    data[nameOfAsset] <- value

  foreach(nameOfAsset, value in animTreeGenFaces)
    if (nameOfAsset == asset)
      data[nameOfAsset][num.tostring()] = genFaceConfig(value, rand)
  safeFaceToJson(data)

},"faceGen.fixErrorFace")

console.register_command(function() {
  ::log_for_user("These face parameters are not attractive")
  headsCompsQuery.perform(function (eid, comp) {
    ::log_for_user(comp["collres.res"], comp["item.uniqueName"])
    ::log_for_user(comp["animcharParams"].getAll())
  })
},"faceGen.faceError")

console.register_command(function(asset, num) {
  log("Add new face animchar to faceGen")
  log("Do not forget to add a name to animTree_gen_faces!")
  local data =  {}
  local rand = Rand()
  if(curGenFaces?[asset]){
    log("ERROR This animchar is already in the config file")
    return
  }
  foreach(nameOfAsset, value in curGenFaces)
    data[nameOfAsset] <- value
  local curNumConfig = {}
  for (local i = 0; i < num; i++)
    curNumConfig[i] <- genFaceConfig(animTreeGenFaces[asset], rand)
  data[asset] <- curNumConfig
  safeFaceToJson(data)

},"faceGen.AddNewFace")


console.register_command(function(num) {
  local data =  {}
  local rand = Rand()
  foreach(nameOfAsset, value in animTreeGenFaces){
    if (value == -1)
      continue
    local curAssetFaces = {}
    if(curGenFaces?[nameOfAsset])
      log(curGenFaces?[nameOfAsset].len(), nameOfAsset, " faces in gen")
    else
      log("no faces with asset ", nameOfAsset)
    for (local i = 0; i < (curGenFaces?[nameOfAsset].len() ?? 0); i++)
      curAssetFaces[i] <- curGenFaces?[nameOfAsset][i.tostring()]

    for (local i = 0; i < num; i++)
      curAssetFaces[(curGenFaces?[nameOfAsset].len() ?? 0) + i] <- genFaceConfig(value, rand)

    data[nameOfAsset] <- curAssetFaces
  }
  safeFaceToJson(data)
}, "faceGen.genEUFaces") 