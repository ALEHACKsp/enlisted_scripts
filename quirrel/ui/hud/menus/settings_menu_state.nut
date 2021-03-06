local { renderOptions } = require("options/render_options.nut")
local { soundOptions } = require("options/sound_options.nut")
local { cameraFovOption } = require("options/camera_fov_option.nut")
local { voiceChatOptions } = require("options/voicechat_options.nut")

local menuTabsOrder = Watched([])
local menuOptions = Watched([])

menuOptions(
  [cameraFovOption]
  .extend(renderOptions)
  .extend(soundOptions)
  .extend(voiceChatOptions)
)

menuTabsOrder([
  {id = "Graphics", text=::loc("options/graphicsParameters")},
  {id = "Sound", text = ::loc("sound")},
  {id = "Game", text = ::loc("options/game")},
  {id = "VoiceChat", text = ::loc("controls/tab/VoiceChat")},
])

return {
  menuOptions = menuOptions
  menuTabsOrder = menuTabsOrder
} 