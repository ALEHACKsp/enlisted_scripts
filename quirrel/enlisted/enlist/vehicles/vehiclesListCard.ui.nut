local {
  defBgColor, hoverTxtColor, defTxtColor, activeBgColor, hoverBgColor, blockedBgColor,
  vehicleListCardSize, smallPadding, listCtors
} = require("enlisted/enlist/viewConst.nut")
local listTxtColor = listCtors.txtColor
local { iconByGameTemplate, getItemName } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")
local { viewVehicle, selectedVehicle, curSquad, curSquadArmy, NEED_RESEARCH_USE, LOCKED, CANT_USE
} = require("vehiclesListState.nut")
local {
  statusIconChosen, statusIconLocked, statusIconBlocked, statusTier
} = require("enlisted/enlist/soldiers/components/itemPkg.nut")
local { unseenSquadsVehicle, markVehicleSeen } = require("enlisted/enlist/vehicles/unseenVehicles.nut")
local hoverHoldAction = require("utils/hoverHoldAction.nut")

local DISABLED_ITEM = { tint = ::Color(40, 40, 40, 160), picSaturate = 0.0 }

local itemStatusIcon = @(vehicle) vehicle.status & LOCKED ? statusIconLocked
  : vehicle.status & NEED_RESEARCH_USE ? statusIconBlocked
  : null

local function mkUnseenSign(vehicle) {
  local hasUnseenSign = Computed(@()
    unseenSquadsVehicle.value?[curSquad.value?.guid][vehicle?.basetpl] ?? false)
  return @() {
    watch = hasUnseenSign
    children = hasUnseenSign.value ? unseenSignal : null
  }
}

local mkVehicleName = @(vehicle, textColor) txt({
  text = getItemName(vehicle)
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  color = textColor
})

local mkVehicleImage = @(vehicleInfo) (vehicleInfo?.gametemplate ?? "") == ""
  ? null
  : iconByGameTemplate(vehicleInfo.gametemplate, {
      width = vehicleListCardSize[0] - smallPadding * 2
      height = vehicleListCardSize[1] - smallPadding * 2
    }).__update(vehicleInfo?.isShopItem ? DISABLED_ITEM : {})

local amountText = @(count, sf, isSelected) {
  rendObj = ROBJ_SOLID
  color = isSelected || (sf & S_HOVER) ? Color(120, 120, 120, 120) : Color(0, 0, 0, 120)
  size = SIZE_TO_CONTENT
  padding = [smallPadding, 2 * smallPadding]
  children = {
    rendObj = ROBJ_DTEXT
    color = listTxtColor(sf, isSelected)
    font = Fonts.small_text
    text = ::loc("common/amountShort", { count = count })
  }
}

local itemCountRarity = @(item, sf, isSelected) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  children = [
    statusTier(item)
    1 >= (item?.count ?? 0) ? null : amountText(item.count, sf, isSelected)
  ]
}

local function card(item, onClick = @(item) null, onDoubleClick = @(item) null) {
  local isAllowed = (item.status & CANT_USE) == 0

  local onHover = hoverHoldAction("unseenSoldierItem", item.basetpl,
    function(tpl) {
      if (unseenSquadsVehicle.value?[curSquad.value?.guid][tpl] && curSquadArmy.value)
        markVehicleSeen(curSquadArmy.value, tpl)
    })

  return ::watchElemState(function(sf) {
    local textColor = (sf & S_HOVER) || item == viewVehicle.value
      ? hoverTxtColor
      : defTxtColor
    local isSelected = item == viewVehicle.value
    return {
      watch = [viewVehicle, selectedVehicle]
      behavior = Behaviors.Button
      rendObj = ROBJ_SOLID
      onClick = @() onClick(item)
      onDoubleClick = @() onDoubleClick(item)
      onHover

      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }

      color = isSelected ? activeBgColor
        : (sf & S_HOVER) ? hoverBgColor
        : isAllowed ? defBgColor
        : blockedBgColor
      size = vehicleListCardSize
      padding = smallPadding
      children = [
        mkVehicleImage(item)
        {
          children = [
            mkUnseenSign(item)
            item == selectedVehicle.value
              ? statusIconChosen
              : itemStatusIcon(item)
          ]
        }
        mkVehicleName(item, textColor)
        itemCountRarity(item, sf, isSelected)
      ]
    }
  })
}

return ::kwarg(card) 