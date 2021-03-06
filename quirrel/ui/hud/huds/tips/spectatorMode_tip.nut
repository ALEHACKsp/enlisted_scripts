local {isSpectator, spectatingPlayerName} = require("ui/hud/state/spectator_state.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")

local spectatingName = ::Computed(@() (isSpectator.value
  && showPlayerHuds.value
  && spectatingPlayerName.value != null) ?  spectatingPlayerName.value : null)

local spectatorMode_tip = @() {
  rendObj = ROBJ_DTEXT
  text = spectatingName.value != null
    ? ::loc("hud/spectator_target", {user = spectatingName.value})
    : null
  watch = spectatingName
  font = Fonts.big_text
  margin = ::hdpx(20)
}

return spectatorMode_tip
 