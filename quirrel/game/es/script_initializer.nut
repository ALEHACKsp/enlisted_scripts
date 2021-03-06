                                                   
local function onScript(init = true) {
  return function(evt, eid, comp) {
    local compiledscript = compilestring("local function fun(eid, init) {{0}};return fun;".subst(comp.script_initializer))
    compiledscript()(eid, init)
  }
}


::ecs.register_es("script_initializer_es", {
  onInit = onScript(),
  onChange = onScript(false)
},  {comps_track = [ ["script_initializer" ::ecs.TYPE_STRING]]})
 