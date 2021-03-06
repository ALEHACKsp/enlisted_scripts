local timeBase = require("std/time.nut")
local {secondsToTimeFormatString, roundTime} = timeBase

local locTable ={
  seconds =::loc("measureUnits/seconds"),
  days =::loc("measureUnits/days"),
  minutes =::loc("measureUnits/minutes")
  hours =::loc("measureUnits/hours")
}

local locFullTable ={
  seconds =::loc("measureUnits/seconds"),
  days =::loc("measureUnits/full/days"),
  minutes =::loc("measureUnits/full/minutes")
  hours =::loc("measureUnits/full/hours")
}

local secondsToStringLoc = @(time) secondsToTimeFormatString(time).subst(locTable)

local secondsToHoursLoc = @(time) secondsToTimeFormatString(roundTime(time)).subst(locTable)

local secondsToHoursLocFull = @(time) secondsToTimeFormatString(roundTime(time)).subst(locFullTable)
local secondsToString = timeBase.secondsToTimeSimpleString
return timeBase.__merge({
  secondsToString = secondsToString
  secondsToStringLoc = secondsToStringLoc
  secondsToHoursLoc = secondsToHoursLoc
  secondsToHoursLocFull = secondsToHoursLocFull
}) 