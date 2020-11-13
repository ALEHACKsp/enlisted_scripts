local math = require("math")
local { researchItemSize, defBgColor, airSelectedBgColor  } = require("enlisted/enlist/viewConst.nut")
local state = require("researchesState.nut")
local { researchStatuses, RESEARCHED, CAN_RESEARCH } = state
local { unseenResearches, markSeen } = require("unseenResearches.nut")
local hoverImage = require("enlist/components/hoverImage.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local { iconByGameTemplate } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local researchIcons = require("enlisted/globals/researchIcons.nut")

const REPAY_TIME = 0.3

local function bgHighLight(id) {
  local highlightSize = hdpx(220)
  local startRotation = math.rand() % 360
  return {
    size = [highlightSize, highlightSize]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    key = $"bgHighLight_{id}"
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = ::Picture("ui/open_flash")
        transform = { }
        transitions = hoverImage.transitions
        animations = [
          { prop = AnimProp.opacity, from = 0.8, to = 1, duration = 1,
            play = true, loop = true, easing = Blink },
          { prop = AnimProp.rotate, from = startRotation, to = startRotation + 360,
            duration = 47, play = true, loop = true }
        ]
      }
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = ::Picture("ui/open_flash")
        transform = { }
        transitions = hoverImage.transitions
        animations = [
          { prop = AnimProp.opacity, from = 0.8, to = 1,
            duration = 1, play = true, loop = true, easing = Blink},
          { prop = AnimProp.rotate, from = startRotation-180, to = startRotation + 180,
            duration = 97, play = true, loop = true }
        ]
      }
    ]
  }
}

local selectedResearchTarget = @(research_id, bgColor, width, height) function (){
  local res = { watch = state.selectedResearch }
  if (state.selectedResearch.value?.research_id != research_id)
    return res

  local size = (height * 1.5).tointeger()
  local imgSize = size > 256 ? 256 : size
  return res.__update({
    size = [size, size]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [0, ::hdpx(2)]
    rendObj = ROBJ_IMAGE
    image = ::Picture($"ui/skin#research_target_circle.svg:{imgSize}:{imgSize}:F")
    transform = { pivot = [0.5, 0.5]}
    animations = [
      {
        prop = AnimProp.scale, from = [0.1, 0.1], to = [1, 1], duration = 0.15,
        play = true, easing = OutQuad
      }
      {
        prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1, play = true,
        loop = true, easing = Blink
      }
    ]
    color = bgColor
  })
}

local RESEARCH_IMAGE_PARAMS = {
  imgName = ""
  color = Color(255, 255, 255, 255)
  size = researchItemSize
}

local function mkImageForResearch(params = {}) {
  params = RESEARCH_IMAGE_PARAMS.__merge(params)
  return {
    rendObj = ROBJ_IMAGE
    image = ::Picture("ui/skin#{2}.svg:{0}:{1}:K".subst(
      params.size[0].tointeger(), params.size[1].tointeger(), params.imgName))
  }.__update(params)
}

local unseen = unseenSignal()

local mkUnseen = @(isUnseen) @() {
  watch = isUnseen
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  pos = [0, hdpx(10)]
  children = isUnseen.value ? unseen : null
}

local mkCount = ::kwarg(function(squad_size = null, squad_class_limit = null) {
  local count = (squad_size ?? {}).reduce(@(res, val) res + val, 0)
  if (count <= 0)
    count = (squad_class_limit ?? {}).reduce(@(res, classList) res + classList.reduce(@(sum, val) sum + val, 0), 0)
  if (count <= 1)
    return null
  return {
    rendObj = ROBJ_SOLID
    padding = hdpx(4)
    color = defBgColor
    children = txt({
      text = $"+{count}"
      font = Fonts.big_text
    })
  }
})

local mkImageByIcon = ::kwarg(function(
  width, height, sf, uid, image, isDisabled = false, iconOverride = null
) {
  local size = min(width, height)
  local resized = size * (iconOverride?.scale ?? 1.0)
  local pos = iconOverride?.pos ?? [0, 0]
  local imageName = image.slice(-4) == ".svg"
    ? $"!{image}:{(size * 1.2).tointeger()}:{(size * 1.2).tointeger()}:K"
    : $"{image}?Ac"
  return hoverImage.create({
    sf = sf
    uid = uid
    size = [size, size]
    image = null
    pivot = [0.5, 0.9]
    children = {
      size = [resized, resized]
      rendObj = ROBJ_IMAGE
      image = image != null ? ::Picture(imageName) : null
      tint = isDisabled ? ::Color(120, 120, 120, 255) : null
      pos = [(size - resized) * pos[0],  (size - resized) * pos[1]]
    }
  })
})

