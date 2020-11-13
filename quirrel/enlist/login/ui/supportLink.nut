local urlText = require("enlist/components/urlText.nut")
local {gaijinSupportUrl} = require("enlist/components/supportUrls.nut")

return {
  hplace=ALIGN_LEFT
  vplace=ALIGN_BOTTOM
  margin = hdpx(20)
  children = urlText(::loc("support"), gaijinSupportUrl, {opacity=0.7})
} 