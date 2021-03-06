local { curSectionDetails } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { addScene, removeScene } = require("enlist/navState.nut")

local scenes = Watched([])

local curCamera = ::Computed(@() (scenes.value.len() ? scenes.value.top()?.camera : null)
  ?? curSectionDetails.value?.camera
  ?? "soldiers")

local function sceneWithCameraAdd(content, camera) {
  if (scenes.value.findindex(@(c) c.content == content) != null)
    return
  addScene(content)
  scenes(@(s) s.append({ content = content, camera = camera }))
}

local function sceneWithCameraRemove(content) {
  local idx = scenes.value.findindex(@(c) c.content == content)
  if (idx == null)
    return
  removeScene(content)
  scenes(@(s) s.remove(idx))
}

return {
  curCamera,  sceneWithCameraAdd, sceneWithCameraRemove
} 