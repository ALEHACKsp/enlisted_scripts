       
                                                                                               
  
local hudState = {
  leftPanelTop    = Watched(null)
  leftPanelMiddle = Watched(null)
  leftPanelBottom = Watched(null)
  centerPanelTop    = Watched(null)
  centerPanelMiddle = Watched(null)
  centerPanelBottom = Watched(null)
  rightPanelTop    = Watched(null)
  rightPanelMiddle = Watched(null)
  rightPanelBottom = Watched(null)

  debug_borders = persist("debug_borders", @() Watched(false))

  centerPanelBottomStyle = Watched({})
  centerPanelTopStyle = Watched({})
  centerPanelMiddleStyle = Watched({})

  rightPanelBottomStyle = Watched({})
  rightPanelTopStyle = Watched({})
  rightPanelMiddleStyle = Watched({})

  leftPanelBottomStyle = Watched({})
  leftPanelTopStyle = Watched({})
  leftPanelMiddleStyle = Watched({})
}

::console.register_command(@() hudState.debug_borders.update(!hudState.debug_borders.value),"ui.hud_layout_borders_debug")

return hudState
 