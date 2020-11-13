local { TEAM_UNASSIGNED } = require("team")
local { logerr } = require("dagor.debug")
local string = require("string")
local {TEAM0_COLOR_FG, TEAM1_COLOR_FG, TEAM0_COLOR_FG_TR, TEAM1_COLOR_FG_TR} = require("ui/hud/style.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local { localPlayerTeam } = require("ui/hud/state/local_player.nut")
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {lerp} = require("std/math.nut")
local capzone_images = require("capzone_images.nut")
local { capZones } = require("enlisted/ui/hud/state/capZones.nut")

/*
TODO: this is not optimal as we rebuild complicate ui of zone widget on ANY zone changes
better to accpet state to watch on and map zones state to zone states
*/
local ZONE_TEXT_COLOR = Color(80,80,80,20)
local ZONE_BG_COLOR = Color(60, 60, 60, 60)

local NEUTRAL_TRANSP = Color(80,80,80,80)
local INACTIVATED_ZONE_FG = Color(160, 150, 120)
local CAPTURE_ZONE_BG = Color(80, 75, 50, 160)

local ZoneProgress = {
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture("ui/skin#circle_progress")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}

local ZoneDefendProgress = {
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture("!ui/skin#icon_defend")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}

local function getCapZoneColors(capzone_data, heroTeam, bright = false) {
  local colorFg = null
  local colorBg = null
  if (capzone_data.capTeam == TEAM_UNASSIGNED || capzone_data.progress == 0.0) {
    if (!capzone_data.active && capzone_data.wasActive) {
      colorFg = INACTIVATED_ZONE_FG
      colorBg = CAPTURE_ZONE_BG
    } else if (bright) {
      colorFg = Color(160, 160, 160)
      colorBg = Color(160, 160, 160)
    } else {
      colorFg = NEUTRAL_TRANSP
      colorBg = NEUTRAL_TRANSP
    }
  } else if (capzone_data.capTeam == heroTeam) {
    colorFg = capzone_data.active ? TEAM0_COLOR_FG : TEAM0_COLOR_FG_TR
    colorBg = CAPTURE_ZONE_BG
  } else {
    colorFg = capzone_data.active ? TEAM1_COLOR_FG : TEAM1_COLOR_FG_TR
    colorBg = CAPTURE_ZONE_BG
  }
  return { fg = colorFg, bg = colorBg }
}

local mkDrawCapCountText = @(text, color, fontSize) {
  text = text
  rendObj = ROBJ_DTEXT
  fontSize = fontSize
  color = color
  size = SIZE_TO_CONTENT
}

local function getCapZonePersoneCountText(teamPresence, heroTeam, fontSize) {
  local alliesCount = 0
  local enemiesCount = 0
  foreach(teamId, soldierCount in teamPresence) {
    if (teamId.tointeger() == heroTeam) {
      alliesCount = soldierCount
    } else {
      enemiesCount = soldierCount
    }
  }
  return [
      mkDrawCapCountText($"{alliesCount}", TEAM0_COLOR_FG_TR, fontSize)
      mkDrawCapCountText($"/", ZONE_TEXT_COLOR, fontSize)
      mkDrawCapCountText($"{enemiesCount}", TEAM1_COLOR_FG_TR, fontSize)
  ]
}

local baseZoneAppearAnims = [
  { prop=AnimProp.scale, from=[2.5,2.5], to=[1,1], duration=0.4, play=true}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true}
]

local highlightScale = [3,3]
local transformCenterPivot = {pivot = [0.5, 0.5]}

local animActive = [
  { prop=AnimProp.scale, from=[7.5,7.5], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.translate, from=[0,sh(20)], to=[0,0], duration=0.4, play=true, easing=OutQuart}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true}
]

local animCapturing = [
  { prop=AnimProp.opacity, from=0.1, to=1.0, duration=1.0, play=true, loop=true, easing=CosineFull}
]

local defZoneBaseSize = [hdpx(24), hdpx(24)]

local defaultCorrect = @(fontSize) [fontSize*0.04+1, fontSize*0.05]
local lettersCorrection = {
  B = defaultCorrect,
  D = defaultCorrect,
  F = defaultCorrect,
  [fa["forward"]] = @(fontSize) [fontSize*0.12+1, fontSize*0.08],
  [fa["shield"]] = @(fontSize) [0, fontSize*0.12],
  [fa["close"]] = @(fontSize) [0, fontSize*0.14],
  [fa["check"]] = @(fontSize) [0, fontSize*0.2],
}
local function mkPosOffsetForLetterVisPos(letter, fontSize){
// we need psychovisual correction for centered letters - B is not percepted as in the center when it is in the center
  return lettersCorrection?[letter](fontSize) ?? [0, fontSize*0.05]
}

