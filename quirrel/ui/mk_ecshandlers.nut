local function defComp_ctor(key, comp){
  if (::type(comp?[key])=="instance")
    return comp?[key]?.getAll()
  return comp?[key]
}
local function makeEcsHandlers(watched, comps, compCtor=defComp_ctor) {
  local fullCompsList = [].extend(comps?.comps_ro ?? []).extend(comps?.comps_rw ?? []).extend(comps?.comps_track ?? [])

  local function onChange(evt, eid, comp) {
    local entry = {}
    foreach (v in fullCompsList)
      entry[v[0]] <- compCtor(v[0], comp)

    watched.update(function(val) {val[eid] <- entry})
  }


  local function onDestroy(evt, eid, comp) {
    if (eid in watched.value)
      delete watched[eid]
  }

  return {
    onChange = onChange
    onInit = onChange
    onDestroy = onDestroy
  }
}

return {
  makeEcsHandlers = makeEcsHandlers
  defComp_ctor = defComp_ctor
}
 