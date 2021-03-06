local cursors = require("ui/style/cursors.nut")
local tooltipBox = require("ui/style/tooltipBox.nut")
local premiumWnd = require("premiumWnd.nut")
local { premiumActiveInfo, premiumImage } = require("premiumComp.nut")
local { bigPadding } = require("enlisted/enlist/viewConst.nut")
local { sendBigQueryUIEvent } = require("enlist/bigQueryEvents.nut")

local premiumWidget = @() {
  size = [ph(100), ph(100)]
  padding = bigPadding
  behavior = Behaviors.Button
  onClick = function() {
    premiumWnd()
    sendBigQueryUIEvent("open_premium_window", null, "menubar_premium")
  }
  onHover = @(on) cursors.tooltip.state(on
    ? tooltipBox(premiumActiveInfo())
    : null)
  children = premiumImage(hdpx(35))
}

return premiumWidget
 