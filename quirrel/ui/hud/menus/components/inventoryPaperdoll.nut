local { pickup_item_entity_to_gear } = require("humaninv")
local { carriedVolume, capacityVolume, carriedWeight } = require("ui/hud/state/inventory_items_es.nut")
local { equipment } = require("ui/hud/state/equipment_es.nut")
local { draggedData, focusedData, requestData } = require("ui/hud/state/inventory_state.nut")
local iconWidget = require("ui/hud/components/icon3d.nut")
local cursors = require("ui/style/cursors.nut")
local dropMarker = require("dropMarker.nut")

local function paperdoll() {
  local function equippedGearWidget(slot) {
    if (!equipment.value || !(slot in equipment.value)) {
      return null
    }

    local equippedItem = equipment.value[slot]
    local nameLoc = ::loc(equippedItem?.desc ?? "", "")
    local descLoc = ::loc("{0}/desc".subst(equippedItem?.desc ?? ""), "")
    local hint = "{0}{1}".subst(nameLoc, (descLoc != "" ? $": {descLoc}" : ""))
    local requestItem = "request/item/{0}".subst(slot)
    local contextItem = equippedItem.__merge({canDrop=true currentEquipmentSlotName=slot})
    if ((contextItem?.desc ?? "") == "" || (contextItem?.equipmentSlots?.len() ?? 0)== 0)
      contextItem = null

    local function onHover(on) {
      if (on)
        focusedData(contextItem)
      else
        focusedData(null)
      requestData.update(on ? requestItem : "")
      cursors.tooltip.state(on && hint != "" ? hint : null)
    }

    local function onDragMode(on, eqItem){
      draggedData.update(on ? eqItem : null)
    }

    return {
      rendObj = ROBJ_TEXTAREA
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      behavior = [Behaviors.DragAndDrop, Behaviors.TextArea]
      eventPassThrough = true
      onHover = onHover
      onDragMode = onDragMode
      dropData = contextItem
      transform = {}
      children = [iconWidget(equippedItem)]
    }
  }

  local capacityWidget = @() {
    watch = [carriedVolume, capacityVolume]
    rendObj = ROBJ_DTEXT
    halign = ALIGN_CENTER
    text = "{capacity} {curvolume}/{maxvolume}".subst({
      curvolume = carriedVolume.value ?? "0"
      maxvolume = capacityVolume.value
      capacity = ::loc("inventory/capacity")
    })
    vplace = ALIGN_CENTER
    margin = [hdpx(4), 0]
    color = Color(96, 96, 96, 96)
    size = SIZE_TO_CONTENT
  }

  local weightWidget = @() {
    watch = carriedWeight
    rendObj = ROBJ_DTEXT
    halign = ALIGN_CENTER
    text = "{weight} {curweight}".subst({
      weight = ::loc("inventory/weight","Weight:")
      curweight = carriedWeight.value
    })
    vplace = ALIGN_CENTER
    margin = [hdpx(4), 0]
    color = Color(96, 96, 96, 96)
    size = SIZE_TO_CONTENT
  }

  local function equipmentSlotWidget(children, slot_name) {
    local stateFlags=::Watched(0)
    return function() {
      local canDropDragged = @(item) "equipmentSlots" in item
        && item.equipmentSlots.indexof(slot_name) != null
        && slot_name != item?.currentEquipmentSlotName
      local needMark = (draggedData.value != null) && (!canDropDragged || canDropDragged(draggedData.value))
      local children_ = []
      if (type(children)!="array")
        children_=[children]
      else children_ = children
      if(needMark){
        children_.append(dropMarker(stateFlags.value))
      }
      return {
        children = children_
        rendObj = ROBJ_BOX
        size = [sh(8),sh(8)]
        fillColor = Color(0,0,0,120)
        borderColor = Color(30,30,30,160)
        borderWidth=hdpx(2)
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        behavior = Behaviors.DragAndDrop
        canDrop = canDropDragged
        onElemState = @(sf) stateFlags(sf)
        watch = [draggedData, stateFlags]
        onDrop = function(item) {
          pickup_item_entity_to_gear(item?.eid ?? item.id, slot_name)
        }
      }
    }
  }

  local function equipmentLine(list, required = []) {
    local children = []
    foreach (slot in list) {
      local slotWidget = equippedGearWidget(slot)
      if (slotWidget != null)
        children.append(equipmentSlotWidget(slotWidget, slot))
      else if (required.indexof(slot) != null)
        return null
    }
    if (children.len() == 0)
      return null
    return { flow = FLOW_HORIZONTAL gap = sh(0.8) children = children }
  }

  local backpackSlot = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    margin = [0, 0, sh(3), 0]
    children = [
      equipmentLine(["backpack"])
      capacityWidget
      weightWidget
    ]
  }

  return {
    size = [SIZE_TO_CONTENT, flex()]
    watch = equipment
    halign = ALIGN_RIGHT
    children = {
      vplace = ALIGN_CENTER
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = sh(0.5)
      size = [SIZE_TO_CONTENT, flex()]
      children = [
        equipmentLine(["head"])
        equipmentLine(["head_m"])
        { size = [0, flex()] }
        equipmentLine(["shoulder_l", "shoulder_r"], ["shoulder_l", "shoulder_r"])
        equipmentLine(["right_arm", "spine", "left_arm"])
        equipmentLine(["body", "back"], ["body"])
        equipmentLine(["pelvis"])
        equipmentLine(["pelvis_back"])
        equipmentLine(["right_leg", "left_leg"])
        equipmentLine(["leg_l", "leg_r"], ["leg_l", "leg_r"])
        equipmentLine(["tacticalVest"])
        equipmentLine(["beltSlot1", "beltSlot2", "beltSlot3"])
        backpackSlot
        { size = [0, flex()] }
        equipmentLine(["mod1", "mod2"], ["mod1", "mod2"])
        equipmentLine(["gadget"])
      ]
    }
    transform = {}
    animations = [
        { prop=AnimProp.translate,from=[0,-sh(50)], to=[0,0], duration=0.3, play=true, easing=OutCubic }
        { prop=AnimProp.translate,from=[0,0], to=[0,-sh(50)], duration=0.3, playFadeOut=true, easing=OutCubic }
    ]
  }
}

return paperdoll
 