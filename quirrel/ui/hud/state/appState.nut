                                                                 

local levelLoaded = persist("levelLoaded", @() Watched(false))
::ecs.register_es("level_state_ui_es",
  {
    [["onChange","onInit"]] = @(evt, eid, comp)  levelLoaded.update(comp["level.loaded"])
    onDestroy = @(evt,eid, comp) levelLoaded.update(false)
  },
  {comps_track = [["level.loaded", ::ecs.TYPE_BOOL]]}
)


local levelIsLoading = persist("levelIsLoading", @() Watched(false))
::ecs.register_es("level_is_loading_ui_es",
  {
    [["onChange","onInit"]] = @(evt, eid, comp) levelIsLoading(comp["level_is_loading"])
    onDestroy = @(evt,eid, comp) levelIsLoading.update(false)
  },
  {comps_track = [["level_is_loading", ::ecs.TYPE_BOOL]]}
)

local currentLevelBlk = persist("currentLevelBlk", @() Watched())
::ecs.register_es("level_blk_name_ui_es",
  {
    [["onInit"]] = @(evt, eid, comp) currentLevelBlk(comp["level.blk"])
    onDestroy = @(evt,eid, comp) currentLevelBlk.update(null)
  },
  {comps_ro = [["level.blk", ::ecs.TYPE_STRING]]}
)

local uiDisabled = persist("uiDisabled", @() Watched(false))
::ecs.register_es("ui_disabled_ui_es",
  {
    [["onChange","onInit"]] = @(evt, eid, comp) uiDisabled.update(comp["ui.disabled"])
    onDestroy = @(evt,eid, comp) uiDisabled.update(false)
  },
  {comps_track = [["ui.disabled", ::ecs.TYPE_BOOL]]}
)

local dbgLoading = persist("dbgLoading", @() Watched(false))
console.register_command(function() {dbgLoading(!dbgLoading.value)},
  "ui.loadingDbg")


return {
  levelLoaded
  levelIsLoading
  uiDisabled //this is ugly, but we can't disabled HUD via absence of data
  currentLevelBlk
  dbgLoading
} 