local colors = require("ui/style/colors.nut")
local baseSelect = require("daRg/components/select.nut")
local baseSelectStyle = require("daRg/components/select.style.nut")

local rootStyle = clone baseSelectStyle.rootStyle
local elemStyle = baseSelectStyle.elemStyle.__merge({
  textCommonColor = colors.BtnTextNormal
  textActiveColor = colors.BtnTextActive
  textHoverColor = colors.BtnTextHover

  borderColor = colors.comboboxBorderColor

  bkgActiveColor = colors.BtnBgSelected
  bkgHoverColor = colors.BtnBgHover
  bkgNormalColor = colors.BtnBgNormal

})

return ::kwarg(function select(state, options, onClickCtor=null, isCurrent=null, textCtor=null, elem_style=null, root_style=null) {
  return baseSelect({
    state, options,
    onClickCtor,
    isCurrent,
    textCtor,
    elem_style=elemStyle.__merge(elem_style ?? {}),
    root_style = rootStyle.__merge(root_style ?? {})
  })
})
 