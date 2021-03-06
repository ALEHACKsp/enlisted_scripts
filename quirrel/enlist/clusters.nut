local {ControlBgOpaque, BtnBgDisabled, BtnBdDisabled, BtnTextVisualDisabled} = require("ui/style/colors.nut")
local {canChangeQueueParams, queueClusters, isInQueue} = require("quickMatchQueue.nut")
local {availableClusters, clusters} = require("clusterState.nut")
local popupsState = require("enlist/popup/popupsState.nut")
local textButton = require("components/textButton.nut")
local modalPopupWnd = require("enlist/components/modalPopupWnd.nut")
local multiselect = require("enlist/components/multiselect.nut")

local clustersViewMap = { RU = "EEU" }
local clusterLoc = @(cluster) ::loc(clustersViewMap?[cluster] ?? cluster)

local borderColor = Color(60,60,60,255)
local btnParams = { size = [flex(), hdpx(50)], halign = ALIGN_LEFT, margin = 0,
  textMargin = [0, 0, 0, sh(1.5)] }
local visualDisabledBtnParams = btnParams.__merge({
  style = {
    BgNormal = BtnBgDisabled
    BdNormal = BtnBdDisabled
    TextNormal = BtnTextVisualDisabled
  }
})

local clusterSelector = @() {
  size = [flex(), SIZE_TO_CONTENT]
  watch = availableClusters
  children = multiselect({
    selected = clusters
    minOptions = 1
    options = availableClusters.value.map(@(c) { key = c, text = clusterLoc(c) })
  })
}

local function showCantChangeMessage() {
  local text = isInQueue.value ? ::loc("Can't change params while in queue") : ::loc("Only squad leader can change params")
  popupsState.addPopup({ id = "groupSizePopup", text = text, styleName = "error" })
}

local mkClustersUi = ::kwarg(function(style = {}){
  local size = style?.size ?? [hdpx(250), SIZE_TO_CONTENT]
  local popupWidth = size?[0] ?? SIZE_TO_CONTENT
  local function openClustersMenu(event) {
    modalPopupWnd.add(event.targetRect, {
      uid = "clusters_selector"
      size = [popupWidth, SIZE_TO_CONTENT]
      children = clusterSelector
      popupOffset = hdpx(5)
      popupHalign = ALIGN_LEFT
      fillColor = ControlBgOpaque
      borderColor = borderColor
      borderWidth = hdpx(1)
    })
  }
  return function clustersUi() {
    local clustersArr = queueClusters.value
      .filter(@(has, cluster) has && availableClusters.value.indexof(cluster) != null)
      .keys()
    local text = "{0}: {1}".subst(::loc("quickMatch/Server"), ", ".join(clustersArr.map(clusterLoc)))
    return {
      watch = [queueClusters, canChangeQueueParams, availableClusters]
      size = size
      children = canChangeQueueParams.value
        ? textButton(text, openClustersMenu, btnParams)
        : textButton(text, showCantChangeMessage, visualDisabledBtnParams)
    }
  }
})

return {
  mkClustersUi
} 