local soldierClasses = require("model/soldierClasses.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local { classIcon } = require("components/soldiersUiComps.nut")
local {
  smallPadding, activeBgColor, hoverBgColor, defBgColor, listCtors,
  slotMediumSize
} = require("enlisted/enlist/viewConst.nut")

local sClassSlotWidth = slotMediumSize[0]

local sClassBgColor = @(flags, isSelected)
  isSelected ? activeBgColor
    : flags & S_HOVER ? hoverBgColor
    : defBgColor

local mkCardText = @(t, sf, isSelected) txt({
  text = t
  color = listCtors.txtColor(sf, isSelected)
})

local function mkClassTab(sClass, isSelected, onSelect, addedObj = null) {
  local stateFlags = ::Watched(0)
  return function() {
    local sf = stateFlags.value
    local classCfg = soldierClasses?[sClass] ?? soldierClasses.unknown
    return {
      watch = stateFlags
      rendObj = ROBJ_SOLID
      size = [sClassSlotWidth, SIZE_TO_CONTENT]
      padding = smallPadding
      color = sClassBgColor(sf, isSelected)
      key = $"class_{sClass}"
      behavior = Behaviors.Button
      xmbNode = ::XmbNode()
      onElemState = @(newSF) stateFlags(newSF)
      onClick = @() onSelect(sClass)
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          valign = ALIGN_CENTER
          children =[
            classIcon(sClass, hdpx(50), null, listCtors.txtColor(sf, isSelected))
            mkCardText(::loc(classCfg.locId), sf, isSelected)
          ]
        }
        addedObj
      ]
    }
  }
}

return {
  mkClassTab = mkClassTab
}
 