  
     
                                                                
                                      
  


local {dtext} = require("daRg/components/text.nut")
local {round_by_value} = require("std/math.nut")
local {secondsToString} = require("utils/time.nut")

//local showRoC = Watched(false) //export these settings outside and use it here, as well as measure units

local defCaption = @(obj) ::loc(obj.locId)

local defTransform = @(obj, val) round_by_value(val, 1)

/*
local function rocTransform(val) {
  local ret = round_by_value(val, 0.1).tostring()
  if (ret.indexof(".")==null)
    return $"{ret}.0"
  return ret
}
*/

local transformPercentsFunc =  @(obj, val) round_by_value(val*100, 1)

//local transformPercentsWithAutoFlagFunc = @(obj, val) obj.watchAuto.value ? ::loc("AUTO") : transformPercentsFunc(obj, val)

local transformTimeFunc = @(obj, val) secondsToString(val)

local transformBoolFunc =@(obj, val) obj.boolValues[val ? 1 : 0]

local transformEnumFunc = @(obj, val) obj.enumValues[val]

local defStyle = {fontFx = FFT_GLOW, fontFxColor = Color(0,0,0,50), fontFxFactor = 64, fontFxOffsY=hdpx(0.9)}
local hText = ::calc_comp_size(dtext("THROTTLE:   100%"))

local function mkIndicator(obj){
  local captionFunc = obj?.captionFunc ?? defCaption
  local transformFunc = obj?.transformFunc ?? defTransform
  local watch = obj.watch
  local watchShow = obj?.watchShow
  local watches = obj.values().filter(@(v) v instanceof Watched)
  return function() {
    return {
      children = watch.value != null && (watchShow == null || watchShow?.value) ? [
        {children = [dtext(captionFunc(obj), defStyle), dtext(":",defStyle)], flow = FLOW_HORIZONTAL}
        dtext(transformFunc(obj, watch.value).tostring(), {hplace = ALIGN_RIGHT}.__update(defStyle))
      ] : null
      size = watch.value!=null ? hText : null
      watch = watches
    }
  }
}

local function mkExistIndicator(obj){
  local watch = obj.watch
  local locId = obj.locId
  local watches = obj.values().filter(@(v) v instanceof Watched)
  return function() {
    return {
      children = watch.value ? dtext(::loc(locId), defStyle) : null
      size = watch.value!=null ? hText : null
      watch = watches
    }
  }
}

local function mkHide(obj){
  return function() {
    return null
  }
}

