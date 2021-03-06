local {joinQueue, leaveQueue, isInQueue} = require("enlist/quickMatchQueue.nut")
local textButton = require("enlist/components/textButton.nut")
local {leaveRoom, room} = require("enlist/state/roomState.nut")
local {showCreateRoom} = require("globals/uistate.nut")
local {BtnActionBgNormal, BtnActionBgDisabled}  = require("ui/style/colors.nut")
local JB = require("ui/control/gui_buttons.nut")
local { curUnfinishedBattleTutorial } = require("enlisted/enlist/tutorial/battleTutorial.nut")
local gameLauncher = require("enlist/gameLauncher.nut")
local {myExtSquadData,
  isSquadLeader,
  squadSelfMember,
  isInSquad } = require("enlist/squad/squadState.nut")
local { showCurNotReadySquadsMsg } = require("soldiers/model/notReadySquadsState.nut")

local skip_descr = {description = {skip=true}}

local defQuickMatchBtnParams = {
  size = [pw(100), hdpx(80)]
  halign = ALIGN_CENTER
  margin = 0
  borderWidth = hdpx(0)
  textParams = { validateStaticText = false, rendObj=ROBJ_DTEXT font = Fonts.big_text }
}

local stdQuickMatchBtnParams = {style = {BgNormal   = BtnActionBgNormal}}.__merge(defQuickMatchBtnParams)
local mkButton = @(quickBtnText, quickMatchFn, quickMatchBtnParams) textButton(quickBtnText, quickMatchFn, quickMatchBtnParams)
local disabledQuickMatchBtnParams = {style = {BgNormal   = BtnActionBgDisabled}}.__merge(defQuickMatchBtnParams)
local quickMatchBtnParams = stdQuickMatchBtnParams.__merge({hotkeys = [ ["^J:Y", skip_descr] ]})
local leaveBtnParams = defQuickMatchBtnParams.__merge({hotkeys = [ ["^{0} | Esc".subst(JB.B), skip_descr] ]})

local quickMatchButtonWidth = hdpx(400)
local function quickMatchFn() {
  if (room.value)
    leaveRoom(@(...) null)
  showCreateRoom.update(false)
  joinQueue()
}

local leaveQuickMatchButton = textButton(::loc("Leave queue"), @() leaveQueue(), leaveBtnParams)

local quickMatchFunction = @(cb) cb != null
  ? cb(quickMatchFn)
  : quickMatchFn()

local mkJoinQuickMatchButton = @(cb)
  mkButton(::loc("START"),
    @() showCurNotReadySquadsMsg(@() quickMatchFunction(cb)),
    quickMatchBtnParams)

local function mkQuickMatchButton(params = {}) {
  local cb = params?.callback
  return @() {
    size = [quickMatchButtonWidth, SIZE_TO_CONTENT]
    watch = [isInQueue]
    children = isInQueue.value
      ? leaveQuickMatchButton
      : mkJoinQuickMatchButton(cb)
   }.__merge(params?.style ?? {})
}

local function mkSquadQuickMatchButton(params){
  local mkQBtn = @(btn) {size = params?.style?.size ?? [flex(), SIZE_TO_CONTENT], minWidth = hdpx(250), children = btn}
  local quickMatchBtn = mkQuickMatchButton(params)
  local pressWhenReadyBtn = mkQBtn(mkButton(::loc("Press when ready"),
    @() showCurNotReadySquadsMsg(@() myExtSquadData.ready(true)),
    stdQuickMatchBtnParams.__merge({ hotkeys = [ ["^J:Y", skip_descr ] ] }))
  )

  local setNotReadyBtn = mkQBtn(mkButton(::loc("Set not ready"),
    @() myExtSquadData.ready(false),
    disabledQuickMatchBtnParams.__merge({ hotkeys = [ ["^J:B", skip_descr ] ] }))
  )
  return function() {
    local btn = quickMatchBtn
    if (!isSquadLeader.value && squadSelfMember.value != null)
      btn = myExtSquadData.ready.value ? setNotReadyBtn : pressWhenReadyBtn
    return {
      watch = [
        isSquadLeader,
        squadSelfMember,
        myExtSquadData.ready
      ]
      size = SIZE_TO_CONTENT
      children = btn
    }
  }
}

local startTutorial = @() gameLauncher.startGame({
  game = "enlisted", scene = curUnfinishedBattleTutorial.value
}, @(...) null)

local startTutorialBtn = mkButton(::loc("TUTORIAL"), startTutorial, quickMatchBtnParams)

local btnParams = {style = {size = [quickMatchButtonWidth, SIZE_TO_CONTENT]}}
local quickMatchButton = mkQuickMatchButton(btnParams)
local squadMatchButton = mkSquadQuickMatchButton(btnParams)

local startBtn = @() {
  watch = [curUnfinishedBattleTutorial, isInSquad]
  children = curUnfinishedBattleTutorial.value != null ? startTutorialBtn
    : isInSquad.value ? squadMatchButton
    : quickMatchButton
  size = [quickMatchButtonWidth, SIZE_TO_CONTENT]
}

return {
  startBtn = startBtn
  startBtnWidth = quickMatchButtonWidth
}
 