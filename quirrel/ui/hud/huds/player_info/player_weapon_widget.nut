local style = require("ui/hud/style.nut")
local { blurBack } = require("style.nut")
local iconWidget = require("ui/hud/components/icon3d.nut")

local ammoColor = Color(100,100,100,50)
local curColor = Color(180,200,230,180)
local color = Color(168,168,168,150)
local curBorderColor = style.SELECTION_BORDER_COLOR
local nextBorderColor = Color(200, 200, 200, 100)


local function itemAppearing(duration=0.2) {
  return {prop=AnimProp.opacity, from=0, to=1, duration=duration, play=true, easing=InOutCubic}
}
local wWidth = hdpx(280)
local wHeight = hdpx(40)


local function weaponId(weapon, params={width=flex() height=wHeight}) {
  local size = [params?.width ?? flex(), params?.height ?? wHeight]
  local name = weapon.name

  return {
    size = size
    padding= params?.padding ?? [0,0,hdpx(2),hdpx(2)]
    margin = params?.margin
    clipChildren = true
    children = {
      behavior = Behaviors.Marquee
      size = flex()
      valign = ALIGN_CENTER
      children = {
        size = SIZE_TO_CONTENT
        halign = ALIGN_LEFT
        rendObj = ROBJ_DTEXT
        font = Fonts.small_text
//        fontSize = size[1]/3
        text = ::loc(name)
        fontFx = FFT_BLUR
        fontFxColor = Color(0,0,0,30)
        key = name
        color = weapon?.isCurrent ? curColor : color
      }
    }
  }
}
local wAmmoDef = {width=SIZE_TO_CONTENT height=SIZE_TO_CONTENT}
local function weaponAmmo(weapon, params=wAmmoDef) {
  //note: no sense in having size, cause we do not have scalable DTEXT yet :(
  local size = [params?.width ?? SIZE_TO_CONTENT, params?.height ?? SIZE_TO_CONTENT]
  local curAmmo = weapon?.curAmmo ?? 0
  local totalAmmo = weapon?.totalAmmo ?? 0
  local instant = weapon?.instant
  local showZeroAmmo = weapon?.showZeroAmmo ?? false

  local ammo_string = (totalAmmo + curAmmo <= 0 && !showZeroAmmo) ? ""
    : instant ? (totalAmmo + curAmmo)
    : (weapon?.isReloadable ?? false) ? $"{curAmmo}/{totalAmmo}"
    : totalAmmo

  return {
    rendObj = ROBJ_DTEXT
    text = ammo_string
    color = weapon?.isCurrent ? curColor : ammoColor
    size = size
    clipChildren=true
    key = totalAmmo+curAmmo
    halign = params?.halign ?? ALIGN_RIGHT
    hplace = params?.hplace ?? ALIGN_RIGHT
    transform  = {pivot =[0.5,0.5]}
    margin = params?.margin ?? hdpx(5)
    animations = [
      { prop=AnimProp.scale, from=[1.1,1.3], to=[1,1], duration=0.2, play=true, easing=OutCubic }
    ]
  }
}


local silhouetteDefColor=[200,200,200,200]
local silhouetteEmptyColor=[0,0,0,120]
local silhouetteInactiveColor=[0,0,0,200]
local outlineDefColor=[0,0,0,0]
local outlineEmptyColor=[200,200,200,0]
local outlineInactiveColor=[200,200,200,0]

local weaponWidgetAnims = [
  {prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true}
  itemAppearing()
]

local function iconCtorDefault(weapon, width, height) {
  local isLoadable = (weapon?.maxAmmo ?? 0) > 0
  local isAmmoLoaded = (!isLoadable || (weapon?.curAmmo ?? 0) > 0)
  return iconWidget(weapon, {
    width = width
    height = height
    hplace = ALIGN_CENTER
    shading = "silhouette"
    silhouette = isAmmoLoaded ? silhouetteDefColor : silhouetteEmptyColor
    outline = isLoadable ? outlineDefColor : outlineEmptyColor
    silhouetteInactive = silhouetteInactiveColor
    outlineInactive = outlineInactiveColor
  })
}

local currentBorder = { size = flex(), rendObj = ROBJ_FRAME, borderWidth = 1, color = curBorderColor }
local nextBorder = { size = flex(), rendObj = ROBJ_FRAME, borderWidth = 1, color = nextBorderColor, key = {}
  animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1, play = true, loop = true, easing = CosineFull }] }

local function weaponWidget(weapon, hotkey = null, width = wWidth, height = wHeight, showHint = true, iconCtor = iconCtorDefault) {
  local markAsSelected = weapon?.isEquiping || (weapon?.isCurrent && !weapon?.isHolstering)
  local borderComp = markAsSelected ? currentBorder
    : weapon?.isNext ? nextBorder
    : null

  local weaponHudIcon = iconCtor(weapon, hdpx(128), height - ::hdpx(2) * 2)

  local controlHint = showHint ? hotkey : null
  local hintsPadding = (showHint ? wHeight + hdpx(2) : hdpx(2))
  return @() {
    size = [width,height]
    animations = weaponWidgetAnims
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = [width - hintsPadding, height]
        clipChildren = true
        children = [
          blurBack,
          borderComp,
          {
            size = [width-hintsPadding,height]
            clipChildren = true
            valign = ALIGN_CENTER
            children = (weapon?.name && weapon?.name!= "")
              ? [
                  {
                    size = flex()
                    padding=hdpx(2)
                    children = [
                      weaponHudIcon,
                      {
                        flow = FLOW_HORIZONTAL
                        size = flex()
                        valign = ALIGN_CENTER
                        children = [
                          weaponId(weapon, { size=[flex(),height/2]})
                          weaponAmmo(weapon, {width = SIZE_TO_CONTENT height=wHeight/2 hplace=ALIGN_RIGHT vplace = ALIGN_CENTER})
                        ]
                      }
                    ]
                  }
                ]
              : {size=flex()}
          }
        ]
      }
      showHint ? {size = flex(0.01) minWidth=hdpx(1)} : null
      controlHint
    ]
  }
}

return ::kwarg(weaponWidget)
 