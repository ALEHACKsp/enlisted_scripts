local msgbox = require("ui/components/msgbox.nut")
msgbox = clone msgbox
local styling = clone msgbox.styling
local BgOverlay = clone styling.BgOverlay

if (msgbox.styling.BgOverlay?.sound!=null)
  msgbox.styling.BgOverlay.sound = null
return msgbox
 