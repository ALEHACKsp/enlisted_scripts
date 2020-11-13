local {get_setting_by_blk_path} = require("settings")
local {safeAreaAmount, safeAreaBlkPath, safeAreaList, safeAreaSetAmount, safeAreaCanChangeInOptions} = require("globals/safeArea.nut")
local platform = require("globals/platform.nut")
local {get_arg_value_by_name, DBGLEVEL} = require("dagor.system")

local {loc_opt, defCmp, getOnlineSaveData, optionPercentTextSliderCtor, optionCheckBox, optionCombo, optionSlider,
  mkDisableableCtor
} = require("options_lib.nut")
local { resolutionList, resolutionValue } = require("resolution_state.nut")
local { DLSS_BLK_PATH, DLSS_OFF, dlssAvailable, dlssValue, dlssToString, dlssSetValue, dlssNotAllowLocId
} = require("dlss_state.nut")
local { LOW_LATENCY_BLK_PATH, LOW_LATENCY_OFF, lowLatencyAvailable, lowLatencyValue, lowLatencySetValue,
  lowLatencyToString, lowLatencySupported
} = require("low_latency_options.nut")

local { availableMonitors, monitorValue, get_friendly_monitor_name } = require("monitor_state.nut")

local resolutionToString = @(v) typeof v == "string" ? v : $"{v[0]} x {v[1]}"

local PS4_MODE_CHANGE_ENABLED = true

local availableGraphicPresets = ["HighFPS"]
if (platform.is_xbox)
  availableGraphicPresets = [ "HighQuality", "HighFPS" ]
else if (platform.is_ps4)
  availableGraphicPresets = !PS4_MODE_CHANGE_ENABLED ? [ "HighFPS" ] : [ "HighQuality", "HighFPS" ]
else if (platform.is_ps5)
  availableGraphicPresets = ["HighQuality"]

local hfps_taa_mip_bias = (platform.is_xboxone_X || platform.is_xbox_scarlett || platform.is_ps4_pro || platform.is_ps5) ? -0.25 : 0.0
local hq_taa_mip_bias = (platform.is_xboxone_X || platform.is_xbox_scarlett) ? -0.5 : -0.25
const hfps_anisotropy = 2
const hq_anisotropy = 4

local forceGraphicPreset = platform.is_console ? get_arg_value_by_name("graphicPreset") : null
if (forceGraphicPreset != null) {
  if (availableGraphicPresets.indexof(forceGraphicPreset) != null) {
    log("force graphic preset {0}".subst(forceGraphicPreset))
    availableGraphicPresets = [forceGraphicPreset]
  }
  else {
    log("unknwon graphic preset {0}, allowed presets: {1}".subst(forceGraphicPreset), availableGraphicPresets)
    forceGraphicPreset = null
  }
}

local videoXboxPreset = getOnlineSaveData("video/xboxPreset", @() availableGraphicPresets[0],
  @(p) availableGraphicPresets.indexof(p) != null ? p : availableGraphicPresets[0])

local gammaCorrectionSave = getOnlineSaveData("graphics/gamma_correction",
  @() 1,
  @(p) clamp(p, 0.5, 1.5)
)

local optInBattleGraphicsPreset = {
  name = ::loc("options/graphicsPreset")
  isAvailable = @() platform.is_xbox
  widgetCtor = optionCombo
  tab = "Graphics"
  var = videoXboxPreset.watch
  setValue = videoXboxPreset.setValue
  defVal = forceGraphicPreset ?? "HighFPS"
  available = availableGraphicPresets
  valToString = loc_opt
  blkPath = "video/resolution"
  convertForBlk = @(v) resolutionToString(resolutionList.value?[v == "HighFPS" ? 0 : 1] ?? "auto")
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/lodsShiftDistMul", val = (val == "HighFPS" ? 1.3 : 1.0)},
      {blkPath = "graphics/IndoorProbes", val = true},
      {blkPath = "graphics/supportsIndoorProbes", val = true},
      {blkPath = "graphics/taa_mip_bias", val = (val == "HighFPS" ? hfps_taa_mip_bias : hq_taa_mip_bias)},
      {blkPath = "graphics/taaQuality",   val = (val == "HighQuality" || (platform.is_xboxone_X || platform.is_xbox_scarlett) ? 1 : 0)},
      {blkPath = "graphics/anisotropy", val = (val == "HighFPS" ? hfps_anisotropy : hq_anisotropy)},
      {blkPath = "graphics/aoQuality", val = (val == "HighFPS" ? ((platform.is_xboxone_X || platform.is_xbox_scarlett) ? "medium": "low") : "high")},
      {blkPath = "graphics/groundDeformations", val = (val == "HighQuality" && (platform.is_xboxone_X || platform.is_xbox_scarlett) ? "medium" : "low")},
      {blkPath = "graphics/shadowsQuality", val = (val == "HighQuality" && (platform.is_xboxone_X || platform.is_xbox_scarlett) ? "high" : "low")},
      {blkPath = "graphics/effectsShadows", val = (val == "HighQuality" || (platform.is_xboxone_X || platform.is_xbox_scarlett) ? true : false)},
      {blkPath = "graphics/dropletsOnScreen", val = (val == "HighQuality")},
      {blkPath = "graphics/scopeImageQuality", val = (val == "HighQuality" ? 1 : 0)},
      {blkPath = "graphics/onlyHighResFx", val = (val == "HighQuality")},
      {blkPath = "graphics/shouldRenderCokpitPrepass", val = (val == "HighQuality")},
      {blkPath = "graphics/giQuality", val = (val == "HighQuality" && (platform.is_xboxone_X || platform.is_xbox_scarlett)) ? "medium" : "off"},
      {blkPath = "graphics/skiesQuality", val = (platform.is_xboxone_s ? "low" : (val == "HighFPS" ? "medium" : "high"))}
    ]
  }
}