local mkImageByTemplate = ::kwarg(function(
  width, height, sf, uid, templateId, isDisabled = false, templateOverride = null
) {
  local tmplParams = templateOverride ?? {}
  local size = min(width, height)
  local resized = size * (tmplParams?.scale ?? 1.0)
  tmplParams = tmplParams.__merge({
    width = size * 1.2
    height = size * 1.2
    shading = "silhouette"
    silhouette = isDisabled ? [30, 30, 30, 255] : [255, 255, 255, 255]
    outline = [0, 0, 0, 85]
  })
  local templateIcon = iconByGameTemplate(templateId, tmplParams)
  if (templateIcon == null)
    return null
  return hoverImage.create({
    sf = sf
    uid = uid
    size = [size, size]
    image = null
    pivot = [0.5, 0.9]
    children = templateIcon.__update({ size = [resized, resized] })
  })
})

local hoverCallBacks = {}
return function(armyId, researchDef, elemPosX, elemPosY) {
  local researchId = researchDef.research_id
  local status = ::Computed(@() researchStatuses.value?[researchId])
  local isUnseen = ::Computed(@() unseenResearches.value?[armyId][researchId] ?? false)

  local width = researchItemSize[0]
  local height = researchItemSize[1]
  local bgColor = state.tableStructure.value.pages[state.selectedTable.value].bg_color
  local darkedBgColor = ::mul_color(bgColor, 0.6) | 0xff000000
  local darkedStrokeColor = ::mul_color(bgColor, 0.85) | 0xff000000
  local stateFlags = Watched(0)

  local countComp = mkCount(researchDef?.effect)

  return function() {
    local researchStatus = status.value
    local iconImage = researchIcons?[researchDef?.icon_id]
    local templateId = researchDef?.gametemplate ?? ""
    local isDisabled = researchStatus != RESEARCHED && researchStatus != CAN_RESEARCH
    return {
      size = [width, height]
      pos = [elemPosX - 0.5 * width, elemPosY - 0.5 * height]
      watch = [status, stateFlags]

      children = [
        researchStatus == CAN_RESEARCH ? bgHighLight(researchDef) : null
        selectedResearchTarget(researchId, airSelectedBgColor, width, height)
        {
          pos = [0, hdpx(10)]
          key = researchId
          children = [
            mkImageForResearch({
              imgName = "research_shield_bg",
              color = researchStatus != RESEARCHED ? darkedBgColor : bgColor
            })
            mkImageForResearch({
              imgName = "research_shield_stroke_up",
              color = researchStatus != RESEARCHED ? darkedStrokeColor : null
            })
            templateId == "" ? null : mkImageByTemplate({
              width = width
              height = height
              sf = stateFlags.value
              uid = researchId
              templateId = templateId
              isDisabled = isDisabled
              templateOverride = researchDef?.templateOverride
            })
            iconImage == null ? null : mkImageByIcon({
              width = width
              height = height
              sf = stateFlags.value
              uid = researchId
              image = iconImage
              isDisabled = isDisabled
              iconOverride = researchDef?.iconOverride
            })
            mkImageForResearch({
              imgName = "research_shield_stroke_bottom",
              color = researchStatus != RESEARCHED ? darkedStrokeColor : null
            })
            mkImageForResearch({
              key = researchDef
              imgName = "research_shield_bg"
              behavior = Behaviors.Button
              xmbNode = ::XmbNode()
              sound = {
                hover = "ui/enlist/button_highlight"
                click = researchStatus == RESEARCHED ? null : "ui/enlist/button_click"
              }
              onClick = @() state.selectedResearch(researchDef)
              onHover = function(on) {
                if (!isUnseen.value)
                  return
                if (hoverCallBacks?[researchId]) {
                  ::gui_scene.clearTimer(hoverCallBacks[researchId])
                  delete hoverCallBacks[researchId]
                }
                if (on) {
                  hoverCallBacks[researchId] <- function() {
                    markSeen(armyId, [researchId])
                    delete hoverCallBacks[researchId]
                  }
                  ::gui_scene.setTimeout(REPAY_TIME, hoverCallBacks[researchId])
                }
              }
              onDetach = function() {
                if (isUnseen.value)
                  markSeen(armyId, [researchId])
              }
              opacity = 0
              onElemState = @(sf) stateFlags(sf)
            })
            countComp
          ]
        }
        mkUnseen(isUnseen)
      ]
    }
  }
}


 