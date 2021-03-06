local {weaponsList} = require("ui/hud/state/hero_state.nut")
local {grenades} = require("ui/hud/state/inventory_items_es.nut")
local {blurBack, notSelectedItemColor, HUD_ITEMS_COLOR, iconSize, itemAppearing} = require("style.nut")
local grenadeIcon = require("grenadeIcon.nut")

local getGrenadeIcon = ::memoize(@(gtype) grenadeIcon(gtype, iconSize))

local curGrenadeSize = [sh(2.5), sh(2.5)]
local getCurGrenadeIcon = ::memoize(@(gtype) grenadeIcon(gtype, curGrenadeSize))

local small_count = @(count, color) {
  rendObj = ROBJ_DTEXT
  key = count
  text = count > 1 ? count.tostring() : null
  color = color
  font = Fonts.tiny_text
  vplace = ALIGN_BOTTOM
  pos = [0, hdpx(2)]
  animations = itemAppearing
}


local currentGrenade = ::Computed(@() weaponsList.value.filter(@(weapon) weapon?.currentWeaponSlotName == "grenade")?[0]?.grenadeType)
local playerGrenadesBelt = ::Computed(function(){
  local allGrenades=grenades.value
  local curGrenadeType=currentGrenade.value
  local res = []
  local grenadesCopy = clone allGrenades
  local curGrenade = []
  if (curGrenadeType in grenadesCopy) {
    curGrenade = [[curGrenadeType, delete grenadesCopy[curGrenadeType]]]
  }
  foreach (grenadeType, grenadeCount in grenadesCopy){
    res.append([grenadeType, grenadeCount])
  }
  res.extend(curGrenade)
  return res
})

local function mkGrenadeImage(grenadeType, color, isCurrent=false, pos=null){
  return {
    rendObj = ROBJ_IMAGE
    image = isCurrent ? getCurGrenadeIcon(grenadeType) : getGrenadeIcon(grenadeType)
    hplace = ALIGN_CENTER
    size = isCurrent ? curGrenadeSize : iconSize
    color = color
    pos = pos
  }
}
local shadowColor = Color(0,0,0,90)
local selectedShadowColor = Color(0,0,0,120)
local function mkGrenadeWidget(grenadeType, count, key, isCurrent=false){
  local color = isCurrent ? HUD_ITEMS_COLOR : notSelectedItemColor
  return {
    flow = FLOW_HORIZONTAL
    gap = ::hdpx(1)
    key = key
    animations = itemAppearing
    children = [
      {
        children = [
          mkGrenadeImage(grenadeType, isCurrent ? selectedShadowColor : shadowColor, isCurrent, [hdpx(1), hdpx(1)])
          mkGrenadeImage(grenadeType, color, isCurrent)
        ]
        size = SIZE_TO_CONTENT
      }
      small_count(count, color)
    ]
  }
}
local function grenadesBlock() {
  local children = playerGrenadesBelt.value.map(@(g,i,list) mkGrenadeWidget(g[0],g[1], "_".concat(g[0],g[1],i), i==list.len()-1))

  return {
    size = SIZE_TO_CONTENT
    watch = [playerGrenadesBelt]
    children = [
      blurBack
      {
        flow = FLOW_HORIZONTAL
        size = SIZE_TO_CONTENT
        gap = sh(0.4)
        children = children
        valign =ALIGN_BOTTOM
      }
    ]
    animations = itemAppearing
  }
}


local belt = {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  gap = hdpx(10)
  valign = ALIGN_BOTTOM
  size = SIZE_TO_CONTENT //todo - min-height should be SIZE_TO_CONTENT, height - flex
  children = grenadesBlock
}

return belt

 