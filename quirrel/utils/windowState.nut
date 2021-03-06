local dagor_window = require("dagor.window")
local steam = require_optional("steam")

local windowActive = persist("windowActive", @() Watched(true))
local steamOverlayActive = persist("steamOverlayActive", @() Watched(false))

dagor_window.set_window_activation_handler(function(active) {
  windowActive.update(active)
})

if (steam) {
  steam.set_overlay_activation_handler(
    @(active) steamOverlayActive.update(active)
  )
}

return {
  windowActive = windowActive
  steamOverlayActive = steamOverlayActive
}
 