local { Inactive } = require("ui/style/colors.nut")
local { bigGap, gap } = require("enlisted/enlist/viewConst.nut")
local { navBottomBarHeight } = require("enlisted/enlist/mainMenu/mainmenu.style.nut")
local { mailboxEnabled } = require("enlist/mailboxState.nut")
local mailboxButton = require("enlist/mailboxButton.ui.nut")
local { isContactsEnabled } = require("enlist/contacts/contactsState.nut")
local contactsButton = require("enlist/contacts/contactsButton.ui.nut")
local { enabledSquad } = require("enlist/squad/squadState.nut")
local squadWidget = require("enlisted/enlist/squad/squadWidget.ui.nut")
local { curSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")

local showSocialBlock = Computed(@() curSection.value == "SOLDIERS")


local buttons = ::Computed(
  function() {
    local res = []
    if (mailboxEnabled.value)
      res.append(mailboxButton)
    if (isContactsEnabled.value)
      res.append(contactsButton)
    return res
  })

local allBlocks = ::Computed(function() {
  if (!showSocialBlock.value)
    return null
  local res = []
  if (enabledSquad.value)
    res.append(squadWidget)
  if (buttons.value.len() > 0)
    res.append({
      size = [SIZE_TO_CONTENT, navBottomBarHeight]
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = gap
      children = buttons.value
    })
  return res
})

local bottomBar = @() {
  watch = allBlocks
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = {
    size = [hdpx(1), ph(65)]
    rendObj = ROBJ_SOLID
    color = Inactive
    margin = [0, bigGap, 0, bigGap]
  }
  children = allBlocks.value
}

return bottomBar
 