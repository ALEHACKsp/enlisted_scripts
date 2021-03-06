::print("init globals\n")
local dagorMath = require("dagor.math")
local DataBlock = require("DataBlock")

local blk2str = require("std/blk2str.nut")
local log_ = require("std/log.nut")([
  {
    compare = @(val) val instanceof dagorMath.Point3
    tostring = function(val){
      return "Point3: {x}, {y}, {z}".subst({x=val.x, y=val.y, z=val.z})
    }
  }
  {
    compare = @(val) val instanceof dagorMath.Point2
    tostring = function(val){
      return "Point2: {x}, {y}".subst({x=val.x, y=val.y})
    }
  }
  {
    compare = @(val) val instanceof dagorMath.TMatrix
    tostring = function(val){
      local o = " ".join(array(4)
        .map(@(v,i) "[{0}, {1}, {2}]".subst(val[i].x, val[i].y, val[i].z)))
      return "TMatix: [ {0} ]".subst(o)
    }
  }
  {
    compare = @(val) val instanceof DataBlock
    tostring = blk2str
  }
])

::dlog <- log_.dlog //disable: -dlog-warn
::log_for_user <- log_.dlog  //disable: -dlog-warn
::dlogsplit <- log_.dlogsplit
::vlog <- log_.vlog
::log <- log_.log
::debugTableData <- log_.debugTableData

local functools = require("std/functools.nut")
::partial <- functools.partial
::pipe <- functools.pipe
::compose <- functools.compose
::kwarg <- functools.kwarg
::kwpartial <- functools.kwpartial
::curry <- functools.curry
::memoize <- functools.memoize

local global_modules = [
  "globals/ecs.nut"
  "anim.nut"
]
foreach(g in global_modules)
  require(g)
::print("init globals done\n") 