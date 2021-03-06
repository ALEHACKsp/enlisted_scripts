local dgs_get_settings = require("dagor.system").dgs_get_settings
local platform = require("platform")
local {get_platform_string_id, get_platform_sdk, get_console_model, get_default_lang} = platform

local id = dgs_get_settings().getStr("platform", get_platform_string_id())

local ps4 = null
local PS4_REGION_NAMES = null

return {
  id = id
  is_pc = ["win32", "win64", "macosx", "linux64"].indexof(id) != null
  is_windows = ["win32", "win64"].indexof(id) != null
  is_ps4 = id == "ps4"
  is_ps5 = id == "ps5"
  is_sony = id=="ps4" || id=="ps5"
  is_android = id == "android"
  is_ios = id == "iOS"
  is_mobile = ["iOS", "android"].indexof(id) != null
  is_xbox = ["xboxOne", "xboxScarlett"].indexof(id) != null
  is_xboxone = id == "xboxOne"
  is_xbox_scarlett = id == "xboxScarlett"
  is_nswitch = id == "nswitch"
  is_xboxone_simple = get_console_model()==platform.XBOXONE
  is_xboxone_s = get_console_model()==platform.XBOXONE_S
  is_xboxone_X = get_console_model()==platform.XBOXONE_X
  is_xbox_lockhart = get_console_model()==platform.XBOX_LOCKHART
  is_xbox_anaconda = get_console_model()==platform.XBOX_ANACONDA
  is_ps4_simple = id=="ps4" && get_console_model()==platform.PS4
  is_ps4_pro = id=="ps4" && get_console_model()==platform.PS4_PRO
  is_console = ["ps4", "nswitch", "xboxOne", "xboxScarlett"].indexof(id) != null
  is_gdk = get_platform_sdk() == "gdk"
  is_xdk = get_platform_sdk() == "xdk"

  ps4RegionName = function() {
    if (!is_sony)
      return "no region on this platform"

    if (!ps4) {
      ps4 = require("ps4")
      PS4_REGION_NAMES = {
        [ps4.SCE_REGION_SCEE]  = "scee",
        [ps4.SCE_REGION_SCEA]  = "scea",
        [ps4.SCE_REGION_SCEJ]  = "scej"
      }
    }
    return PS4_REGION_NAMES[ps4.get_region()]
  }

  get_language = @() get_default_lang()
}

 