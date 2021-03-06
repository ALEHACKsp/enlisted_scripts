local { curSectionDetails } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local msgbox = require("enlist/components/msgbox.nut")
local mkOnlineSaveData = require("enlist/options/mkOnlineSaveData.nut")

local menuDescShown = mkOnlineSaveData("menuDescShown", @() {})
local TaskTextDesc = Color(150, 150, 160, 220)

local function showDescription(section) {
  local descId = section?.descId
  if ((descId ?? "") == "")
    return

  local id = section.id
  local shown = menuDescShown.watch.value
  if (id in shown)
    return
  menuDescShown.setValue(shown.__merge({ [id] = true }))

  local description = {
    content = {
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      gap = ::hdpx(40)
      children = [
        {
          size = [sw(35), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          font = Fonts.big_text
          text = ::loc(section.locId)
        }
        {
          size = [sw(50), SIZE_TO_CONTENT]
          halign = ALIGN_LEFT
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          font = Fonts.medium_text
          color = TaskTextDesc
          text = ::loc(descId)
          parSpacing = ::hdpx(20)
        }
      ]
    }
    buttons = [{ text = ::loc("Ok"), isCurrent = true, isCancel = true }]
  }
  msgbox.showMessageWithContent(description)
}

console.register_command(@() menuDescShown.setValue({}), "ui.resetMenuDescriptions")

curSectionDetails.subscribe(showDescription) 