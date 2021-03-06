local platform  = require("globals/platform.nut")
local dagor_fs = require("dagor.fs")
local dagor_sys = require("dagor.system")
local {startswith} = require("string")
local game_name = require("app").get_game_name()
local dainput = require("dainput2")

local controlsList = require_optional("content/{0}/config/{0}.controls_presets_list.nut".subst(game_name))
  ?? require_optional($"{game_name}/content/common/config/controls_presets_list.nut")
  ?? {}
local curPlatformId = platform.id

if (controlsList?[curPlatformId] == null)
   controlsList[curPlatformId] <- [dainput.get_default_preset_prefix()]
local generation = ::Watched(0)
local haveChanges = persist("haveChanges", @() ::Watched(false))


local function mkPresetNameFromPresetPath(path){
  local split = path.split("/")
  local preset_name = split[split.len()-1]
  preset_name = preset_name.replace($"{game_name}.", "")
  return preset_name
}


local locPreset = function(name) {
  name = name?.name ?? mkPresetNameFromPresetPath(name)
  return ::loc($"controls/preset_{name}", ::loc(name))
}

local Preset = class {
  name = null
  preset = null
  constructor(_preset, _name = null){
    name = _name ?? locPreset(_preset)
    preset = _preset
  }
  function tostring(){
    return name
  }
  function value(){
    return this
  }
}

local function gatherByBpath(path) {
  local use_realfs = (dagor_sys.DBGLEVEL > 0) ? true: false
  return dagor_fs.scan_folder({root=path, vromfs = true, realfs = use_realfs, recursive = false, files_suffix=".c0.preset.blk"})
    .map(@(v) startswith(v, "/") ? (v.slice(1)).replace(".c0.preset.blk", "") : v.replace(".c0.preset.blk", ""))
}
local function substringInList(substring, list){
  foreach(v in list){
    if (v.indexof(substring)!=null)
      return true
  }
  return false
}

local function gatherPresets(){
  local availablePresets = gatherByBpath("content/{0}/config".subst(game_name)).extend(gatherByBpath("content/common/config"))
  availablePresets = controlsList?[curPlatformId]?.filter(@(v) substringInList(v, availablePresets)) ?? []
  return availablePresets.map(@(v) Preset(v))
}
local availablePresets = ::Watched(gatherPresets())

local idIn = @(list, val) list.indexof(val) != null
local getActionTags = ::memoize(@(action_handler)
  dainput.get_group_tag_str_for_action(action_handler).split(",").map(@(v) v.replace(" ","")).filter(@(v) v!=""))

const platform_suffix = "platform="
local function mkSubTagsFind(suffix){
  return ::memoize(function(action_handler){
    foreach (tag in getActionTags(action_handler)){
      if (startswith(tag, suffix)) {
        tag = tag.slice(suffix.len())
        return tag.split("/").map(@(v) v.replace(" ","")).filter(@(v) v!="")
      }
    }
    return null
  })
}
local getSubTagsForPlatform = mkSubTagsFind(platform_suffix)
local isActionForPlatform = ::memoize(function(action_handler){
  local platforms = getSubTagsForPlatform(action_handler)
  if (platforms != null) {
    if (platform.is_pc && idIn(platforms,"pc"))
      return true
    if (platform?.is_console && idIn(platforms,"console"))
      return true
    if (idIn(platforms, platform.id))
      return true
    return false
  }
  return true
})

local function getActionsList() {
  local res = []
  local total = dainput.get_actions_count()
  for (local i = 0; i < total; i++) {
    local ah = dainput.get_action_handle_by_ord(i)
    if (dainput.is_action_internal(ah) || !isActionForPlatform(ah))
      continue
    local actionType = dainput.get_action_type(ah)
    if ([dainput.TYPEGRP_DIGITAL, dainput.TYPEGRP_AXIS, dainput.TYPEGRP_STICK].indexof(actionType & dainput.TYPEGRP__MASK) != null)
      res.append(ah)
  }
  return res
}

local importantGroups = Watched([ "Movement", "Weapon", "View", "Vehicle" ])

return {
  importantGroups
  generation
  haveChanges
  availablePresets
  locPreset
  Preset
  controlsList

  getActionsList
  getActionTags

  mkSubTagsFind
}
 