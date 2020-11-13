local frameUpdateCounter = ::Watched(0)

::gui_scene.setUpdateHandler(function sceneUpdateHandler(dt) {
  frameUpdateCounter(frameUpdateCounter.value+1)
})

return {
  frameUpdateCounter
} 