local optGraphicsPreset = {
  name = ::loc("options/graphicsPreset")
  isAvailable = @() platform.is_ps4
  widgetCtor = optionCombo
  tab = "Graphics"
  var = videoXboxPreset.watch
  setValue = videoXboxPreset.setValue
  defVal = (PS4_MODE_CHANGE_ENABLED ? forceGraphicPreset : null) ?? "HighFPS"
  available = availableGraphicPresets
  valToString = loc_opt
  blkPath = "video/resolution"
  convertForBlk = @(v) resolutionToString(resolutionList.value?[v == "HighFPS" ? 0 : 1] ?? "auto")
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/lodsShiftDistMul", val = (val == "HighFPS" ? 1.3 : 1.0)},
      {blkPath = "graphics/IndoorProbes", val = true},
      {blkPath = "graphics/supportsIndoorProbes", val = true},
      {blkPath = "graphics/taa_mip_bias", val = (val == "HighFPS" ? hfps_taa_mip_bias : hq_taa_mip_bias)},
      {blkPath = "graphics/taaQuality",   val = (val == "HighQuality" || (platform.is_ps4_pro || platform.is_ps5) ? 1 : 0)},
      {blkPath = "graphics/anisotropy", val = (val == "HighFPS" ? hfps_anisotropy : hq_anisotropy)},
      {blkPath = "graphics/aoQuality", val = (val == "HighFPS" ? (platform.is_ps4_pro ? "medium": "low") : "high")},
      {blkPath = "graphics/groundDeformations", val = (val == "HighQuality" && platform.is_ps4_pro ? "medium" : "low")},
      {blkPath = "graphics/shadowsQuality", val = (val == "HighQuality" ? "high" : "low")},
      {blkPath = "graphics/effectsShadows", val = (val == "HighQuality" ? true : false)},
      {blkPath = "graphics/dropletsOnScreen", val = (val == "HighQuality")},
      {blkPath = "graphics/scopeImageQuality", val = (val == "HighQuality" ? 1 : 0)},
      {blkPath = "video/vsync_tearing_tolerance_percents", val = (val == "HighFPS" ? 35 : 10)},
      {blkPath = "video/frameSkip", val = ((val == "HighFPS" || platform.is_ps5) ? 0 : 1)},
      {blkPath = "graphics/shouldRenderCokpitPrepass", val = (val == "HighQuality")},
      {blkPath = "graphics/skiesQuality", val = (platform.is_ps4_simple ? "low" : (val == "HighFPS" ? "medium" : "high"))}
    ]
  }
}

local optSafeArea = {
  name = ::loc("options/safeArea")
  widgetCtor = optionCombo
  tab = "Graphics"
  isAvailable = safeAreaCanChangeInOptions
  blkPath = safeAreaBlkPath
  var = safeAreaAmount
  setValue = safeAreaSetAmount
  defVal = 1.0
  available = safeAreaList
  valToString = @(s) $"{s*100}%"
  isEqual = defCmp
}

const defVideoMode = "fullscreen"
local originalValVideoMode = get_setting_by_blk_path("video/mode") ?? defVideoMode
local videoModeVar = Watched(originalValVideoMode)

