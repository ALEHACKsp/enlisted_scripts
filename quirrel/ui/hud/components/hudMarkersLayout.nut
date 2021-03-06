local {horPadding, verPadding} = require("globals/safeArea.nut")

local function mkViewport(padding){
  return {
    sortOrder = -999
    size = [sw(100) - horPadding.value*2 - padding, sh(100) - verPadding.value*2 - padding]
    data = {
      isViewport = true
    }
  }
}

local function layout(state, ctors, padding){
  local child = mkViewport(padding)
  if (::type(ctors) != "array")
    ctors = [ctors]

  return function() {
    local children = [child]
    foreach(ctor in ctors)
      foreach (eid, info in state.value)
        children.append(ctor(eid, info))
    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = flex()
      children = children
      watch = state
      behavior = Behaviors.Projection
      sortChildren = true
    }
  }
}

local function makeMarkersLayout(stateAndCtors, padding){
  local layers = []
  foreach (state, ctors in stateAndCtors)
    layers.append(layout(state, ctors, padding))

  return @(){
    size = [sw(100), sh(100)]
    children = layers
    watch = [horPadding, verPadding]
  }
}

return {
  makeMarkersLayout = makeMarkersLayout
} 