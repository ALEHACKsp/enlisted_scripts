local { defTxtColor, hoverTxtColor, blurBgColor, bigPadding, defBgColor, activeBgColor, warningColor
} = require("enlisted/enlist/viewConst.nut")
local modalWindows = require("daRg/components/modalWindows.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { showNotReadySquads, goToSquadAndClose } = require("model/notReadySquadsState.nut")
local JB = require("ui/control/gui_buttons.nut")

local textButton = require("enlist/components/textButton.nut")
local { mkSquadIcon } = require("components/squadsUiComps.nut")


const WND_UID = "not_ready_squads_msg"
local needShow = keepref(::Computed(@() (showNotReadySquads.value?.notReady.len() ?? 0) > 0))
local close = @() showNotReadySquads(null)

local squadIconSize = [::hdpx(60), ::hdpx(60)]
local squadBlockWidth = ::hdpx(500)

local header = {
  rendObj = ROBJ_DTEXT
  font = Fonts.big_text
  color = defTxtColor
  text = ::loc("notReadySquads/header")
}

local mkHint = @(canBattle) {
  size = [hdpx(1100), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  font = Fonts.big_text
  color = defTxtColor
  text = ::loc(canBattle ? "notReadySquads/canBattleHint" : "notReadySquads/hasCantBattleSquadsHint")
}

local mkText = @(text, color) { rendObj = ROBJ_DTEXT, color = color, text = text }

local function mkSquadRow(readyData) {
  local { squad, unreadyMsgs, canBattle } = readyData
  local stateFlags = ::Watched(0)

  return function() {
    local sf = stateFlags.value
    local textColor = sf & S_HOVER ? hoverTxtColor : defTxtColor
    local allMsgs = (clone unreadyMsgs).map(@(msg, idx)
      mkText(msg, !canBattle && idx == 0 ? warningColor : textColor))
    allMsgs.insert(0, mkText(::loc(squad.manageLocId), textColor))

    return {
      watch = stateFlags
      size = [squadBlockWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_SOLID
      color = sf & S_HOVER ? activeBgColor : defBgColor

      behavior = Behaviors.Button
      onClick = @() goToSquadAndClose(squad)
      onElemState = @(nsf) stateFlags(nsf)

      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      padding = bigPadding
      gap = bigPadding
      children = [
        mkSquadIcon(squad.icon).__update({ size = squadIconSize })
        {
          flow = FLOW_VERTICAL
          children = allMsgs
        }
      ]
    }
  }
}

local mkSquadsList = @(notReadyList) {
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = notReadyList.map(mkSquadRow)
}

local mkButtons = @(onContinue) {
  flow = FLOW_HORIZONTAL
  children = onContinue == null
    ? textButton(::loc("Ok"), close)
    : [
        textButton(::loc("continueToBattle"),
          function() {
            close()
            onContinue()
          },
          { hotkeys = [["^Enter | Space"]] })
        textButton(::loc("Cancel"), close)
      ]
}

local function notReadySquadMsg() {
  local { notReady = [], onContinue = null } = showNotReadySquads.value
  local canBattle = notReady.findvalue(@(s) !s.canBattle) == null
  return {
    watch = showNotReadySquads
    size = SIZE_TO_CONTENT
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = ::hdpx(20)

    children = [
      header
      mkSquadsList(notReady)
      mkHint(canBattle)
      mkButtons(canBattle ? onContinue : null)
    ]
  }
}

local open = @() modalWindows.add({
  key = WND_UID
  size = [sw(100), sh(100)]
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  children = notReadySquadMsg
  onClick = close
  hotkeys = [[$"^Esc | {JB.B}", { description = ::loc("Close") }]]
})

needShow.subscribe(@(v) v ? open() : modalWindows.remove(WND_UID)) 