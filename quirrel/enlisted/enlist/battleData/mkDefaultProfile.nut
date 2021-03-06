local json = require("json")
local io = require("io")

local client = require("enlisted/enlist/meta/clientApi.nut")

local function saveDefaultProfile(profile) {
  if (profile == null)
    return
  foreach (armyId, armyData in profile) {
    if (armyData?["armyProgress"] != null)
      delete armyData?["armyProgress"]
  }
  local file = io.file("../prog/scripts/enlisted/game/data/default_client_profile.nut", "wt+")
  file.writestring("return ");
  file.writestring(json.to_string(profile, true))
  file.close()
  log("Saved to default_client_profile.nut")
}

local defProfileArmies = []
foreach (campaign in ["moscow","berlin","normandy","tunisia"])
  defProfileArmies = defProfileArmies.append($"{campaign}_allies", $"{campaign}_axis")

console.register_command(@() client.gen_default_profile(defProfileArmies, @(res) saveDefaultProfile(res?.defaultProfile)), "meta.genDefaultProfile") 