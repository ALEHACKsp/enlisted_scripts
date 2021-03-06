local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")
local {teammatesAliveNum} = require("ui/hud/state/human_teammates.nut")
local remap_nick = require("globals/remap_nick.nut")
local {watchedHeroPlayerEid} = require("ui/hud/state/hero_state_es.nut")
local {localPlayerSpecTarget} = require("ui/hud/state/local_player.nut")

local isSpectator = ::Computed(@() localPlayerSpecTarget.value != INVALID_ENTITY_ID)//::Computed(@() watchedHeroEid.value != controlledHeroEid.value)
local spectatingPlayerName = ::Computed(@() remap_nick(::ecs.get_comp_val(watchedHeroPlayerEid.value, "name", null)))

local hasSpectatorKeys = ::Computed(@() isSpectator.value
  && showPlayerHuds.value
  && teammatesAliveNum.value > 1)

return {
  isSpectator = isSpectator
  spectatingPlayerName = spectatingPlayerName
  localPlayerSpecTarget = localPlayerSpecTarget
  hasSpectatorKeys = hasSpectatorKeys
} 