local function zoneBase(text_params={}, params={}) {
  local text = text_params?.text
  local fontSize = (params?.size ?? defZoneBaseSize)[1] * 0.8
  local color = params?.color ?? ZONE_TEXT_COLOR
  local children = {
    rendObj = ROBJ_STEXT
    fontSize = fontSize
    color = color
    pos = mkPosOffsetForLetterVisPos(text, fontSize)
    animations = params?.animAppear ?? baseZoneAppearAnims
    transform = transformCenterPivot
  }.__update(text_params)
  return {
    transform = transformCenterPivot
    size = SIZE_TO_CONTENT
    halign  = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }
}

local function zoneFontAwesome(symbol, params) {
  return zoneBase({
    text = fa[symbol]
    padding = [0,0,hdpx(2)]
    font = Fonts.fontawesome
    valign = ALIGN_CENTER
    key = symbol
  }, params)
}

local getPicture = ::memoize(function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  local imagename = null
  if (name.indexof("/") != null) {
    imagename = string.endswith(name,".svg") ? "{0}:{1}:{1}:K".subst(name, iconSz.tointeger()) : name
  } else if (name in capzone_images) {
    imagename = "{0}:{1}:{1}:K".subst(capzone_images[name], iconSz.tointeger())
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

local function capzoneCtor(zoneData, params={}) {
  if (zoneData == null || (!zoneData.wasActive && !zoneData.alwaysShow))
    return { ui_order = zoneData?.ui_order ?? 0 }

  local size = params?.size ?? [sh(3), sh(3)]
  local canHighlight = params?.canHighlight ?? true
  local highlight = canHighlight && zoneData.active
    && (zoneData.heroInsideEid != INVALID_ENTITY_ID && zoneData.heroInsideEid == params?.watchedHeroEidV)
  local animAppear = params?.animAppear

  local highlightedSize = highlight ? [size[0] * highlightScale[0], size[1] * highlightScale[1]] : size
  local iconSz = [highlightedSize[0] / 1.5, highlightedSize[1] / 1.5]
  local blur_back = ("customBack" in params) ? params.customBack(highlightedSize[1])
    : (params?.useBlurBack ?? true) ? capzonBlurback(highlightedSize[1])
    : capzonDarkback(highlightedSize[1])
  local zoneToCaptureIcon = zoneFontAwesome("shield",
    { size = iconSz, color = TEAM1_COLOR_FG, animAppear = animAppear })
  local zoneCapturedIcon = zoneFontAwesome("check",
    { size = iconSz, color = TEAM0_COLOR_FG, animAppear = animAppear })
  local zoneToDefendIcon = zoneFontAwesome("shield",
    { size = iconSz, color = TEAM0_COLOR_FG, animAppear = animAppear })
  local zoneFailedIcon = zoneFontAwesome("close",
    { size = iconSz, color = TEAM1_COLOR_FG, animAppear = animAppear })

  local heroTeam = params?.heroTeam ?? INVALID_ENTITY_ID
  local color = getCapZoneColors(zoneData, heroTeam)

  local isDefendZone = zoneData.only_team_cap > -1 && zoneData.only_team_cap != heroTeam
  local isAttackZone = zoneData.only_team_cap > -1 && zoneData.only_team_cap == heroTeam

  local zoneIcon = null
  local progress = 0
  if (zoneData.progress >= 1.0)
    progress = 1
  else if (zoneData.progress > 0.0)
    progress = lerp(0, 1, 0.015, 0.985, zoneData.progress)

  local zoneIconPic = getPicture(zoneData?.icon, iconSz[0])
  if (zoneIconPic) {
    zoneIcon = {
      rendObj = ROBJ_IMAGE
      size = iconSz
      halign  = ALIGN_CENTER
      valign = ALIGN_CENTER
      color = Color(125,125,125,125)
      transform = transformCenterPivot
      image = zoneIconPic
      animations = animAppear ?? baseZoneAppearAnims
    }
  }

  local zoneGeneric = ZoneProgress.__merge({
    size = highlightedSize
    transform = transformCenterPivot
    bgColor = color.bg
    fgColor = color.fg
    fValue = progress
  })

  local zoneCapturing = zoneGeneric.__merge({
    bgColor = CAPTURE_ZONE_BG
    fgColor = (zoneData.curTeamCapturingZone == heroTeam) ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
    animations = zoneData.isCapturing ? animCapturing : []
    key = {a=zoneData.isCapturing, b=zoneData.curTeamCapturingZone, c=zoneData?.active, d=zoneData?.wasActive}
  })

  local zoneCommonProgress = zoneGeneric.__merge({
    children = [
      zoneData.isCapturing ? zoneCapturing : null,
      zoneBase({text=zoneData.title, font=Fonts.huge_text}, { size = iconSz, animAppear = animAppear })
    ]
  })

  local zoneDefendProgressCapturing = ZoneDefendProgress.__merge({
    size = highlightedSize
    transform = transformCenterPivot
    bgColor = CAPTURE_ZONE_BG
    fgColor = (zoneData?.active) ? (zoneData.capTeam == heroTeam) ? TEAM0_COLOR_FG : TEAM1_COLOR_FG : color.fg
    fValue = progress
  })

  local zoneDefendProgress = zoneDefendProgressCapturing.__merge({
    size = highlightedSize
    transform = transformCenterPivot
    children = [
      zoneData.isCapturing
        ? zoneDefendProgressCapturing.__merge({
            animations = animCapturing
            bgColor = (zoneData.curTeamCapturingZone == heroTeam) ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
            transform = transformCenterPivot
          })
        : null
      zoneBase({text=zoneData.title, font=Fonts.huge_text}, { size = iconSz, animAppear = animAppear })
    ]
  })

  local zoneNotActive = {
    size = highlightedSize
    transform = transformCenterPivot
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = (zoneIcon && !isAttackZone && !isDefendZone) ? zoneIcon
      : isAttackZone ? (zoneData.capTeam == heroTeam ? zoneCapturedIcon : zoneToCaptureIcon)
      : isDefendZone ? (zoneData.capTeam > 0 && zoneData.capTeam != heroTeam ? zoneFailedIcon : zoneToDefendIcon)
      : null
  }

  local zoneProgress = zoneNotActive
  if (zoneData?.active) {
    if (!isDefendZone)
      zoneProgress = zoneCommonProgress
    else
      zoneProgress = zoneDefendProgress
  }

  local zoneCaption = {
    rendObj = ROBJ_DTEXT
    text = ::loc(zoneData.caption)
    fontSize = size[0] / 1.7
    color = ZONE_TEXT_COLOR
    size = SIZE_TO_CONTENT
    halign  = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    animations = animAppear ?? baseZoneAppearAnims
  }

  local zoneTeamCaptionInfo = {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    animations = animAppear ?? baseZoneAppearAnims
    children = getCapZonePersoneCountText(zoneData.presenceTeamCount, heroTeam, size[0] * 1.5)
  }

  local margin = params?.margin ?? (size[0] / 1.5).tointeger()
  local total = (params?.total ?? 0).tofloat()
  local idx = (params?.idx ?? 0).tofloat()
  local hlCenteredOffset = [((total - 1.0) * 0.5 - idx) * (size[0] + margin), size[1] + highlightedSize[1] * 0.5]
  local innerZone = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        halign  = ALIGN_CENTER
        valign = ALIGN_CENTER
        size = highlightedSize
        children = [
          blur_back
          zoneProgress
          zoneData?.active ? zoneIcon : null
        ]
      }
      highlight ? zoneTeamCaptionInfo : null
      highlight ? zoneCaption : null
    ]
    transform = {
      translate = highlight ? hlCenteredOffset : [0, 0]
    }
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
  if (zoneData?.active) {
    local ownTeamId = "team{0}".subst(zoneData?.owningTeam)
    if (ownTeamId in zoneData?.ownTeamIcon)
      zoneProgress.__update({
        image = ::Picture("{0}:{1}:{1}:K".subst(zoneData?.ownTeamIcon[ownTeamId], highlightedSize[0].tointeger()))
        color = ZONE_BG_COLOR
      })
    zone_animations.extend(params?.animActive ?? animActive)
  }
  innerZone.animations <- zone_animations

  return zone
}

local function capzoneWidget(zoneEid, params={}) {
  local zoneWatch = ::Computed(@() capZones.value?[zoneEid])
  return @() capzoneCtor(zoneWatch.value, params.__merge({ watchedHeroEidV = watchedHeroEid.value, heroTeam = localPlayerTeam.value }))
    .__update({ watch = [zoneWatch, watchedHeroEid, localPlayerTeam] })
}

local function captureZoneGap(params = {}) {
  local size = params?.size ?? [sh(3), sh(3)]
  local margin = (size[0] / 1.5).tointeger()
  return { margin = [0, margin] }
}

return {
  capzoneCtor = capzoneCtor
  capzoneWidget = capzoneWidget
  capzoneGap = captureZoneGap
}
 