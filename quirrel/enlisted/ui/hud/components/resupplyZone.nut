local { logerr } = require("dagor.debug")
local string = require("string")

local ZONE_ICON_COLOR = Color(200,200,200,200)

local baseZoneAppearAnims = [
  { prop=AnimProp.scale, from=[2.5,2.5], to=[1,1], duration=0.4, play=true}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true}
]

local transformCenterPivot = {pivot = [0.5, 0.5]}

local animActive = [
  { prop=AnimProp.scale, from=[7.5,7.5], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.translate, from=[0,sh(20)], to=[0,0], duration=0.4, play=true, easing=OutQuart}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true}
]

local getPicture = ::memoize(function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  local imagename = null
  if (name.indexof("/") != null) {
    imagename = string.endswith(name,".svg") ? "{0}:{1}:{1}:K".subst(name, iconSz.tointeger()) : name
  }

  if (!imagename) {
    logerr("no image found")
    return null
  }

  return ::Picture(imagename)
}, @(name, iconSz) "".concat(name, iconSz))

local capzonBlurback = ::memoize(@(height) {
    size = [height, height]
    rendObj = ROBJ_MASK
    image = ::Picture("ui/uiskin/white_circle.png?Ac")
    children = [{size = flex() rendObj = ROBJ_WORLD_BLUR_PANEL color = Color(220, 220, 220, 255)}]
  })

local capzonDarkback = ::memoize(@(height) {
    size = [height, height]
    rendObj = ROBJ_IMAGE
    image = ::Picture("ui/uiskin/white_circle.png?Ac")
    color = Color(0, 0, 0, 120)
  })

local function resupplyZoneCtor(zoneData, params={}) {
  if (zoneData == null)
    return { ui_order = zoneData?.ui_order ?? 0 }

  local size = params?.size ?? [sh(3), sh(3)]
  local animAppear = params?.animAppear

  local iconSz = [size[0] / 1.5, size[1] / 1.5]
  local blur_back = ("customBack" in params) ? params.customBack(size[1])
    : (params?.useBlurBack ?? true) ? capzonBlurback(size[1])
    : capzonDarkback(size[1])

  local zoneIcon = null

  local zoneIconPic = getPicture(zoneData?.icon, iconSz[0])
  if (zoneIconPic) {
    zoneIcon = {
      rendObj = ROBJ_IMAGE
      size = iconSz
      halign  = ALIGN_CENTER
      valign = ALIGN_CENTER
      color = ZONE_ICON_COLOR
      transform = transformCenterPivot
      image = zoneIconPic
      animations = animAppear ?? baseZoneAppearAnims
    }
  }

  local margin = params?.margin ?? (size[0] / 1.5).tointeger()
  local innerZone = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        halign  = ALIGN_CENTER
        valign = ALIGN_CENTER
        size = size
        children = [
          blur_back
          zoneData?.active ? zoneIcon : null
        ]
      }
    ]
    transitions = [{ prop=AnimProp.translate, duration=0.2 }]
  }

  local zone = {
    size = size
    margin = [0, margin]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    key = zoneData.eid

    zoneData = { zoneEid = zoneData.eid }
    children = [ innerZone ]

    ui_order = zoneData.ui_order
  }

  local zone_animations = innerZone?.animations ?? []
  if (zoneData?.active)
    zone_animations.extend(params?.animActive ?? animActive)
  innerZone.animations <- zone_animations

  return zone
}

return {
  resupplyZoneCtor = resupplyZoneCtor
}
 