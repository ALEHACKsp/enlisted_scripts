local platform = require("globals/platform.nut")
local versions = require("enlisted/changelog/versions.nut")
local {mkVersionFromString, versionToInt} = require("std/version.nut")
local {language} = require("enlist/state/clientState.nut")

local { onlineSettingUpdated, settings } = require("enlist/options/onlineSettings.nut")

const pathprefix = "enlisted/changelog/changelogs/"
const SAVE_ID = "ui/lastSeenVersionInfoNum"
local langFile = @(version, lang) "{0}{1}_{2}.nut".subst(pathprefix,"_".join(version), lang)

local lastSeenVersionInfoNumState = ::Computed(function() {
  if (!onlineSettingUpdated.value)
    return -1
  return settings.value?[SAVE_ID] ?? 0
})

local chosenPatchnote = ::Watched(null)

const maxPatchnotesNum = 10

versions = versions
  .slice(0, maxPatchnotesNum)
  .filter(function(object){
    return object?.platform == null || object.platform.indexof(platform.id)!=null || (platform.is_pc && object.platform.indexof("pc")!=null)
  })
  .map(function(v) {
    local version = mkVersionFromString(v.version)
    local title = v?.title?[language.value.tolower()] ?? v?.title?["english"] ?? v?.title["def"] ?? v?.title
    local tVersion = ".".join(version)
    if (::type(title)!="string")
      title = tVersion
    return {version = version, iVersion = versionToInt(version), tVersion = tVersion, versionType = v?.type, title=title}
  })

local function isVersion(version){
  return ::type(version?.version) == "array" && type(version?.iVersion) == "integer" && type(version?.tVersion) == "string"
}

local function findBestVersionToshow(versionsList = versions, lastSeenVersionNum=0) {
  //here we want to find first unseen Major version or last unseed hotfix version.
  lastSeenVersionNum = lastSeenVersionNum ?? 0
  versionsList = versionsList ?? []
  foreach (version in versionsList) {
    if (lastSeenVersionNum < version.iVersion && version.versionType=="major"){
      return version
    }
  }
  local res = null
  foreach(version in versionsList)
    if (version.iVersion > lastSeenVersionNum)
      res = version
    else
      break
  return res
}

local function markSeenVersion(v) {
  if (v == null)
    return
  if (v.iVersion > lastSeenVersionInfoNumState.value)
    settings[SAVE_ID] <- v.iVersion
}

local unseenPatchnote = ::Computed(
  @() onlineSettingUpdated.value ? findBestVersionToshow(versions, lastSeenVersionInfoNumState.value) : null)
local curPatchnote = ::Computed(@() chosenPatchnote.value ?? unseenPatchnote.value ?? versions?[0])

local curPatchnoteIdx = ::Computed( @() versions.indexof(curPatchnote.value) ?? 0)
local updateVersion = @() markSeenVersion(curPatchnote.value)

local function chosePatchnote(version) {
  updateVersion()
  chosenPatchnote(version)
}

local curVersionInfo = ::Computed(function(){
  local curPatch = curPatchnote.value
  local lang = language.value
  if (!isVersion(curPatch))
    return null
  local res
  try {
    res = require_optional(langFile(curPatch.version, lang)) ?? require_optional(langFile(curPatch.version, "en"))
  }
  catch(e){
    log_for_user(::loc("Some errors happened during loading update info"))
    log(e)
  }
  return res
})

local function haveUnseenMajorVersions(){
  local bestUnseenVersion = findBestVersionToshow(versions, lastSeenVersionInfoNumState.value)
  return (bestUnseenVersion != null && bestUnseenVersion.versionType == "major")
}

local function haveUnseenHotfixVersions(){
  local bestUnseenVersion = findBestVersionToshow(versions, lastSeenVersionInfoNumState.value)
  return (bestUnseenVersion != null && bestUnseenVersion.versionType != "major")
}

local haveUnseenVersions = ::Computed(@() unseenPatchnote.value != null)

local function changePatchNote(delta=1){
  return function() {
    local nextIdx = clamp(curPatchnoteIdx.value-delta, 0, versions.len()-1)
    chosePatchnote(versions[nextIdx])
  }
}
local nextPatchNote = changePatchNote()
local prevPatchNote = changePatchNote(-1)

console.register_command(@() SAVE_ID in settings.value ? delete settings[SAVE_ID] : null, "changelog.reset")

return {
  chosePatchnote = chosePatchnote
  curPatchnote = curPatchnote
  versions = versions
  isVersion = isVersion
  findBestVersionToshow = findBestVersionToshow
  haveUnseenHotifxVersions = haveUnseenHotfixVersions
  haveUnseenVersions = haveUnseenVersions
  haveUnseenMajorVersions = haveUnseenMajorVersions
  curVersionInfo = curVersionInfo
  curPatchnoteIdx = curPatchnoteIdx
  nextPatchNote = nextPatchNote
  prevPatchNote = prevPatchNote
  updateVersion = updateVersion
}
 