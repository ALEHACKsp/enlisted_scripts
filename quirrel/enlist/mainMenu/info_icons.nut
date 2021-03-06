local cursors = require("ui/style/cursors.nut")
local picSz = sh(3.3)
local {hudIsInteractive} = require("ui/hud/state/interactive_state.nut")
local platform = require("globals/platform.nut")
local matchingCli = require("enlist/matchingClient.nut")

local isSavingData = ::Watched(false)

local function pic(name) {
  return ::Picture("ui/skin#info/{0}.svg:{1}:{1}:K".subst(name, picSz.tointeger()))
}

local mkIcon = @(iconname, tiptext, isVisibleWatch) @() {
    watch = [isVisibleWatch, hudIsInteractive]
    key = iconname
    children =  isVisibleWatch.value
                ? {
                    size = [picSz, picSz]
                    image = pic(iconname)
                    behavior = hudIsInteractive.value ? Behaviors.Button : null
                    onHover = @(on) cursors.tooltip.state(on ? ::loc(tiptext, "") : null)
                    rendObj = ROBJ_IMAGE
                    animations = [{ prop = AnimProp.opacity, from = 0.1, to = 1.0,
                                    duration = 1, play = true, loop = true, easing = Blink}]
                    color = Color(200, 50, 0, 160)
                  }
                : null
}

if (platform.is_nswitch) {
  local nswitchEvents = require("nswitch.events")
  nswitchEvents.setOnSavedataUsageCallback(function() {
    isSavingData(true)
    ::gui_scene.setTimeout(1.5, @() isSavingData(false) )
  })
}

local noServerStatus = mkIcon("no_server", "hud/no_server", matchingCli.connecting)
local saveDataStatus = mkIcon("save_data", "hud/save_data", isSavingData)



return {
  //NetworkStatus = mkIcon("no_network", "hud/no_network")
  noServerStatus
  saveDataStatus
}
 