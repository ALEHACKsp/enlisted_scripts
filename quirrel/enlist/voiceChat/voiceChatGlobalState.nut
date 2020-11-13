local sharedWatched = require("globals/sharedWatched.nut")
local platform = require("globals/platform.nut")

return {
  voiceChatEnabled = sharedWatched("voiceChatEnabled", @() platform.is_pc || platform.is_sony)
}
 