local {safeAreaShow, safeAreaAmount} = require("globals/safeArea.nut")

local function dbgSafeArea(){
  return {
    size = [sw(100*safeAreaAmount.value), sh(100*safeAreaAmount.value)]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = safeAreaShow.value ? ROBJ_FRAME : null
    watch = [safeAreaShow, safeAreaAmount]
    color = Color(255,128,128)
  }
}

return { dbgSafeArea } 