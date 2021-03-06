local {remove_item_from_weap_to_inventory} = require("humaninv")
local {draggedData, focusedData} = require("ui/hud/state/inventory_state.nut")
local dropMarker = require("dropMarker.nut")

local modTextColor = Color(160,160,160,128)
local modFillDragColor = Color(10,10,10,180)
local transparentColor = Color(0,0,0,0)
local modBorderColor = Color(30,30,30,5)

local actMoveToInventory = @(data)
  remove_item_from_weap_to_inventory(data.currentWeaponSlotName, data.currentWeapModSlotName)

local function weaponModWidgetContent(dropData, image, text, isUnloadable, compsOnHover) {
  local onHoverW = ::Watched(false)
  local onHoverComps = @() { watch = onHoverW, children = onHoverW.value ? compsOnHover : null}
  local rmbAction = dropData?.canDrop ? @() actMoveToInventory(dropData) : null
  local function action(event) {
    if (event.button == 1) rmbAction?()
  }
  return ::watchElemState(function(sf) {
    return  {
      behavior = isUnloadable ? Behaviors.DragAndDrop : null
      transform = {}
      eventPassThrough = true
      rendObj = ROBJ_BOX
      fillColor= (sf & S_DRAG) ? modFillDragColor : transparentColor
      borderColor = (sf & S_DRAG) ? modBorderColor : transparentColor
      skipDirPadNav = true

      size= flex()
      clipChildren = true
      padding = hdpx(1)
      children = [
        {vplace=ALIGN_TOP hplace=ALIGN_CENTER size=SIZE_TO_CONTENT children = image eventPassThrough = true }
        {
          transform = {}
          behavior = isUnloadable ? [Behaviors.Marquee] : null //Behaviors.Button
          //scrollOnHover = true
          vplace = ALIGN_BOTTOM
          eventPassThrough = true
          hplace = ALIGN_CENTER
          maxWidth = pw(100)
          children = {
            rendObj = ROBJ_DTEXT
            text = text
            behavior = isUnloadable ? Behaviors.DragAndDrop : null
            font = Fonts.small_text
            skipDirPadNav = true
            vplace = ALIGN_BOTTOM
            color = modTextColor
            eventPassThrough = true
          }
        }
      ].append(onHoverComps)
      onDragMode = function(on, item) {
        draggedData.update(on ? item : null)
      }
      onClick = action
      dropData = dropData
      function onHover(on){
        focusedData(on ? dropData : null)
        onHoverW(on)
      }
    }
  }
)}

local fillColor = Color(25,25,25,120)
local borderColor = Color(25,25,20,5)
local nullFunc = @() null
local mkWeaponModWidget = ::kwarg(
  function mkWeaponModWidget(size=[sh(14),sh(5.5)], text="", isUnloadable=true, dropData=null, onDrop=nullFunc, canDropDragged=nullFunc, image=null, compsOnHover=null, group=null, children=null) {
    local cont = weaponModWidgetContent(dropData, image, text, isUnloadable, compsOnHover)
    local stateFlags = ::Watched(0)
    children = ::type(children)=="array" ? children : [children]
    local function weaponModWidget() {
      local needMark = (draggedData.value != null) && canDropDragged(draggedData.value)
      local sf = stateFlags.value
      return {
        rendObj = ROBJ_BOX
        size = size
        margin = [0,hdpx(2),hdpx(2),0]
        clipChildren = true
        fillColor = fillColor
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        onElemState = @(newSF) stateFlags.update(newSF)
        skipDirPadNav = true

        children = [cont].extend(children).append(needMark ? dropMarker(sf) : null)
        behavior = [Behaviors.Button, Behaviors.DragAndDrop]
        watch = [draggedData, stateFlags]
        borderColor =  borderColor
        borderWidth = hdpx(1.5)
        canDrop = canDropDragged
        onDrop = onDrop
      }
    }
    return weaponModWidget
  }
)

return mkWeaponModWidget
 