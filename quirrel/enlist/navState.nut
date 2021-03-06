local scenesList =  Watched([])

return {
  scenesList,
  function addScene(component) {
    local idx = scenesList.value.indexof(component)
    if (idx != null)
      return
    scenesList.update(@(value) value.append(component))
  }
  function removeScene(component) {
    local idx = scenesList.value.indexof(component)
    if (idx == null)
      return
    scenesList.update(@(value) value.remove(idx))
  }
}
 