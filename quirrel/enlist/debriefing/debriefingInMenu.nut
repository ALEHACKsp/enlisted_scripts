local debriefingStateBase = require("debriefingStateInMenu.nut")
local { dbgShow, dbgData } = require("debriefingDbgState.nut")
local { gameClientActive } = require("enlist/gameLauncher.nut")
local navState = require("enlist/navState.nut")

local function init(ctor, state = null, clearData = null) {
  local { show, data } = state ?? debriefingStateBase
  clearData = clearData ?? debriefingStateBase.clearData

  local needShow = keepref(::Computed(@() !gameClientActive.value && (dbgShow.value || show.value)))

  gameClientActive.subscribe(function(active) {
    if (!active)
      return
    clearData() //clear previous battle debriefing
    dbgShow(false)
  })

  local closeAction = @() dbgShow.value ? dbgShow(false) : show(false)
  local dataToShow = ::Computed(@() dbgShow.value ? dbgData.value : data.value)
  local debriefingWnd = @() {
    key = "enlist_debriefing_root"
    watch = dataToShow

    size = flex()
    children = ctor(
      dataToShow.value,
      closeAction
    )
  }

  needShow.subscribe(
    function(val) {
      if (val)
        navState.addScene(debriefingWnd)
      else
        navState.removeScene(debriefingWnd)
    }
  )
  if (needShow.value)
    navState.addScene(debriefingWnd)
}
return init 