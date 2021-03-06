local {get_setting_by_blk_path} = require("settings")
local dagor_sys = require("dagor.system")

local config = ::gui_scene.config
config.defaultFont = Fonts.small_text
config.reportNestedWatchedUpdate = (dagor_sys.DBGLEVEL > 0) ? true : get_setting_by_blk_path("debug/reportNestedWatchedUpdate") ?? false
config.kbCursorControl = true
config.gamepadCursorSpeed = 1.85
//::config.gamepadCursorDeadZone - depending on driver deadzon in controls_setup, default is setup in library

config.gamepadCursorNonLin = 0.5
config.gamepadCursorHoverMinMul = 0.07
config.gamepadCursorHoverMaxMul = 0.8
config.gamepadCursorHoverMaxTime = 1.0
//config.defSceneBgColor =Color(10,10,10,160)
//config.gamepadCursorControl = true
//config.defaultFont = Fonts.medium_text

//config.clickRumbleLoFreq = 0
//config.clickRumbleHiFreq = 0.7
config.clickRumbleLoFreq = 0
config.clickRumbleHiFreq = 0.8
config.clickRumbleDuration = 0.04
 