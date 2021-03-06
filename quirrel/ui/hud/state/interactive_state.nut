local interactiveElements = persist("interactiveElements", @() Watched({}))

local function addInteractiveElement(id) {
  if (!(id in interactiveElements.value))
    interactiveElements[id] <- true
}

local function removeInteractiveElement(id) {
  if (id in interactiveElements.value)
    delete interactiveElements[id]
}

local function setInteractiveElement(id, val){
  if (val)
    addInteractiveElement(id)
  else
    removeInteractiveElement(id)
}

local function switchInteractiveElement(id) {
  interactiveElements.update(function(v) {
    if (id in v)
      delete v[id]
    else
      v[id] <- true
  })
}

return {
  interactiveElements = interactiveElements
  removeInteractiveElement = removeInteractiveElement
  addInteractiveElement = addInteractiveElement
  switchInteractiveElement = switchInteractiveElement
  setInteractiveElement = setInteractiveElement
  hudIsInteractive = ::Computed(@() interactiveElements.value.len() > 0)
}

 