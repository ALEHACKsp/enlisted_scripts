local {isEqual} = require("std/underscore.nut")
local blk2str = require("std/blk2str.nut")
local DataBlock = require("DataBlock") //for debug purposes
local {TMatrix, Point2, Point3, Point4, Color3, Color4, IPoint2, IPoint3} = require("dagor.math")
local logLib = require("std/log.nut")
local {tostring_r} = require("std/string.nut")
::loc <- require("dagor.localize").loc

local tostringfuncTbl = [
  {
    compare = @(val) val instanceof ::Watched
    tostring = @(val) "::Watched: {0}".subst(tostring_r(val.value,{maxdeeplevel = 3, splitlines=false}))
  }
  {
    compare = @(val) val instanceof Point3
    tostring = function(val){
      return $"Point3: {val.x}, {val.y}, {val.z}"
    }
  }
  {
    compare = @(val) val instanceof Point4
    tostring = function(val){
      return $"Point4: {val.x}, {val.y}, {val.z}, {val.w}"
    }
  }
  {
    compare = @(val) val instanceof Point2
    tostring = function(val){
      return $"Point2: {val.x}, {val.y}"
    }
  }
  {
    compare = @(val) val instanceof TMatrix
    tostring = function(val){
      local o = []
      for (local i=0; i<4;i++)
        o.append("[{x}, {y}, {z}]".subst({x=val[i].x,y=val[i].y, z=val[i].z}))
      o = " ".join(o)
      return "TMatrix: [{0}]".subst(o)
    }
  }
  {
    compare = @(val) val instanceof DataBlock
    tostring = blk2str
  }
]
local customIsEqual = {}
local specifiedIsEqual = @(val1, val2, customIsEqualTbl = customIsEqual) isEqual(val1, val2, customIsEqualTbl)

customIsEqual.__update({
  [DataBlock] = function(val1, val2) {
    if (val1.paramCount() != val2.paramCount() || val1.blockCount() != val2.blockCount())
      return false

    for (local i = 0; i < val1.paramCount(); i++)
      if (val1.getParamName(i) != val2.getParamName(i) || ! isEqual(val1.getParamValue(i), val2.getParamValue(i)))
        return false
    for (local i = 0; i < val1.blockCount(); i++) {
      local b1 = val1.getBlock(i)
      local b2 = val2.getBlock(i)
      if (b1.getBlockName() != b2.getBlockName() || !specifiedIsEqual(b1, b2))
        return false
    }
    return true
  },
  [IPoint2] = @(val1, val2) val1.x == val2.x && val1.y == val2.y,
  [IPoint3] = @(val1, val2) val1.x == val2.x && val1.y == val2.y && val1.z == val2.z,
  [Point2] = @(val1, val2) val1.x == val2.x && val1.y == val2.y,
  [Point3] = @(val1, val2) val1.x == val2.x && val1.y == val2.y && val1.z == val2.z,
  [Point4] = @(val1, val2) val1.x == val2.x && val1.y == val2.y && val1.z == val2.z && val1.w == val2.w,
  [Color4] = @(val1, val2) val1.r == val2.r && val1.g == val2.g && val1.b == val2.b && val1.a == val2.a,
  [Color3] = @(val1, val2) val1.r == val2.r && val1.g == val2.g && val1.b == val2.b,
  [TMatrix] = function(val1, val2) {
    for (local i = 0; i < 4; i++)
      if (!isEqual(val1[i], val2[i]))
        return false
    return true
  }
})
::isEqual <- specifiedIsEqual   //warning disable: -ident-hides-ident
local log = logLib(tostringfuncTbl)
::debugTableData <- log.debugTableData //used for sq debugger
::dlog <- log.dlog  //warning disable: -dlog-warn
::log_for_user <- log.dlog //warning disable: -dlog-warn
::log <- log  //warning disable: -ident-hides-ident
::dlogsplit <- log.dlogsplit
::vlog <- log.vlog
::console_print <- log.console_print
::wlog <- function wlog(watched, prefix = "", logger = ::log) {
  //intentionally requires dlog for visual log, to be sure that no one occassionally left dlog in code
  if (::type(prefix) == "function") {
    logger = prefix
    prefix = ""
  }
  if (::type(watched) != "array")
    watched = [watched]
  prefix = prefix!="" ? $"{prefix}" : null
  if (prefix != null) {
    foreach (w in watched) {
      logger(prefix, w.value)
      w.subscribe(@(v) logger(prefix, v))
    }
  }
  else {
    foreach (w in watched){
      logger(w.value)
      w.subscribe(logger)
    }
  }
}
::wdlog <- @(watched, prefix = "") ::wlog(watched, prefix, ::dlog) //disable: -dlog-warn

global enum Layers {
  Default
  Upper
  ComboPopup
  MsgBox
  Blocker
  Tooltip
  Inspector
}
 