local state = [
  // flight parameters
  {comp = "plane_view.tas",           watch = Watched(), locId="TAS",  typ = ::ecs.TYPE_FLOAT, transformFunc = @(obj, val) round_by_value(val*3.6, 1)}
  //{comp = "plane_view.ias",           watch = Watched(), locId="IAS",  typ = ::ecs.TYPE_FLOAT, transformFunc = @(obj, val) round_by_value(val*3.6, 1)}
  {comp = "plane_view.altitude",      watch = Watched(), locId="ALT",  typ = ::ecs.TYPE_FLOAT}
  //{comp = "plane_view.vertical_speed",watch = Watched(), watchShow = showRoC, locId="RoC", typ = ::ecs.TYPE_FLOAT, transformFunc = rocTransform}
  //{comp = "plane_view.heading_deg",   watch = Watched(), locId="HDG",  typ = ::ecs.TYPE_INT  }

  // controls
  {comp = "plane_view.throttle",      watch = Watched(), locId="THR",  typ = ::ecs.TYPE_FLOAT, transformFunc = transformPercentsFunc}
  {comp = "plane_view.has_gear_control", watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.gear_position", watch = Watched(),
    compShow = "plane_view.has_gear_control", watchShow = Watched(false),
    locId="GEAR",  typ = ::ecs.TYPE_BOOL,
    boolValues = ["UP", "DOWN"], transformFunc = transformBoolFunc}
  {comp = "plane_view.has_flaps_control", watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "flaps_position",           watch = Watched(),
    compShow = "plane_view.has_flaps_control", watchShow = Watched(false),
    locId="FLAPS", typ = ::ecs.TYPE_INT,
    enumValues = ["UP", "COMBAT", "TAKEOFF", "LANDING"], transformFunc = transformEnumFunc}
/*
  {comp = "is_parking_brake_on",      watch=Watched(), locId = "PARKING BRAKE", typ = ::ecs.TYPE_BOOL, mkIndicator = mkExistIndicator}
*/
  // fuel
  {comp = "plane_view.fuel_time",  watch = Watched(), locId="FUEL", typ = ::ecs.TYPE_FLOAT, transformFunc = transformTimeFunc, watchShow=Watched(false)}
/*
  // engines + propellers
  {comp = "plane_view.engine_manual_control",  watch=Watched(), locId = "ENGINE CONTROL", typ = ::ecs.TYPE_BOOL, mkIndicator = mkExistIndicator}
  {comp = "plane_view.engine_speed",  watch = Watched(), locId="RPM", typ = ::ecs.TYPE_FLOAT, transformFunc = @(obj, val) round_by_value(val*9.55, 1)}
  {comp = "plane_view.engine_has_pitch_control", watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_pitch_control_auto", watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_pitch_control", watch = Watched(),
    compShow = "plane_view.engine_has_pitch_control", watchShow = Watched(false),
    compAuto = "plane_view.engine_pitch_control_auto", watchAuto = Watched(false),
    locId="PITCH", typ = ::ecs.TYPE_FLOAT,
    transformFunc = transformPercentsWithAutoFlagFunc}
  {comp = "plane_view.engine_has_radiator_control", watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_radiator_control_auto", watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_radiator",      watch = Watched(),
    compShow = "plane_view.engine_has_radiator_control", watchShow = Watched(false),
    compAuto = "plane_view.engine_radiator_control_auto", watchAuto = Watched(false),
    locId="RAD",   typ = ::ecs.TYPE_FLOAT,
    transformFunc = transformPercentsWithAutoFlagFunc}
  {comp = "plane_view.engine_has_oil_radiator_control", watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_oil_radiator_control_auto", watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_oil_radiator",  watch = Watched(),
    compShow = "plane_view.engine_has_oil_radiator_control", watchShow = Watched(false),
    compAuto = "plane_view.engine_oil_radiator_control_auto", watchAuto = Watched(false),
    locId="OIL RAD", typ = ::ecs.TYPE_FLOAT,
    transformFunc = transformPercentsWithAutoFlagFunc}
  {comp = "plane_view.engine_air_cooled",    watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_water_cooled",  watch = Watched(), locId = "", typ = ::ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_water_temperature", watch = Watched(),
    compShow = "plane_view.engine_water_cooled", watchShow = Watched(false),
    locId="WATER", typ = ::ecs.TYPE_FLOAT}
  {comp = "plane_view.engine_head_temperature",  watch = Watched(),
    compShow = "plane_view.engine_air_cooled",   watchShow = Watched(false),
    locId="HEAD",  typ = ::ecs.TYPE_FLOAT}
  {comp = "plane_view.engine_oil_temperature",   watch = Watched(),
    locId="OIL",  typ = ::ecs.TYPE_FLOAT}
  // autopilot
  {comp = "stick_pusher_enabled",  watch=Watched(), locId = "INSTRUCTOR",    typ = ::ecs.TYPE_BOOL, mkIndicator = mkExistIndicator}
  {comp = "flight_angles_enabled", watch=Watched(), locId = "AIM CONTROL",   typ = ::ecs.TYPE_BOOL, mkIndicator = mkExistIndicator}
*/
]

//state.each(@(watch, key) watch.subscribe(@(v) log_for_user(key, v)))

::ecs.register_es("plane_basic_hud_es",
  {
    [["onInit","onChange"]] = function(evt, eid, comp){
      state.each(@(v) v.watch(comp[v.comp]))
      state.each(@(v) v?.watchShow != null && v?.compShow != null ? v.watchShow(comp[v.compShow]) : null)
      state.each(@(v) v?.watchAuto != null && v?.compAuto != null ? v.watchAuto(comp[v.compAuto]) : null)
    }
    function onDestroy(evt, eid, comp){
      state.each(@(v) v.watch(null))
      state.each(@(v) v?.watchShow != null ? v.watchShow(null) : null)
      state.each(@(v) v?.watchAuto != null ? v.watchAuto(null) : null)
    }
  },
  {
    comps_track = state.map(@(obj) [obj.comp, obj.typ, null]),
    comps_rq = ["vehicle", "heroVehicle"]
  }
)

local planeState = state.filter(@(obj) "watch" in obj).reduce(function(memo, obj) {memo[obj.comp.replace("plane_view.", "plane_")] <- obj.watch; return memo;}, {})
return {
  planeState = planeState
  mkExistIndicator = mkExistIndicator //to prevent static analyzer warning

  function planeHud(){
    local children = state.map(@(obj)
      !("watchShow" in obj) || obj?.watchShow.value
        ? (obj?.mkIndicator(obj) ?? mkIndicator(obj))
        : null
    ).filter(@(v) v!=null)

    local watches = state.filter(@(obj) "watchShow" in obj).map(@(obj) obj?.watchShow)
    return {
      flow = FLOW_VERTICAL
      gap = hdpx(3)
      children = children
      watch = watches
    }
  }
}
 