local {blurBgColor, blurBgFillColor} = require("viewConst.nut")
local textButton = require("enlist/components/textButton.nut")
textButton.override.__update({ borderRadius = 0 })
textButton.primaryButtonStyle.__update({ borderRadius = 0 })
textButton.onlinePurchaseStyle.__update({ borderRadius = 0, borderWidth = 0 })
textButton.setDefaultButton(@(text, handler, params = {}) textButton.Bordered(text, handler, {borderWidth = 1, borderColor=Color(40,40,40,2)}.__merge(params)))

require("enlist/components/modalPopupWnd.nut").POPUP_PARAMS.__update({
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  borderRadius = 0
}) 