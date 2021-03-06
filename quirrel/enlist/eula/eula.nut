local colors = require("ui/style/colors.nut")
local platform = require("globals/platform.nut")
local msgbox = require("ui/components/msgbox.nut")
local scrollbar = require("daRg/components/scrollbar.nut")
local {safeAreaSize} = require("enlist/options/safeAreaState.nut")
local fs = require("dagor.fs")
local json = require("std/json.nut")
local {language} = require("enlist/state/clientState.nut")
local JB = require("ui/control/gui_buttons.nut")

const NO_VERSION = -1

local json_load = @(file) json.load(file, {logger=log.log, load_text_file = fs.read_text_from_file})

local function loadConfig(fileName) {
  local config = fs.dd_file_exist(fileName) ? json_load(fileName) : null
  local curLang = language.value.tolower()
  if (!(curLang in config))
    curLang = "english"
  return {
    version = config?[curLang]?.version ?? NO_VERSION
    filePath = config?[curLang]?.file
  }
}

local eula = loadConfig("eula/eula.json")
local nda = loadConfig("nda/nda.json")

local postProcessEulaText = @(text) text
if (platform.is_sony) {
  local ps4 = require("ps4")
  postProcessEulaText = function(text) {
    local regionKey = ps4.get_region() == ps4.SCE_REGION_SCEA ? "scea" : "scee"
    local regionText = ::loc($"sony/{regionKey}")
    return $"{text}{regionText}"
  }
}

local customStyleA = {hotkeys=[["^J:X | Enter | Space", {description={skip=true}}]]}
local customStyleB = {hotkeys=[["^Esc | {0}".subst(JB.B), {description={skip=true}}]]}

local function show(version, filePath, decisionCb) {
  if (version == NO_VERSION || filePath == null) {
    // accept if there is no EULA
    if (decisionCb)
      decisionCb(true)
    return
  }
  local eulaTxt = fs.read_text_from_file(filePath)
  eulaTxt = postProcessEulaText("\x09".join(eulaTxt.split("\xE2\x80\x8B")))
  local size = clone safeAreaSize.value
  size[1] -= sh(15) //!!FIX ME: better to count max height by msgBox self, and do not reserve place for buttons here
  local eulaUi = {
    uid = "eula"
    content = {
      size = size
      children = scrollbar.makeVertScroll({
        size = [size[0], SIZE_TO_CONTENT]
        halign = ALIGN_LEFT
        children = {
          size = [size[0] - hdpx(20), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = colors.BtnTextNormal
          font = (sh(100) <= 720) ? Fonts.big_text : Fonts.medium_text
          text = eulaTxt
        }
      }, {
        size = SIZE_TO_CONTENT
        needReservePlace = false
        maxHeight = size[1]
        wheelStep = 30
      })
    }
  }

  if (decisionCb)
    eulaUi.buttons <- [
      {
        text = ::loc("eula/accept")
        isCurrent = true
        action = @() decisionCb(true)
        customStyle = customStyleA
      },
      {
        text = ::loc("eula/reject")
        isCancel = true
        action = @() decisionCb(false)
        customStyle = customStyleB
      }
    ]

  msgbox.showMessageWithContent(eulaUi)
}

local showEula = @(cb) show(eula.version, eula.filePath, cb)
local showNda = @(cb) show(nda.version, nda.filePath, cb)

console.register_command(@() showEula(@(a) log_for_user($"Result: {a}")), "eula.show")
console.register_command(@() showNda(@(a) log_for_user($"Result: {a}")), "nda.show")

return {
  showEula = showEula
  eulaVersion = eula.version
  showNda = showNda
  ndaVersion = nda.version
}
 