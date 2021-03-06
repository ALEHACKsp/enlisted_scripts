local platform = require("globals/platform.nut")
local {get_local_unixtime, unixtime_to_local_timetbl} = require("dagor.time")
local {version} = require("globals/appInfo.nut")
local {horPadding} = require("globals/safeArea.nut")
local remap_nick = require("globals/remap_nick.nut")
local {localPlayerName} = require("ui/hud/state/local_player.nut")

local playerName = ::Computed(@() remap_nick(localPlayerName.value))

local mkText = @(text, params = {}){
  rendObj = ROBJ_DTEXT
  text = text
  color =Color(24,24,24,8)
  font = Fonts.small_text
  fontFx = FFT_GLOW, fontFxColor = Color(0,0,0,60), fontFxFactor = min(hdpx(64), 64), fontFxOffsY=hdpx(0.9)
}.__update(params)
local brColor = Color(40,40,40,10)

local mkNickname = @(pos=null) @() mkText(playerName.value, {
  watch = playerName
  pos = pos
})

local monthToStr = {
  [0] = "Jan",
  [1] = "Feb",
  [2] = "Mar",
  [3] = "Apr",
  [4] = "May",
  [5] = "Jun",
  [6] = "Jul",
  [7] = "Aug",
  [8] = "Sep",
  [9] = "Oct",
  [10] = "Nov",
  [11] = "Dec"
}

local function mkTime(){
  local {day, month, year} = unixtime_to_local_timetbl(get_local_unixtime())
  return $"{day} {monthToStr?[month] ?? month} {year}"
}

local date = mkText(mkTime(), {color = brColor})
local alpha = mkText(platform.is_xbox ? "Game Preview" : "Beta version", {color = brColor, font = Fonts.big_text})
local rightUpCorner = {
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  hplace = ALIGN_RIGHT
  margin = [sh(0.5), sw(2)]
  children = [
    alpha,
    date,
    mkNickname()
  ]
}

local versionUI = mkText(version.value, {font = Fonts.small_text, margin = [sh(0.5), sw(1)]})
local waterMarks = @() {
  watch = horPadding
  size = flex()
  children = [
    versionUI
    rightUpCorner
  ]
  padding = [0, horPadding.value]
}
return { waterMarks } 