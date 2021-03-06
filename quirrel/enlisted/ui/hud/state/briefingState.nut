local components = {
  comps_track = [
    ["briefing", ::ecs.TYPE_BOOL],
    ["header", ::ecs.TYPE_STRING, "briefing/header"],
    ["common_header", ::ecs.TYPE_STRING, ""],
    ["briefing_common", ::ecs.TYPE_STRING, ""],
    ["common", ::ecs.TYPE_STRING, ""],
    ["hints_header", ::ecs.TYPE_STRING, "briefing/common_hints_header"],
    ["hints", ::ecs.TYPE_STRING, "common/controls"],
    ["showtime",  ::ecs.TYPE_FLOAT, 10.0],
  ]
  /*todo: replace image_team1, image_team2, team1, team_default, etc to
    briefing = {def={text="" image=null} [0]={text="" image=""} [1]={text="" image=""}} and use default if not specified
  */
}

local function create_table_from_comps(comps, func = null) {
  local ret = {}
  foreach (comp_type, compsList in comps) {
    foreach (c in compsList) {
      ret[c[0]] <- (func?(c[0]) ?? c?[2])
    }
  }
  return ret
}

local state = persist("state", @() {
  briefing = Watched(create_table_from_comps(components))
})


local function onChange(evt,eid,comp) {
  local curstate = state.briefing.value
  local attr = evt[0]
  curstate[attr] = comp[attr]
  state.briefing.update(curstate)
}

local function onInit(evt, eid, comp) {
  state.briefing.update(create_table_from_comps(components, @(k) ::ecs.get_comp_val(eid, k, null)))
}

::ecs.register_es("es_ui_briefing", {
    onInit=onInit,
    onChange=onChange,
    onDestroy=function(evt,eid,comp) {state.briefing.update(create_table_from_comps(components))}
  }, components
)
local showBriefingOnSquadChange = Watched(false)
::ecs.register_es("es_ui_briefing_show_on_squad_change", {
    onInit =  @(evt, eid, comp) showBriefingOnSquadChange(true)
    onDestroy =  @(evt, eid, comp) showBriefingOnSquadChange(false)
  }, {comps_rq = ["show_briefing_on_squad_change"]}
)

local showBriefingOnHeroChange = Watched(false)
::ecs.register_es("es_ui_briefing_show_on_hero_change", {
    onInit =  @(evt, eid, comp) showBriefingOnHeroChange(true)
    onDestroy =  @(evt, eid, comp) showBriefingOnHeroChange(false)
  }, {comps_rq = ["show_briefing_on_hero_change"]}
)

local showBriefing = persist("showBriefing", @() Watched(false))

state.__update({
  showBriefingOnHeroChange
  showBriefingOnSquadChange
  showBriefingForTime = Watched(null)
  showBriefing
})

return state
 