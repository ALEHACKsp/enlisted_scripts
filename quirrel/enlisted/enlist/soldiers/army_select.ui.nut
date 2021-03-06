local { isGamepad } = require("ui/control/active_controls.nut")
local { mkHotkey } = require("ui/components/uiHotkeysHint.nut")
local { gap, bigGap, activeTitleTxtColor } = require("enlisted/enlist/viewConst.nut")
local { mkPromoImg, mkIcon, mkName } = require("components/armyPackage.nut")
local { allArmiesInfo } = require("model/config/gameProfile.nut")
local { playerSelectedArmy, curArmies_list } = require("model/state.nut")

local armyBtn = ::kwarg(function (armyId, override = {}, hasBackImage = false, addChild = null) {
  local function builder(sf) {
    local isSelected = armyId == playerSelectedArmy.value
    return {
      rendObj = ROBJ_BOX
      watch = [playerSelectedArmy, allArmiesInfo]
      size = SIZE_TO_CONTENT
      borderWidth = (isSelected || (sf & S_HOVER)) ? [0, 0, hdpx(4), 0] : 0
      children = [
        hasBackImage ? mkPromoImg(armyId) : null
        {
          flow = FLOW_HORIZONTAL
          gap = gap
          padding = bigGap
          size = SIZE_TO_CONTENT
          vplace = ALIGN_BOTTOM
          children = [
            mkIcon(armyId)
            mkName(armyId, isSelected, sf)
          ]
        }
        addChild?(armyId, sf)
      ]
    }.__update(!isSelected
      ? {
        behavior = Behaviors.Button
        skipDirPadNav = true
        sound = {
          hover = "ui/enlist/button_highlight"
          click = "ui/enlist/button_click"
        }
        onClick = @() playerSelectedArmy(armyId)
      }
      : {}
    ).__update(override)
  }
  return ::watchElemState(builder)
})

local function selectArmyByGamepad(val) {
  local armies = curArmies_list.value ?? []
  local newArmyId = armies?[val]
  if (newArmyId != null)
    playerSelectedArmy(newArmyId)
}

local function armySelect(hasHotkeys = true, addChild = null, hasBackImage = false, override = {}, customGap = null) {
  local res = function() {
    local children = curArmies_list.value
      .map(@(armyId) armyBtn({
        armyId = armyId
        override = override
        hasBackImage = hasBackImage
        addChild = addChild
      }))
    return {
      watch = curArmies_list
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = customGap ?? {
        rendObj = ROBJ_DTEXT
        text = ::loc("mainmenu/versus_short")
        vplace = ALIGN_BOTTOM
        margin = hdpx(20)
        color = activeTitleTxtColor
      }
      children = children.len() > 1 ? children : null
    }
  }
  if (!hasHotkeys)
    return res

  local tb = @(key, val) @() {
    children = mkHotkey(key, @() selectArmyByGamepad(val))
    isHidden = !isGamepad.value
    watch = [isGamepad, curArmies_list]
    size = SIZE_TO_CONTENT
  }
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      tb("^J:LT", 0)
      res
      tb("^J:RT", 1)
    ]
  }
}

return ::kwarg(armySelect)
 