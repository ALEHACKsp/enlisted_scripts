local tabs = require("ui/components/tabs.nut")
local { mkHotkey } = require("ui/components/uiHotkeysHint.nut")

local function settingsHeaderTabs(params) {
  local cTab = params.currentTab

  local function changeTab(delta, cycle=false){
    local tabsSrc = params.sourceTabs
    local len = tabsSrc.len()
    foreach (idx, tab in tabsSrc) {
      if (cTab.value == tab.id) {
        local next_idx = idx+delta
        local total = tabsSrc.len()
        next_idx = cycle ? ((next_idx+total)%total) : ::clamp(next_idx, 0, total-1)
        cTab(tabsSrc[next_idx].id)
        break
      }
    }
  }
  local changeTabWrap = @(delta) changeTab(delta, true)

  local hotkeys_children = [
    mkHotkey("^J:LB", @() changeTab(-1)),
    mkHotkey("^J:RB", @() changeTab(1)),
    {hotkeys = [["^Tab", @() changeTabWrap(1)], ["^L.Shift Tab | R.Shift Tab", @() changeTabWrap(-1)]]}
  ]

  local function tabsHotkeys(){
    return {
      flow = FLOW_HORIZONTAL
      pos = [0,-sh(2.5)]
      gap = sh(0.25)
      children = hotkeys_children
    }
  }

  local function tabsContainer() {
    return {
      watch = cTab
      size = SIZE_TO_CONTENT
      children = tabs({
        tabs = params.sourceTabs
        currentTab = cTab.value
        onChange = function(tab) {
          cTab.update(tab?.id)
        }
      })
    }
  }

  return function() {
    return {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        params.sourceTabs.len() > 1 ? tabsHotkeys : null
        tabsContainer
      ]
    }
  }
}


return settingsHeaderTabs
 