local {hudIsInteractive} = require("state/interactive_state.nut")
local { logerr } = require("dagor.debug")
/*
  this better be two classes
    - MenuItem {id=string, show=?Watched, event=?string, menu=dargComponent, group=int} (plus may be onLeave, onEnter, canEnter)
    - HUDMenus with openMenu, addMenu, toggleMenu, closeMenu, replaceMenu, setMenus methods and menus (orderedDict alike) value
*/
local hudMenus = ::Watched([])
hudMenus.subscribe(function(menus){
  local ids = menus.map(@(v) v.id)
  local set = {}
  foreach (id in ids){
    assert(!(id in set), @() $"menu with id {id} is already in list!")
    set.id <- true
  }
})
/*
Example: inventory.group = 3, chatInput.group = 4, pieMenu.group = 5
case 1
  requested: piemenu(5), opened: chat(4)
  result = nothing
case 2
  requested: inventory(3), opened: piemenu (4)
  result = piemenu closed, inventory opened
*/

local function closeMenu_int(menu){
  if ("close" in menu)
    menu.close()
  else
    menu.show(false)
}

local function openMenu_int(menu, menusDescr){
  local requestedMenuGroup = menu?.group ?? 100
  local curOpenMenus = []
  foreach (other in menusDescr) {
    if (!other?.show.value || other.id == menu.id)
      continue
    local foundGroup = (other?.group ?? 100)
    if (requestedMenuGroup > foundGroup)
      return
    curOpenMenus.append(other)
  }
  if (menu?.open != null)
    menu.open()
  else
    menu.show(true)
  curOpenMenus.each(@(v) closeMenu_int(v))
}
local function closeMenu(id){
  local menusDescr = hudMenus.value
  local menu = menusDescr.findvalue(@(v) v.id == id)
  closeMenu_int(menu)
}

local function openMenu(id){
  local menusDescr = hudMenus.value
  local menu = menusDescr.findvalue(@(v) v.id == id)
  openMenu_int(menu, menusDescr)
}

local function setMenuVisibility(id, isVisible){
  local menusDescr = hudMenus.value
  local menu = menusDescr.findvalue(@(v) v.id == id)
  if (isVisible)
    openMenu_int(menu, menusDescr)
  else
    closeMenu_int(menu)
}

local function switchMenu(id){
  local menusDescr = hudMenus.value
  local menu = menusDescr.findvalue(@(v) v.id == id)
  if (!menu.show.value){
    openMenu_int(menu, menusDescr)
  }
  else
    closeMenu_int(menu)
}

local function replaceHudMenu(menu, id){
  hudMenus(function(menus) {
    local m = menus.findvalue(@(v) v?.id==id)
    if (m)
      m.menu <- menu
    else
      logerr($"no id = {id} in menus found on replace")
  })
}

local function addHudMenu(menuDescr, id=null, after=false, idx = null){
  assert(menuDescr?.id && menuDescr?.show && menuDescr?.group)
  hudMenus(function(menus) {
    idx = id != null ? menus.findindex(@(v) v?.id==id) : (idx ?? 0)
    if (idx != null)
      menus.insert(after ? idx+1 : idx, menuDescr)
    else
      logerr($"no id = {id} in menus found, {after}, {idx}")
  })
}
local function removeHudMenu(id){
  hudMenus(function(menus) {
    local idx = menus.findindex(@(v) v?.id==id)
    if (idx)
      menus.remove(idx)
  })
}

local function mkMenuEventHandlers(menu) {
  local eventName = menu?.event
  local holdToToggleDurMsec = menu?.holdToToggleDurMsec ?? 500
  if (!( menu?.show instanceof ::Watched) && !("close" in menu && "open" in menu))
    return {}

  local function endEvent(event){
    if ((event?.dur ?? 0) > holdToToggleDurMsec || event?.appActive==false)
      closeMenu_int(menu)
  }
  return {
    [eventName] = @(event) switchMenu(menu.id),
    [$"{eventName}:end"] = endEvent
  }
}

local function menusUi() {
  local watch = [hudMenus, hudIsInteractive]
  local children = []
  local eventHandlers = {}

  local menus_descr = hudMenus.value ?? []
  foreach (menu in menus_descr) {
    if (menu?.event != null) {
      eventHandlers.__update(mkMenuEventHandlers(menu))
    }
    if (menu?.show instanceof ::Watched) {
      watch.append(menu.show)
      if (menu?.show?.value)
        children.append(menu?.menu)
    } else {
      children.append(menu?.menu)
    }
  }

  return {
    size = flex()
    watch = watch
    children = children
    eventHandlers = eventHandlers
  }
}

return {
  hudMenus = hudMenus
  replaceHudMenu = replaceHudMenu
  addHudMenuBefore = @(menu, id) addHudMenu(menu, id)
  addHudMenuAfter = @(menu, id) addHudMenu(menu, id, true)
  insertHudMenu = @(menu, idx=0) addHudMenu(menu, null, false, idx)
  removeHudMenu = removeHudMenu
  openMenu = openMenu
  closeMenu = closeMenu
  setMenuVisibility = setMenuVisibility
  switchMenu = switchMenu
  menusUi = menusUi
}
 