local { get_setting_by_blk_path } = require("settings")
local { resolutionValue } = require("resolution_state.nut")
local { get_dlss_state, is_dlss_quality_available_at_resolution } = require("videomode")

const DLSS_BLK_PATH = "video/dlssQuality"
const DLSS_OFF = -1
const DLSS_PERFORMANCE = 0
const DLSS_BALANCED = 1
const DLSS_QUALITY = 2
const DLSS_ULTRA_PERFORMANCE = 3
const DLSS_ULTRA_QUALITY = 4

// Values match with enum class DlssState in dag_drv3dConsts.h
const NOT_IMPLEMENTED = 0
const NOT_CHECKED = 1
const NGX_INIT_ERROR_NO_APP_ID = 2
const NGX_INIT_ERROR_UNKNOWN = 3
const NOT_SUPPORTED_OUTDATED_VGA_DRIVER = 4
const NOT_SUPPORTED_INCOMPATIBLE_HARDWARE = 5
const NOT_SUPPORTED_32BIT = 6
const SUPPORTED = 7
const READY = 8

local dlssToString = {
  [DLSS_OFF] = "option/off",
  [DLSS_PERFORMANCE] = "option/performance",
  [DLSS_BALANCED] = "option/balanced",
  [DLSS_QUALITY]  = "option/quality",
  [DLSS_ULTRA_PERFORMANCE]  = "option/ultraperformance",
  [DLSS_ULTRA_QUALITY]  = "option/ultraquality",
}

local dlssSupportLocId = {
  // These should not happen in production, but let's disable DLSS option in these cases. Also, these strings are not localized, but it's
  // probably better to display these as opposed to nothing.
  [NOT_IMPLEMENTED] = "NOT_IMPLEMENTED",
  [NOT_CHECKED] = "NOT_CHECKED",
  [NGX_INIT_ERROR_NO_APP_ID] = "NGX_INIT_ERROR_NO_APP_ID",
  [NGX_INIT_ERROR_UNKNOWN] = "NGX_INIT_ERROR_UNKNOWN",
  // These are the cases that can happen in production and we want to feedback users about why is DLSS unavailable
  [NOT_SUPPORTED_OUTDATED_VGA_DRIVER] = "dlss/updateDrivers",
  [NOT_SUPPORTED_INCOMPATIBLE_HARDWARE] = "dlss/incompatibleHardware",
  [NOT_SUPPORTED_32BIT] = "dlss/notSupported32bit"
}
local curDlssSupportStateLocId = dlssSupportLocId?[get_dlss_state()]
local dlssNotAllowLocId = ::Computed(@() curDlssSupportStateLocId)

local dlssAllQualityModes = [DLSS_OFF, DLSS_ULTRA_PERFORMANCE, DLSS_PERFORMANCE, DLSS_BALANCED, DLSS_QUALITY, DLSS_ULTRA_QUALITY]

local dlssAvailable = ::Computed(function() {
  local dlssState = get_dlss_state()
  if (dlssState != SUPPORTED && dlssState != READY)
    return [DLSS_OFF] // it's not allowed to call is_dlss_quality_available_at_resolution  when DLSS is not supported
  local res = resolutionValue.value
  if (::type(res) != "array")
    res = [0, 0]
  return dlssAllQualityModes.filter(@(q) q == DLSS_OFF || (is_dlss_quality_available_at_resolution(res[0], res[1], q)))
})

local dlssValueChosen = ::Watched(get_setting_by_blk_path(DLSS_BLK_PATH))

local dlssSetValue = @(v) dlssValueChosen(v)

local dlssValue = ::Computed(@() dlssNotAllowLocId.value != null ? DLSS_OFF
  : dlssAvailable.value.indexof(dlssValueChosen.value) != null ? dlssValueChosen.value
  : DLSS_OFF)

return {
  DLSS_BLK_PATH = DLSS_BLK_PATH
  DLSS_OFF = DLSS_OFF
  dlssAvailable = dlssAvailable
  dlssValue = dlssValue
  dlssSetValue = dlssSetValue
  dlssToString = dlssToString
  dlssNotAllowLocId = dlssNotAllowLocId
} 