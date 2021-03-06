local {mkInputHintBlock} = require("ui/hud/huds/tips/tipComponent.nut")
local {curWeaponTotalAmmo, curWeaponIsReloadable, curWeaponAmmo, curWeaponHasSwitchableWeaponMods} = require("weapons_state.nut")
local {blurBack, DEFAULT_TEXT_COLOR} = require("style.nut")

local heightTxt = ::calc_comp_size({font = Fonts.medium_text rendObj = ROBJ_DTEXT text="auto"})[1]
local ammoNumAnim = [
  { prop=AnimProp.scale, from=[1.25,1.4], to=[1,1], duration=0.25, play=true, easing=OutCubic }
]

local weapModToggleHint = mkInputHintBlock("Human.WeapModToggle")
local function weapModToggleTip() {
  return {
    watch = [curWeaponHasSwitchableWeaponMods]
    vplace = ALIGN_CENTER
    children = curWeaponHasSwitchableWeaponMods.value ? [weapModToggleHint] : null
    padding = [0,heightTxt/2,0,0]
  }
}

local curAmmoCmp = @(){
  rendObj = ROBJ_DTEXT
  text = curWeaponAmmo.value
  watch = curWeaponAmmo
  font = Fonts.medium_text
  color = DEFAULT_TEXT_COLOR
  key = curWeaponAmmo.value
  transform = {
    pivot = [0.5, 0.5]
  }
  animations = ammoNumAnim
}
local sep = {
  rendObj = ROBJ_DTEXT
  text = " / "
  font = Fonts.small_text
  color = DEFAULT_TEXT_COLOR
}

local totalAmmoCmp = @() {
  rendObj = ROBJ_DTEXT
  text = curWeaponTotalAmmo.value
  watch = curWeaponTotalAmmo
  font = Fonts.small_text
  color = DEFAULT_TEXT_COLOR
  animations = ammoNumAnim
}

local ammoInfo = @(){
  size = SIZE_TO_CONTENT
  watch = curWeaponIsReloadable
  children = curWeaponIsReloadable.value ? [
    blurBack,
    {
      size  = [SIZE_TO_CONTENT, heightTxt]
      padding = [0,hdpx(2),0,hdpx(2)]
      flow  = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      valign = ALIGN_CENTER
      children = [weapModToggleTip, curAmmoCmp, sep, totalAmmoCmp]
    }
  ] : null
}
return ammoInfo 