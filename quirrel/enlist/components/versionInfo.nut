local {isProductionCircuit, circuit, version, build_number} = require("globals/appInfo.nut")

local function version_info(){
  local buildNum = build_number.value ?? ""
  local versionNum = version.value ?? ""
  local versionInfo = $"version: {versionNum}"
  if (!isProductionCircuit.value)
    versionInfo = $"build: {buildNum} {versionInfo}@{circuit.value}"
  return {
    text = versionInfo
    rendObj = ROBJ_DTEXT
    watch = [circuit, version, isProductionCircuit]
    font = Fonts.tiny_text
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    pos = [-hdpx(18), -hdpx(2)]
    opacity = 0.2
    zOrder = Layers.MsgBox
  }
}

return version_info 