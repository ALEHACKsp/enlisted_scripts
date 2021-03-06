local { textListFromAction, buildElems } = require("ui/control/formatInputBinding.nut")
local { isGamepad } = require("ui/control/active_controls.nut")
local { mkShortHudHintFromList } = require("ui/hud/components/controlHudHint.nut")
local { HUD_TIPS_HOTKEY_FG } = require("ui/hud/style.nut")

local disabledColor = Color(128,128,128,128)

local function isHotkeysEmpty(textList){
  textList = textList ?? [""]
  if (textList.len()==1 && textList?[0] == "")
    return true
  return false
}

const eventTypeToText = false
local function makeControlTip(hotkey, active) {
  return function() {
    local textFunc = @(text){
      text=text font=Fonts.medium_text, color = active ? HUD_TIPS_HOTKEY_FG : disabledColor, rendObj = ROBJ_DTEXT padding = hdpx(4)
    }
    local textList = textListFromAction(hotkey, isGamepad.value ? 1 : 0, eventTypeToText)
    if (isHotkeysEmpty(textList) && (["Human.Weapon1", "Human.Weapon2"].indexof(hotkey) != null)){
      textList = textListFromAction("Human.WeaponNextMain", isGamepad.value ? 1 : 0, eventTypeToText)
    }
    if (isHotkeysEmpty(textList) && ["Human.Weapon1", "Human.Weapon2", "Human.Weapon3", "Human.Weapon4"].indexof(hotkey) != null)
      textList = textListFromAction("Human.WeaponNext", isGamepad.value ? 1 : 0, eventTypeToText)
    if (isHotkeysEmpty(textList) && ["Human.Weapon1", "Human.Weapon2", "Human.Weapon3", "Human.Weapon4"].indexof(hotkey) != null)
      textList = textListFromAction("Human.WeaponPrev", isGamepad.value ? 1 : 0, eventTypeToText)
    local controlElems = buildElems(textList, {textFunc = textFunc, compact = true})
    return mkShortHudHintFromList(controlElems)
  }
}

local weaponHotkeysActive = {}
local weaponHotkeysInactive = {}
local weaponKeys = ["Human.Weapon1", "Human.Weapon2", "Human.Weapon3", "Human.Weapon4", "Human.Throw", "Inventory.UseMedkit",
                    "Human.Melee", "Human.WeaponNextMain", "Human.GrenadeNext", "Human.FiringModeNext"]
foreach (key in weaponKeys) {
  weaponHotkeysActive[key] <- makeControlTip(key, true)
  weaponHotkeysInactive[key] <- makeControlTip(key, false)
}

local function getWeaponHotkeyWidget(key, active) {
  return (active ? weaponHotkeysActive : weaponHotkeysInactive)[key]
}

return getWeaponHotkeyWidget 