local optVideoMode = {
  name = ::loc("options/mode")
  widgetCtor = optionCombo
  tab = "Graphics"
  blkPath = "video/mode"
  isAvailable = @() platform.is_pc
  defVal = defVideoMode
  available = platform.is_windows ? ["windowed", "fullscreenwindowed", "fullscreen"] : ["windowed", "fullscreen"]
  originalVal = originalValVideoMode
  var = videoModeVar
  restart = !platform.is_windows
  valToString = @(s) ::loc($"options/mode_{s}")
  isEqual = defCmp
}

local optMonitorSelection = {
  name = ::loc("options/monitor", "Monitor")
  widgetCtor = mkDisableableCtor(
    ::Computed(@() videoModeVar.value == "windowed" ? ::loc("options/auto") : null),
    optionCombo)
  tab = "Graphics"
  blkPath = "video/monitor"
  isAvailable = @() platform.is_pc
  defVal = availableMonitors.current
  available = availableMonitors.list
  originalVal = availableMonitors.current
  var = monitorValue
  valToString = @(v) (v == "auto") ? ::loc("options/auto") : get_friendly_monitor_name(v)
  isEqual = defCmp
}

videoModeVar.subscribe(function(val){
  if (["fullscreenwindowed", "fullscreen"].indexof(val)!=null)
    resolutionValue("auto")
  else
    monitorValue("auto")
})

local normalize_res_string = @(res) typeof res == "string" ? res.replace(" ", "") : res

local optResolution = {
  name = ::loc("options/resolution")
  widgetCtor = optionCombo
  tab = "Graphics"
  originalVal = resolutionValue
  blkPath = "video/resolution"
  isAvailable = @() platform.is_pc
  var = resolutionValue
  defVal = resolutionValue
  available = resolutionList
  restart = !(platform.is_windows || platform.is_xboxone)
  valToString = @(v) (v == "auto") ? ::loc("options/auto") : "{0} x {1}".subst(v[0], v[1])
  isEqual = function(a, b) {
    if (typeof a == "string" || typeof b == "string")
      return normalize_res_string(a) == normalize_res_string(b)
    return a[0]==b[0] && a[1]==b[1]
  }
  convertForBlk = resolutionToString
}

local optDlss = {
  name = ::loc("options/DLSS", "NVIDIA DLSS")
  tab = "Graphics"
  widgetCtor = mkDisableableCtor(
    ::Computed(@() dlssNotAllowLocId.value == null ? null : "{0} ({1})".subst(::loc("option/off"), ::loc(dlssNotAllowLocId.value))),
    optionCombo)
  isAvailable = @() platform.is_pc
  blkPath = DLSS_BLK_PATH
  defVal = DLSS_OFF
  var = dlssValue
  setValue = dlssSetValue
  available = dlssAvailable
  valToString = @(v) ::loc(dlssToString[v])
}

local optVsync = {
  name = ::loc("options/vsync")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionCheckBox
  restart = !platform.is_windows
  blkPath = "video/vsync"
  defVal = false
}
local optLatency = {
  name = ::loc("options/latency", "NVIDIA Reflex Low Latency")
  tab = "Graphics"
  widgetCtor = mkDisableableCtor(
    ::Computed(@() lowLatencySupported.value ? null : "{0} ({1})".subst(::loc("option/off"), ::loc("option/unavailable"))),
    optionCombo)
  isAvailable = @() platform.is_pc && DBGLEVEL > 0
  blkPath = LOW_LATENCY_BLK_PATH
  defVal = LOW_LATENCY_OFF
  var = lowLatencyValue
  setValue = lowLatencySetValue
  available = lowLatencyAvailable
  valToString = @(v) ::loc(lowLatencyToString[v])
}
local optShadowsQuality = {
  name = ::loc("options/shadowsQuality", "Shadow Quality")
  widgetCtor = optionCombo
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  blkPath = "graphics/shadowsQuality"
  defVal = "low"
  available = DBGLEVEL > 0 ? [ "low", "medium", "high", "ultra" ] : [ "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
}
local optEffectsShadows = {
  name = ::loc("options/effectsShadows", "Shadows from Effects")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionCheckBox
  blkPath = "graphics/effectsShadows"
  defVal = true
  restart = false
}
local optGiQuality = {
  name = ::loc("options/giQuality", "Global Illumination Quality")
  widgetCtor = optionCombo
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  blkPath = "graphics/giQuality"
  defVal = get_setting_by_blk_path("maxGIByDefault") ? "medium" : "minimum"
  available = [ "minimum", "low", "medium" ]
  restart = false
  valToString = loc_opt
  isEqual = @(a, b) get_setting_by_blk_path("graphics/giQuality")!=null ? a == b : false
}

local optSkiesQuality = {
  name = ::loc("options/skiesQuality", "Skies quality")
  widgetCtor = optionCombo
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  blkPath = "graphics/skiesQuality"
  defVal = "medium"
  available = [ "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
}

local optSsaoQuality = {
  name = ::loc("options/ssaoQuality", "Ambient Occlusion Quality")
  widgetCtor = optionCombo
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  blkPath = "graphics/aoQuality"
  available = [ "low", "medium", "high" ]
  valToString = loc_opt
  defVal = "medium"
  restart = false
  isEqual = defCmp
}

local optObjectsDistanceMul = {
  name = ::loc("options/objectsDistanceMul")
  widgetCtor = optionSlider
  isAvailable = @() platform.is_pc && DBGLEVEL != 0
  tab = "Graphics"
  blkPath = "graphics/objectsDistanceMul"
  defVal = 1.0
  min = 0.0 max = 1.5 unit = 0.05 pageScroll = 0.05
  restart = false
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/rendinstDistMul", val = val},
      {blkPath = "graphics/riExtraMulScale", val = val}
    ]
  }
}

