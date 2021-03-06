local {curWeaponName, curWeaponFiringMode, showWeaponBlock} = require("weapons_state.nut")
local {blurBack, DEFAULT_TEXT_COLOR} = require("style.nut")

local ammoInfo = require("player_ammo.ui.nut")
local heightFireMode = ::calc_comp_size({font = Fonts.small_text rendObj = ROBJ_DTEXT text="auto"})[1]
local heightTxt = ::calc_comp_size({font = Fonts.medium_text rendObj = ROBJ_DTEXT text="auto"})[1]


local weaponNameCmp = @() {
  size = SIZE_TO_CONTENT
  watch = curWeaponName
  children = curWeaponName.value != "" ?
    [
      blurBack,
      {
        padding=[0,hdpx(2),0,hdpx(2)]
        rendObj = ROBJ_DTEXT
        text = ::loc(curWeaponName.value)
        font = Fonts.medium_text
        color = DEFAULT_TEXT_COLOR
        minHeight=heightTxt
      }
   ] : null
}

local firingModeCmp = @(){
  size = SIZE_TO_CONTENT
  watch = curWeaponFiringMode
  children = (curWeaponFiringMode.value != "") ? [
    blurBack
    {
      padding=[0,hdpx(2),0,hdpx(2)]
      rendObj = ROBJ_DTEXT
      minHeight=heightFireMode
      text = ::loc("firing_mode/{0}".subst(curWeaponFiringMode.value))
      font = Fonts.small_text
      color = DEFAULT_TEXT_COLOR
    }
  ] : null
}

local function weaponBlock() {
  return {
    halign = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    size = [SIZE_TO_CONTENT, heightFireMode+heightTxt*2]
    watch = [showWeaponBlock]
    children = showWeaponBlock.value ? {
      size = SIZE_TO_CONTENT
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      children = {
        flow = FLOW_VERTICAL
        halign = ALIGN_RIGHT
        valign = ALIGN_BOTTOM
        size = SIZE_TO_CONTENT
        children = [ammoInfo, weaponNameCmp, firingModeCmp]
      }
    }: null
  }
}

return weaponBlock 