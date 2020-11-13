local fontIconButton = require("enlist/components/fontIconButton.nut")
local { note } = require("enlisted/enlist/components/defcomps.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local {
  mkCardText, mkSquadCard, squadBgColor, mkSquadIcon, mkSquadTypeIcon, mkSquadPremIcon
} = require("components/squadsUiComps.nut")
local {
  bigPadding, smallPadding, blurBgFillColor, blurBgColor, squadSlotHorSize,
  multySquadPanelSize, listCtors
} = require("enlisted/enlist/viewConst.nut")
local { makeVertScroll, thinStyle } = require("ui/components/scrollbar.nut")
local { getItemName } = require("enlisted/enlist/soldiers/itemsInfo.nut")

local squadIconSize = [::hdpx(60), ::hdpx(60)]
local squadTypeIconSize = [::hdpx(20), ::hdpx(20)]

local curDropData = Watched(null)
local curDropTgtIdx = Watched(-1)
curDropData.subscribe(@(v) curDropTgtIdx(-1))

local getMoveDirSameList = @(idx, dropIdx, targetIdx)
  dropIdx < idx && targetIdx >= idx ? -1
    : dropIdx > idx && targetIdx <= idx ? 1
    : 0

local function squadDragAnim(idx, fixedSlots, stateFlags, content, chContent) {
  local watch = content?.watch ?? []
  if (typeof watch != "array")
    watch = [watch]
  watch.append(curDropData, curDropTgtIdx)

  local dropIdx = curDropData.value?.squadIdx ?? -1
  local targetIdx = curDropTgtIdx.value
  local moveDir = 0
  if (targetIdx >= 0 && dropIdx >= 0)
    if (idx < fixedSlots)
      moveDir = dropIdx < fixedSlots && targetIdx < fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx) : 0
    else
      moveDir = dropIdx >= fixedSlots && targetIdx >= fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx)
        : dropIdx < fixedSlots && targetIdx >= fixedSlots && targetIdx <= idx ? 1
        : 0

  return content.__update({
    watch = watch
    behavior = Behaviors.DragAndDrop
    xmbNode = ::XmbNode()
    canDrop = @(data) data?.dragid == "squad"
    dropData = "dropData" in content ? content.dropData : { squadIdx = idx, dragid = "squad" }
    onDragMode = @(on, data) curDropData(on ? data : null)
    onElemState = function(sf) {
      stateFlags(sf)
      if (!curDropData.value || curDropData.value.squadIdx == idx)
        return
      if (sf & S_ACTIVE)
        curDropTgtIdx(idx)
      else if (curDropTgtIdx.value == idx)
        curDropTgtIdx(-1)
    }
    transform = {}
    children = chContent.__update({
      transform = idx == dropIdx ? {} : { translate = [0, moveDir * squadSlotHorSize[1]] }
      transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = OutQuad }]
    })
  })
}

local bonusText = @(val) "+{0}%".subst((100 * val).tointeger())

local mkHorizontalSlot = ::kwarg(function (guid, squadId, idx, onClick, manageLocId,
  isSelected = Watched(false), onInfoCb = null, onDropCb = null, group = null,
  icon = "", squadType = "", level = 0, vehicle = null, squadSize = null, battleExpBonus = 0,
  isOwn = true, fixedSlots = -1, override = {}, premIcon = null, isLocked = false, unlocObj = null
) {
  local stateFlags = ::Watched(0)
  local function onDrop(data) {
    onDropCb?(data?.squadIdx, idx)
  }
  local isDropTarget = ::Computed(@() idx < fixedSlots && curDropTgtIdx.value == idx
    && (curDropData.value?.squadIdx ?? -1) >= fixedSlots)

  return function() {
    local sf = stateFlags.value
    local selected = isSelected.value
    local watch = [isSelected, stateFlags, isDropTarget]
    local bgColor = squadBgColor(sf, selected || isDropTarget.value, isLocked)
    local chContent = {
      key = $"slot{guid}{idx}"
      size = flex()
      opacity = isOwn ? 1.0 : 0.5
      flow = FLOW_HORIZONTAL
      transform = {}
      children = [
        {
          rendObj = ROBJ_SOLID
          flow = FLOW_HORIZONTAL
          size = flex()
          valign = ALIGN_CENTER
          color = bgColor
          margin = [0, 0, bigPadding, 0]
          children = [
            mkSquadIcon(icon).__update({ size = squadIconSize, margin = bigPadding })
            {
              size = flex()
              flow = FLOW_VERTICAL
              valign = ALIGN_CENTER
              gap = smallPadding
              clipChildren = true
              children = [
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  group = group
                  behavior = Behaviors.Marquee
                  scrollOnHover = true
                  flow = FLOW_HORIZONTAL
                  children = [
                    mkSquadPremIcon(premIcon, { margin = [0, ::hdpx(5), 0, ::hdpx(2)] })
                    mkCardText(::loc(manageLocId), sf, selected)
                  ]
                }
                {
                  size = SIZE_TO_CONTENT
                  flow = FLOW_HORIZONTAL
                  valign = ALIGN_BOTTOM
                  children = [
                    mkSquadTypeIcon(squadType, sf, selected, squadTypeIconSize)
                    premIcon == null
                      ? mkCardText(::loc("levelInfo", { level = level + 1 }), sf, selected)
                      : mkCardText("".concat(::loc("XP"), ::loc("ui/colon"), bonusText(battleExpBonus)),
                        sf, selected)
                    mkCardText(", {0} ".subst(::loc("squad/contain")), sf, selected)
                    mkCardText(squadSize, sf, selected)
                    mkCardText(fa["user-o"], sf, selected).__update({
                      rendObj = ROBJ_STEXT
                      font = Fonts.fontawesome
                      fontSize = hdpx(12)
                    })
                    vehicle == null
                      ? null
                      : mkCardText($", {::loc("menu/vehicle")} {getItemName(vehicle)}", sf, selected)
                  ]
                }
              ]
            }
            unlocObj
          ]
        }
        onInfoCb != null
          ? {
              size = [ph(100), flex()]
              padding = [0,0,bigPadding,0]
              stopHover = true
              children = [
                {
                  rendObj = ROBJ_SOLID
                  color = bgColor
                  size = flex()
                }
                fontIconButton("info", {
                  onClick = function() {
                    onInfoCb(squadId)
                  }
                  margin = 0
                  size = flex()
                  iconColor = @(sflag) sflag & S_ACTIVE ? Color(110,110,220)
                    : sflag & S_HOVER ? Color(90,90,200)
                    : Color(110,110,160)
                }.__update(override))
              ]
            }
          : null
      ]
    }

    return onDropCb != null
      ? squadDragAnim(idx, fixedSlots, stateFlags,
          {
            watch = watch
            group = group
            size = squadSlotHorSize
            key = $"{guid}{idx}"
            onDrop = onDrop
            onClick = onClick
          }.__update(override),
          chContent)
      : {
          watch = watch
          group = group
          size = squadSlotHorSize
          onClick = onClick
        }.__update({
          behavior = Behaviors.Button
          onElemState = @(sf) stateFlags(sf)
          transform = {}
          children = chContent
        })
  }
})

