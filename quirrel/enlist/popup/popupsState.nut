local POPUP_PARAMS = {
  id = ""
  text = ""
  styleName = ""
  showTime = 10.0
  onClick = null //function() - will be called on popup click
}

const MAX_POPUPS = 3
local popups = Watched([])
local counter = 0 //for popups without id

local function removePopup(id) {
 //id (str) or uid (int)
  local idx = popups.value.findindex(@(p) p.id == id || p.uid == id)
  if (idx != null)
    popups(@(l) l.remove(idx))
}

local function addPopup(config) {
  local uid = counter++
  if (config?.id != null)
    removePopup(config.id)
  else
    config.id <- $"_{uid}"

  if (popups.value.len() >= MAX_POPUPS)
    popups.value.remove(0)

  local popup = POPUP_PARAMS.__merge(config)
  popup.uid <- uid

  popup.click <- function() {
    popup.onClick?()
    removePopup(popup.id)
  }

  popup.visibleIdx <- Watched(-1)
  popup.visibleIdx.subscribe(function(newVal) {
    popup.visibleIdx.unsubscribe(callee())
    ::gui_scene.setInterval(popup.showTime,
      function() {
        ::gui_scene.clearTimer(callee())
        removePopup(uid) //if popup changed, it has own timer
      })
    })

  popups.update(@(value) value.append(popup))
}

console.register_command(@() addPopup({ text = $"Default popup\ndouble line {counter}" }),
  "popup.add")
console.register_command(@() addPopup({ text = $"Default error popup\nnext line {counter}", styleName = "error" }),
  "popup.error")

return {
  popups = popups
  addPopup = addPopup
  removePopup = removePopup

} 