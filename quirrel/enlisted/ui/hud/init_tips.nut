local tips = require("ui/hud/state/tips.nut")
local reload_tip              = require("ui/hud/huds/tips/reload_tip.nut")
local medkit_tip              = require("ui/hud/huds/tips/medkit_tip.nut")
local medkit_usage            = require("ui/hud/huds/tips/medkit_usage.nut")
local vehicle_under_water     = require("ui/hud/huds/tips/vehicle_underwater.nut")
local downed_tip              = require("ui/hud/huds/tips/downed_tip.nut")
local burning_tip             = require("ui/hud/huds/tips/burning_tip.nut")
local hold_breath_tip         = require("ui/hud/huds/tips/hold_breath_tip.nut")
local prevent_reloading_tip   = require("ui/hud/huds/tips/prevent_reloading_tip.nut")
local mark_enemy_tip          = require("huds/tips/mark_enemy_tip.nut")
local mortar_aiming_tip       = require("ui/hud/huds/tips/mortar_aiming_tip.nut")

tips([
  {
    pos = [-sh(25), sh(25)]
    children = reload_tip
  }
  {
    pos = [sh(30), sh(25)]
    gap = hdpx(2)
    children = [mark_enemy_tip, hold_breath_tip, medkit_tip, prevent_reloading_tip, mortar_aiming_tip]
  }
  { children = medkit_usage }
  { children = vehicle_under_water }
  {
    pos = [sh(0), sh(5)]
    children = [downed_tip, burning_tip]
  }
]) 