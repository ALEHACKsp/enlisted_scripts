local pieMenuItems = persist("items", @()::Watched([]))
local radius = ::hdpx(365)

local showPieMenu = persist("showPieMenu", @() ::Watched(false))
local openPath = persist("openPath", @() ::Watched([]))
local path = persist("path", @() ::Watched([]))

local mkNextPathItem = @(item) item.__merge({
  text = ::loc(item?.id ?? "")
  closeOnClick = false
  action = @() path(@(p) p.append(item?.id ?? ""))
  available = ::Watched(true)
})

local curPieMenuItems = ::Computed(function() {
  local list = pieMenuItems.value
  foreach(id in path.value) {
    list = list.findvalue(@(p) p?.id == id)?.items
    if (::type(list) != "array")
      return [] //no items by path
  }
  return list.map(@(item) ::type(item?.items) == "array" ? mkNextPathItem(item) : item)
})

openPath.subscribe(@(v) path(clone v))
showPieMenu.subscribe(@(v) v ? null : openPath([]))

return {
  pieMenuItems = pieMenuItems
  openPieMenuPath = openPath
  pieMenuPath = path
  radius = ::Watched(radius)
  elemSize = ::Watched([(radius*0.35).tointeger(),(radius*0.35).tointeger()])
  showPieMenu = showPieMenu
  curPieMenuItems = curPieMenuItems
}
 