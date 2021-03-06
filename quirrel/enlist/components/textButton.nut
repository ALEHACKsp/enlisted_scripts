local textButton = require("daRg/components/textButton.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local colors = require("ui/style/colors.nut")

local textButtonTextCtor = require("textButtonTextCtor.nut")

local override = {
  halign = ALIGN_CENTER
  sound = {
    click  = "ui/enlist/button_click"
    hover  = "ui/enlist/button_highlight"
    active = "ui/enlist/button_action"
  }
  textCtor = textButtonTextCtor
}

local onlinePurchaseStyle = {
  font=Fonts.medium_text
  borderWidth = hdpx(1)

  style = {
    BgNormal = colors.BtnActionBgNormal
    BgActive   = colors.BtnActionBgActive
    BgFocused  = colors.BtnActionBgFocused

    BdNormal  = colors.BtnActionBdNormal
    BdActive   = colors.BtnActionBdActive
    BdFocused = colors.BtnActionBdFocused

    TextNormal  = colors.BtnActionTextNormal
    TextActive  = colors.BtnActionTextActive
    TextFocused = colors.BtnActionTextFocused
    TextHilite  = colors.BtnActionTextHilite
  }
}.__update(override)

local primaryButtonStyle = override.__merge({
  style = {
    BgNormal = 0xfa0182b5
    BgActive   = 0xfa015ea2
    BgFocused  = 0xfa0982ca

    TextNormal  = Color(180, 180, 180, 180)
    TextActive  = Color(120, 120, 120, 120)
    TextFocused = Color(160, 160, 160, 120)
    TextHilite  = Color(220, 220, 220, 160)
  }
})

local smallStyle = {
  font = Fonts.small_text
  textMargin = [hdpx(3), hdpx(5)]
}

local defaultButton = @(text, handler, params = {}) textButton.Bordered(text, handler, override.__merge(params))

local export = class {
  _call = @(self, text, handler, params = {}) defaultButton(text, handler, params)
  Transp = @(text, handler, params = {}) textButton.Transp(text, handler, override.__merge(params))
  Bordered = @(text, handler, params = {}) textButton.Bordered(text, handler, override.__merge(params))
  Small = @(text, handler, params = {}) textButton.Transp(text, handler, override.__merge({font=Fonts.small_text margin=hdpx(1) textMargin=[hdpx(2),hdpx(5),hdpx(2),hdpx(5)]}).__merge(params))
  SmallBordered = @(text, handler, params = {}) textButton.Bordered(text, handler, override.__merge(smallStyle).__merge(params))
  Flat = @(text, handler, params = {}) textButton.Flat(text, handler, override.__merge(params))
  SmallFlat = @(text, handler, params = {})
    textButton.Flat(text, handler, override.__merge(smallStyle).__merge(params))
  FAButton = @(iconId, callBack, params = {})
    textButton(fa[iconId], callBack, {
      size = [hdpx(40), hdpx(40)]
      halign = ALIGN_CENTER
      font = Fonts.fontawesome
      borderWidth = (params?.isEnabled ?? true) ? hdpx(1):0
      margin = hdpx(1)
      sound = (params?.isEnabled ?? true) ? {
          hover = "ui/enlist/button_highlight"
          click = "ui/enlist/button_click"
      } : null
    }.__merge(params))

  Purchase = @(text, handler, params = {}) textButton.Bordered(text, handler, onlinePurchaseStyle.__merge(params))
  PurchaseSmall = @(text, handler, params = {})
    textButton.Bordered(text, handler, onlinePurchaseStyle.__merge(smallStyle).__merge(params))
  PrimaryFlat = @(text, handler, params = {}) textButton.Flat(text, handler, primaryButtonStyle.__merge(params))

  onlinePurchaseStyle = onlinePurchaseStyle
  primaryButtonStyle = primaryButtonStyle
  smallStyle = smallStyle
  override = override

  setDefaultButton = function(buttonCtor) { defaultButton = buttonCtor }
}()

return export
 