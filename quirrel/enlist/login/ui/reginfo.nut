local {Inactive} = require("ui/style/colors.nut")
local urlText = require("enlist/components/urlText.nut")
local {registerUrl} = require("loginUiParams.nut")
local function text(str) {
  return {
    rendObj = ROBJ_DTEXT
    font = Fonts.medium_text
    text = str
    color = Inactive
  }
}

return function() {
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    size = [sw(100), SIZE_TO_CONTENT]
    pos = [0, sh(20)]
    watch = registerUrl
    children = [
      text(::loc("login with your id in Gaijin.net"))
      {
        flow = FLOW_HORIZONTAL
        size = SIZE_TO_CONTENT
        children = [
          urlText(::loc("or register here"), registerUrl.value)
        ]
      }
    ]
  }
}
 