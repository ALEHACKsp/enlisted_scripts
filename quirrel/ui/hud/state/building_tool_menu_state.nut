local buildingToolMenuItems = persist("items", @()::Watched([]))
local radius = ::hdpx(365)

local showBuildingToolMenu = persist("showBuildingToolMenu", @() ::Watched(false))
local openPath = persist("openPath", @() ::Watched([]))
local path = persist("path", @() ::Watched([]))

local mkNextPathItem = @(item) item.__merge({
  text = ::loc(item?.id ?? "")
  closeOnClick = false
  action = @() path(@(p) p.append(item?.id ?? ""))
  available = ::Watched(true)
})

local curBuildingToolMenuItems = ::Computed(function() {
  local list = buildingToolMenuItems.value
  foreach(id in path.value) {
    list = list.findvalue(@(p) p?.id == id)?.items
    if (::type(list) != "array")
      return [] //no items by path
  }
  return list.map(@(item) ::type(item?.items) == "array" ? mkNextPathItem(item) : item)
})

openPath.subscribe(@(v) path(clone v))
showBuildingToolMenu.subscribe(@(v) v ? null : openPath([]))

return {
  buildingToolMenuItems = buildingToolMenuItems
  openBuildingToolMenuPath = openPath
  buildingToolMenuPath = path
  radius = ::Watched(radius)
  elemSize = ::Watched([(radius*0.35).tointeger(),(radius*0.35).tointeger()])
  showBuildingToolMenu = showBuildingToolMenu
  curBuildingToolMenuItems = curBuildingToolMenuItems
}
 