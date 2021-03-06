local {get_setting_by_blk_path} = require("settings")
local {getOnlineSaveData, slider, mkSliderWithText} = require("options_lib.nut")

local setCameraFovQuery = ::ecs.SqQuery("setCameraFovQuery", {comps_rw = [ ["fovSettings", ::ecs.TYPE_FLOAT] ], comps_ro = [ ["fovLimits", ::ecs.TYPE_POINT2] ]})

local function optionCameraFovTextSliderCtor(opt, group, xmbNode) {
  local optSetValue = opt.setValue
  local function setValue(val) {
    optSetValue(val)
    setCameraFovQuery.perform(function(eid, comp) {
        comp["fovSettings"] = clamp(val, comp.fovLimits.x, comp.fovLimits.y)
      })
  }
  opt = opt.__merge({setValue = setValue})
  return mkSliderWithText(opt.var, slider.Horiz(opt.var, opt))
}

local function mkCameraFovOption(title, field) {
  local blkPath = "gameplay/camera_fov"
  local { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? 90.0)
  return {
    name = title
    tab = "Game"
    widgetCtor = optionCameraFovTextSliderCtor
    var = watch
    setValue = setValue
    defVal = 90.0
    min = 70.0 max = 90.0 unit = 0.05 pageScroll = 1
    restart = false
    blkPath = blkPath
  }
}

return {
  cameraFovOption = mkCameraFovOption(::loc("gameplay/camera_fov"), "camera_fov")
} 