local mkEmptyHorizontalSlot = ::kwarg(
  function(idx, onDropCb, fixedSlots = -1, group = null, hasBlink = false) {
    local stateFlags = ::Watched(0)
    local isDropTarget = ::Computed(@() idx < fixedSlots && curDropTgtIdx.value == idx
      && (curDropData.value?.squadIdx ?? -1) >= fixedSlots)
    local onDrop = @(data) onDropCb(data?.squadIdx, idx)

    return function() {
      local chContent = {
        rendObj = ROBJ_SOLID
        key = $"empty_slot{idx}"
        size = flex()
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform = {}
        color = squadBgColor(0, isDropTarget.value)
        margin = [0, 0, bigPadding, 0]
        children = {
          key = $"hasBlink{hasBlink}"
          rendObj = ROBJ_DTEXT
          text = ::loc("squads/squadFreeSlot")
          font = Fonts.small_text
          color = hasBlink
            ? listCtors.nameColor(0, isDropTarget.value)
            : listCtors.txtDisabledColor(0, isDropTarget.value)
          animations = hasBlink
            ? [{
                prop = AnimProp.opacity, from = 0.4, to = 1,
                duration = 1, play = true, loop = true, easing = Blink
              }]
            : null
        }
      }
      return squadDragAnim(idx, fixedSlots, stateFlags,
        {
          watch = [stateFlags, isDropTarget]
          size = squadSlotHorSize
          key = $"empty_{idx}"
          onDrop = onDrop
          dropData = null
          fixedSlots = fixedSlots
          group = group
        },
        chContent)
    }
  })

local defSquadCardCtor = @(squad, idx) mkSquadCard({idx = idx}.__update(squad))

local mkSquadsVert = ::kwarg(@(squads, ctor = defSquadCardCtor, addedObj = null) {
  xmbNode = ::XmbContainer({
    canFocus = @() false
    scrollSpeed = 10.0
    isViewport = true
  })
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = squads.map(ctor).append(addedObj)
})

local mkCurSquadsList = ::kwarg(@(
  curSquadsList, curSquadId, addedObj = null, createHandlers = null, bottomObj = null, bgOverride = {}
) function() {
  local squadsList = curSquadsList.value ?? []
  bottomObj = ::type(bottomObj)=="array" ? bottomObj : [bottomObj]
  local function defCreateHandlers(squads){
    squads.each(@(squad, idx)
      squad.__update({
        onClick = @() curSquadId(squad.squadId)
        isSelected = ::Computed(@() curSquadId.value == squad.squadId)
      })
    )
  }
  createHandlers = createHandlers ?? defCreateHandlers
  createHandlers?(squadsList)
  local children = squadsList.len() < 1 ? [] : [
    note(::loc("squads/battle")).__update({ size = [multySquadPanelSize[0], SIZE_TO_CONTENT] })
    makeVertScroll(
      mkSquadsVert({
        squads = squadsList
        addedObj = addedObj
      }),
      { size = [SIZE_TO_CONTENT, flex()], styling = thinStyle })
  ]
  children = [].extend(children).extend(bottomObj)
  return {
    watch = [curSquadsList, curSquadId]
    size = [multySquadPanelSize[0] + 2 * bigPadding, flex()]
    flow = FLOW_VERTICAL
    padding = [bigPadding, 0]
    halign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    fillColor = blurBgFillColor
    children = [
      {
        size = [SIZE_TO_CONTENT, flex()]
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = children
      }
    ]
  }.__merge(bgOverride)
})

return {
  mkCurSquadsList
  mkHorizontalSlot
  mkEmptyHorizontalSlot
}
 