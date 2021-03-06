const UPGRADE_TEMPLATE_SUFFIX = "_upgrade_"

local mkIcon3d = require("ui/hud/components/icon3d.nut")
local itemsPresentation = require("enlisted/globals/itemsPresentation.nut")

local function getIconInfoByGameTemplate(template, params = {}){
  local reassign = @(value, key) key in params ? params[key] : value
  return {
    iconName = template.getCompValNullable("animchar.res")
    iconPitch = reassign(template.getCompValNullable("item.iconPitch"), "itemPitch")
    iconYaw = reassign(template.getCompValNullable("item.iconYaw"), "itemYaw")
    iconRoll = reassign(template.getCompValNullable("item.iconRoll"), "itemRoll")
    iconOffsX = reassign(template.getCompValNullable("item.iconOffset")?.x, "itemOfsX")
    iconOffsY = reassign(template.getCompValNullable("item.iconOffset")?.y, "itemOfsY")
    iconScale = reassign(template.getCompValNullable("item.iconScale"), "itemScale")
  }
}

local function getItemNameByGameTemplate(template) {
  if (template == null)
    return null

  local gametemplate = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  return gametemplate != null ? ::loc(gametemplate.getCompValNullable("item.name")) : null
}

local getItemName = @(item)
  getItemNameByGameTemplate(item?.gametemplate) ?? ::loc($"items/{item?.name ?? ""}")

// works both with item instance or basetpl string value
local function getItemDesc(item) {
  item = typeof item == "table" ? item?.basetpl : item
  if (typeof item != "string")
    return ""
  local tmplEnd = item.indexof(UPGRADE_TEMPLATE_SUFFIX)
  item = tmplEnd != null ? item.slice(0, tmplEnd) : item
  return ::loc($"items/{item}/desc", "")
}

local getItemTypeName = @(item) ::loc($"itemtype/{item?.itemtype ?? ""}")

local function iconByGameTemplate(gametemplate, params = {}){
  if (gametemplate == null)
    return null
  local template = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(gametemplate)
  if (template == null)
    return null
  local itemInfo = getIconInfoByGameTemplate(template, params)
  return mkIcon3d(itemInfo, params)
}

local defIconSize = ::hdpx(64).tointeger()
local function mkIcon(presentation, params = {}) {
  local { opacity = 1.0, hplace = null, vplace = null } = params
  local width = (params?.width ?? defIconSize).tointeger()
  local height = (params?.height ?? defIconSize).tointeger()
  local { icon, color = 0xFFFFFFFF } = presentation
  return {
    rendObj = ROBJ_IMAGE
    size = [width, height]
    keepAspect = true
    image = ::Picture(icon.slice(-4) == ".svg" ? $"{icon}:{width}:{height}:K" : $"{icon}?Ac")
    hplace
    vplace
    opacity
    color
  }
}

local iconByItem = @(item, params) item?.basetpl in itemsPresentation
  ? mkIcon(itemsPresentation[item.basetpl], params)
  : iconByGameTemplate(item?.gametemplate, params)

local function getObjectName(obj) {
  local { name = null, surname = null } = obj
  return name == null ? getItemTypeName(obj)
    : surname == null ? getItemName(obj)
    : " ".join([::loc($"name/{name}", name), ::loc($"surname/{surname}", surname)])
}

return {
  getIconInfoByGameTemplate = getIconInfoByGameTemplate
  iconByGameTemplate = iconByGameTemplate
  getItemNameByGameTemplate = getItemNameByGameTemplate
  iconByItem = iconByItem
  getItemName = getItemName
  getItemDesc = getItemDesc
  getItemTypeName = getItemTypeName
  getObjectName = getObjectName
}
 