local optGroundDisplacementQuality = {
  name = ::loc("options/groundDisplacementQuality", "Ground Displacement Quality")
  widgetCtor = optionCombo
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  blkPath = "graphics/groundDisplacementQuality"
  defVal = 1
  available = [ 0, 1, 2 ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
}

local optGroundDeformations = {
  name = ::loc("options/groundDeformations", "Dynamic Ground Deformations")
  widgetCtor = optionCombo
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  blkPath = "graphics/groundDeformations"
  defVal = "medium"
  available = [ "off", "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
}

local optImpostor = {
  name = ::loc("options/impostor", "Impostor quality")
  widgetCtor = optionCombo
  isAvailable = @() platform.is_pc && DBGLEVEL != 0
  tab = "Graphics"
  blkPath = "graphics/impostor"
  defVal = 0
  available = [ 0, 1, 2 ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
}

local optTaaQuality = {
  name = ::loc("options/taaQuality", "Antialiasing quality")
  isAvailable = @() platform.is_pc
  widgetCtor = mkDisableableCtor(::Computed(@() dlssValue.value == DLSS_OFF ? null : ::loc("option/off")),
    optionCombo)
  tab = "Graphics"
  blkPath = "graphics/taaQuality"
  defVal = 1
  available = [ 0, 1, 2]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
}

local optTaaMipBias = {
  name = ::loc("options/taa_mip_bias", "Enhanced texture filtering")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionSlider
  blkPath = "graphics/taa_mip_bias"
  defVal = -0.5
  min = 0 max = -1.2 unit = 0.05 pageScroll = 0.05
  restart = false
}

local optGammaCorrection = {
  name = ::loc("options/gamma_correction", "Gamma correction")
  tab = "Graphics"
  isAvailable = @() (platform.is_pc && videoModeVar.value == "fullscreen") || platform.is_sony || platform.is_xboxone || platform.is_xbox_scarlett
  widgetCtor = optionSlider
  blkPath = "graphics/gamma_correction"
  var = gammaCorrectionSave.watch
  setValue = gammaCorrectionSave.setValue
  defVal = 1
  min = 0.5 max = 1.5 unit = 0.05 pageScroll = 0.05
  restart = false
}

local optTexQuality = {
  name = ::loc("options/texQuality")
  widgetCtor = optionCombo
  isAvailable = @() platform.is_pc
  tab = "Graphics"
  blkPath = "graphics/texquality"
  defVal = "high"
  available = ["low", "medium", "high"]
  restart = true
  valToString = loc_opt
  isEqual = defCmp
  tooltipText = ::loc("guiHints/texQuality")
}

local optAnisotropy = {
  name = ::loc("options/anisotropy")
  widgetCtor = optionCombo
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  blkPath = "graphics/anisotropy"
  defVal = 2
  available = [1, 2, 4, 8, 16]
  restart = true
  valToString = @(v) (v==1) ? ::loc("option/off") : $"{v}X"
  isEqual = defCmp
}

local optPnTriangulation = {
  name = ::loc("options/pnTriangulation")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionCheckBox
  blkPath = "graphics/pnTriangulation"
  defVal = false
  restart = false
}

local optIndoorProbes = {
  name = ::loc("options/indoorProbes")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionCheckBox
  restart = !platform.is_windows
  blkPath = "graphics/IndoorProbes"
  defVal = true
}

local optOnlyonlyHighResFx = {
  name = ::loc("options/onlyHighResFx")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionCheckBox
  blkPath = "graphics/onlyHighResFx"
  defVal = true
  restart = false
}

local optDropletsOnScreen = {
  name = ::loc("options/dropletsOnScreen")
  tab = "Graphics"
  isAvailable = @() platform.is_pc || platform.is_nswitch
  widgetCtor = optionCheckBox
  blkPath = "graphics/dropletsOnScreen"
  defVal = false
  restart = false
}

local optVoxelReflections = {
  name = ::loc("options/voxelReflections")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionCheckBox
  blkPath = "graphics/voxelReflections"
  defVal = false
  restart = false
}

local optScopeImageQuality = {
  name = ::loc("graphics/scopeImageQuality", "Scope image quality")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionCombo
  blkPath = "graphics/scopeImageQuality"
  defVal = 0
  available = [0, 1, 2]
  valToString = loc_opt
  restart = false
  isEqual = defCmp
}

local optJpegShots = {
  name = ::loc("options/jpegShots")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = optionCheckBox
  blkPath = "screenshots/saveAsJpeg"
  defVal = false
  restart = false
}

local optRenderingResolutionScale = {
  name = ::loc("options/rendering_resolution_scale", "Rendering Resolution Scale")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = mkDisableableCtor(::Computed(@() dlssValue.value == DLSS_OFF ? null : "100%"),
    optionPercentTextSliderCtor)
  blkPath = "video/renderingResolutionScale"
  defVal = 100
  min = 50 max = 100 unit = 5.0/50.0 pageScroll = 5.0/50.0
  restart = false
}

local optTemporalUpsamplingRatio = {
  name = ::loc("options/temporal_upsampling_ratio", "Temporal Upsampling Ratio")
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  widgetCtor = mkDisableableCtor(::Computed(@() dlssValue.value == DLSS_OFF ? null : "100%"),
    optionPercentTextSliderCtor)
  blkPath = "video/temporalUpsamplingRatio"
  defVal = 100
  min = 50 max = 100 unit = 5.0/50.0 pageScroll = 5.0/50.0
  restart = false
}


return {
  optInBattleGraphicsPreset = optInBattleGraphicsPreset
  optGraphicsPreset = optGraphicsPreset
  optResolution = optResolution
  optSafeArea = optSafeArea
  optVideoMode = optVideoMode
  optMonitorSelection = optMonitorSelection
  optVsync = optVsync
  optLatency = optLatency
  optShadowsQuality = optShadowsQuality
  optEffectsShadows = optEffectsShadows
  optGiQuality = optGiQuality
  optSkiesQuality = optSkiesQuality
  optSsaoQuality = optSsaoQuality
  optObjectsDistanceMul = optObjectsDistanceMul
  optGroundDisplacementQuality = optGroundDisplacementQuality
  optGroundDeformations = optGroundDeformations
  optImpostor = optImpostor
  optTaaQuality = optTaaQuality
  optTaaMipBias = optTaaMipBias
  optGammaCorrection = optGammaCorrection
  optTexQuality = optTexQuality
  optAnisotropy = optAnisotropy
  optPnTriangulation = optPnTriangulation
  optIndoorProbes = optIndoorProbes
  optOnlyonlyHighResFx = optOnlyonlyHighResFx
  optDropletsOnScreen = optDropletsOnScreen
  optVoxelReflections = optVoxelReflections
  optScopeImageQuality = optScopeImageQuality
  optJpegShots = optJpegShots
  optRenderingResolutionScale = optRenderingResolutionScale
  optDlss = optDlss
  optTemporalUpsamplingRatio = optTemporalUpsamplingRatio

  renderOptions = [
    optInBattleGraphicsPreset,
    optGraphicsPreset,
    optResolution,
    optVideoMode,
    optMonitorSelection,
    optDlss,
    optRenderingResolutionScale,
    optTemporalUpsamplingRatio,
    optTaaQuality,
    optSafeArea,
    optVsync,
    optLatency,
    optShadowsQuality,
    optEffectsShadows,
    optGiQuality,
    optSkiesQuality,
    optSsaoQuality,
    optObjectsDistanceMul,
    optGroundDisplacementQuality,
    optGroundDeformations,
    optImpostor,
    optTaaMipBias,
    optGammaCorrection,
    optTexQuality,
    optAnisotropy,
    optPnTriangulation,
    optIndoorProbes,
    optOnlyonlyHighResFx,
    optDropletsOnScreen,
    optVoxelReflections,
    optScopeImageQuality,
    optJpegShots,
  ]
  availableGraphicPresets = availableGraphicPresets
  forceGraphicPreset = forceGraphicPreset
}
 