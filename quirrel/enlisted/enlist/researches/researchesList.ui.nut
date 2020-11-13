local fa = require("daRg/components/fontawesome.map.nut")
local { txt, progressBar } = require("enlisted/enlist/components/defcomps.nut")
local { statusIconLocked } =  require("enlisted/style/statusIcon.nut")
local { ModalBgTint, TextHighlight } = require("ui/style/colors.nut")
local {buttonSound} = require("ui/style/sounds.nut")
local cursors = require("ui/style/cursors.nut")
local scrollbar = require("daRg/components/scrollbar.nut")
local colorize = require("enlist/colorize.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local armySelect = require("enlisted/enlist/soldiers/army_select.ui.nut")
local campaignTitle = require("enlisted/enlist/campaigns/campaign_title_small.ui.nut")
local { mkCurSquadsList } = require("enlisted/enlist/soldiers/mkSquadsList.nut")
local {
  bigPadding, smallPadding, bigGap, researchHeaderIconHeight, researchListTabBorder,
  researchListTabPadding, isWide, activeTxtColor, defTxtColor, multySquadPanelSize,
  tablePadding, researchItemSize, defBgColor
} = require("enlisted/enlist/viewConst.nut")
local {
  allSquadsPoints, viewArmy, armiesResearches, viewSquadId,
  closestTargets, selectedTable, tableStructure,
  selectedResearch, researchStatuses, curSquadPoints,
  curArmySquadsProgress, curSquadProgress, buySquadLevel,
  LOCKED, RESEARCHED, BALANCE_ATTRACT_TRIGGER
} = require("researchesState.nut")
local { researchToShow } = require("researchesFocus.nut")
local {
  mkActiveBlock, mkCardText, mkSquadPremIcon
} = require("enlisted/enlist/soldiers/components/squadsUiComps.nut")
local researchDetailsPopup = require("researchDetailsPopup.ui.nut")
local tableElement = require("researchTableElement.ui.nut")
local {
  playerSelectedArmy, curUnlockedSquads, armySquadsById, maxCampaignLevel
} = require("enlisted/enlist/soldiers/model/state.nut")
local { unseenResearches } = require("unseenResearches.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")
local blinkingIcon = require("enlisted/enlist/components/blinkingIcon.nut")
local { safeAreaSize, safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { iconByGameTemplate } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local { promoSmall } = require("enlisted/enlist/currency/pkgPremiumWidgets.nut")
local researchIcons = require("enlisted/globals/researchIcons.nut")
local { purchaseMsgBox } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local { attractToImage } = require("enlist/components/hoverImage.nut")
local { currencyBtn } = require("enlisted/enlist/currency/currenciesComp.nut")
local { enlistedGold } = require("enlisted/enlist/currency/currenciesList.nut")
local { onlinePurchaseStyle, smallStyle, PrimaryFlat } = require("enlist/components/textButton.nut")

local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")

const WORKSHOP_UNLOCK_LEVEL = 3
const WORKSHOP_PAGE_ID = 2

local colorBranchAvailable = ::Color(205, 205, 220)
local pageWidth = min(::sw(100) - safeAreaBorders.value[1] - safeAreaBorders.value[3], ::hdpx(1826))
local tableBoxWidth = (pageWidth - bigPadding * 3 - multySquadPanelSize[0]) * 0.45
local lineVertDistance = ::hdpx(200)
local tabIconBlockSize = researchHeaderIconHeight + bigPadding * 3
local researchesTableHeight = ::Computed(@() safeAreaSize.value[1] - ::hdpx(250)) // FIXME magic summ of sections, armies and squads bar heights
local tblScrollHandler = ::ScrollHandler()

local closestResearchByPages = ::Computed(@()
  closestTargets.value?[viewArmy.value][viewSquadId.value] ?? {})
local closestCurrentResearch = ::Computed(@() closestResearchByPages.value?[selectedTable.value])
local isResearchListVisible = ::Watched(false)
local needScrollClosest = ::Watched(true)

local curSquadData = ::Computed(@() armySquadsById.value?[viewArmy.value][viewSquadId.value])

local curSquadNameLocId = ::Computed(function() {
  local res = armiesResearches.value?[playerSelectedArmy.value].squads[viewSquadId.value].name ?? ""
  return res != "" ? res : curSquadData.value?.manageLocId
})

local tableStructureCalculator = @(tableStruct) {
  tiersTotal = tableStruct.tiersTotal
  rowsTotal = tableStruct.rowsTotal

  cX = function(point) {
    if (tiersTotal == 1)
      return 50.00

    local tableWidth = tableBoxWidth
    local totalPercents = 100.00 * ((tableWidth - tablePadding * 2) / tableWidth)
    return (100.00 - totalPercents) / 2 + totalPercents * (point.tier - 1) / (tiersTotal - 1)
  }

  cY = function(point) {
    if (rowsTotal == 1)
      return 50.00

    local tableHeight = rowsTotal * lineVertDistance + tablePadding * 2
    local totalPercents = 100.00 * ((tableHeight - tablePadding * 2) / tableHeight)
    return (100.00 - totalPercents) / 2 + totalPercents * (point.line - 1) / (rowsTotal - 1)
  }
}

local function scrollToResearch(curResearch) {
  if (curResearch == null)
    return tblScrollHandler.scrollToY(0)

  local TSC = tableStructureCalculator(tableStructure.value)
  local tableHeight = tableStructure.value.rowsTotal * lineVertDistance + tablePadding * 2
  local pos = (TSC.cY(curResearch) / 100) * tableHeight - researchesTableHeight.value / 2
  tblScrollHandler.scrollToY(pos)
}

closestCurrentResearch.subscribe(@(v) needScrollClosest(true))

local needAttractToResearch = keepref(::Computed(@() isResearchListVisible.value
  && (researchToShow.value != null || needScrollClosest.value)))
needAttractToResearch.subscribe(function(v) {
  if (!v)
    return
  local curResearch = researchToShow.value ?? (needScrollClosest.value ? closestCurrentResearch.value : null)
  if (curResearch == null)
    return

  scrollToResearch(curResearch)
  // because scrolling is not momentary
  ::gui_scene.setTimeout(0.1, function() {
    if (researchToShow.value != null)
      attractToImage(curResearch.research_id)
    researchToShow(null)
    needScrollClosest(false)
  })
})

local getLinesLayer = @(tableHeight) function () {
  local commands = [[VECTOR_WIDTH, hdpx(9)]]
  local TSC = tableStructureCalculator(tableStructure.value)
  local researches = tableStructure.value.researches
  local bgColor = tableStructure.value.pages?[selectedTable.value].bg_color ?? ModalBgTint
  foreach(toId, research in researches) {
    local status = researchStatuses.value?[toId] ?? LOCKED
    local to = research
    local curColor = status == LOCKED ? ::mul_color(bgColor, 0.6) | 0xff000000 : colorBranchAvailable
    foreach(fromId in research?.requirements ?? []) {
      local from = researches[fromId]
      commands.append([VECTOR_COLOR, curColor])
      commands.append([VECTOR_LINE, TSC.cX(from), TSC.cY(from), TSC.cX(to), TSC.cY(to) ])
    }
  }

  return {
    rendObj = ROBJ_VECTOR_CANVAS
    size = [tableBoxWidth, tableHeight]
    commands = commands
  }
}

local itemsLayer = @(tableHeight) function() {
  local TSC = tableStructureCalculator(tableStructure.value)
  local armyId = tableStructure.value.armyId
  local children = []

  foreach(tableItem in tableStructure.value.researches) {
    local posX = (TSC.cX(tableItem) / 100) * tableBoxWidth
    local posY = (TSC.cY(tableItem) / 100) * tableHeight
    children.append(tableElement(armyId, tableItem, posX, posY))
  }

  return {
    watch = [tableStructure]
    size = [tableBoxWidth, tableHeight]
    children = children
    behavior = Behaviors.RecalcHandler
  }
}

local function researchInfoPlace() {
  local needScroll = selectedResearch.value != null
  local res = {}

  local objectId = "researchDetailsPopupView"
  return res.__update({
    size = flex()
    children = researchDetailsPopup
    behavior = Behaviors.RecalcHandler
    onRecalcLayout = function(initial) {
      if (needScroll && selectedResearch.value) {
        tblScrollHandler.scrollToChildren(@(comp) comp?.key == objectId, 5, false, true)
        needScroll = false
      }
    }
  })
}

local squadResearchesInfo = ::Computed(function() {
  local researches = (armiesResearches.value?[playerSelectedArmy.value].researches ?? [])
    .filter(@(research) research.squad_id == viewSquadId.value)
  local completed = researches
    .filter(@(research) researchStatuses.value?[research.research_id] == RESEARCHED)
  return {
    total = researches.len()
    completed = completed.len()
  }
})

local mkSkillPoints = @(hasCompleted) @() {
  watch = curSquadPoints
  uid = $"skillPoints{curSquadPoints.value}"
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_TEXTAREA
  behavior = [Behaviors.TextArea, Behaviors.Button]

  font = Fonts.medium_text
  color = defTxtColor

  text = hasCompleted ? ""
    : ::loc("research/skillPoints", { skillPoints = colorize(activeTxtColor, curSquadPoints.value) })

  onHover = @(on) cursors.tooltip.state(!on ? null : ::loc("research/skillPoints/hint"))
  skipDirPadNav = true

  transform = { pivot=[0.5, 0.5] }
  animations = [
    { trigger = BALANCE_ATTRACT_TRIGGER, prop = AnimProp.scale,
      from =[1.0, 1.0], to = [1.2, 1.2], duration = 0.3, easing = CosineFull } // TODO: need fix - animation does not play
    { trigger = BALANCE_ATTRACT_TRIGGER, prop = AnimProp.color,
      from = TextHighlight, to = statusIconLocked, duration = 1.0 easing = Blink }
  ]
}

local iconSquadPoints = {
  rendObj = ROBJ_IMAGE
  size = array(2, ::hdpx(20))
  image = ::Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(::hdpx(20)))
}

local function buySquadLevelMsg() {
  local { levelCost = 0, level = 0 } = curSquadProgress.value
  purchaseMsgBox({
    price = levelCost
    currencyId = "EnlistedGold"
    title = ::loc("squadLevel", { level = level + 2 })
    description = ::loc("buy/squadLevelConfirm")
    purchase = buySquadLevel
    srcComponent = "buy_researches_level"
  })
}

local buyLevelStyle = onlinePurchaseStyle.__merge(smallStyle)
  .__update({ margin = [0, bigPadding] })

local function buyLevelBtn() {
  local cost = curSquadProgress.value?.levelCost ?? 0
  return {
    watch = curSquadProgress
    children = cost <= 0 ? null
      : currencyBtn({
          btnText = ::loc("btn/buy")
          currency = enlistedGold
          price = cost
          cb = buySquadLevelMsg
          style = buyLevelStyle.__merge({
            hotkeys = [[ "^J:Y", { description = {skip = true}} ]]
          })
        })
  }
}

local function squadProgressBlock() {
  local res = {
    watch = [curSquadData, curSquadProgress, squadResearchesInfo, monetization]
  }
  if ((curSquadData.value?.battleExpBonus ?? 0) > 0)
    return res
  local { level, exp, nextLevelExp } = curSquadProgress.value
  local pageInfo = squadResearchesInfo.value
  local hasCompleted = pageInfo.completed >= pageInfo.total
  return res.__update({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        font = Fonts.medium_text
        color = defTxtColor
        text = ::loc("levelInfo", { level = colorize(activeTxtColor, level + 1) })
      }
      nextLevelExp <= 0 ? null : progressBar({
        value = exp.tofloat() / nextLevelExp, width = ::hdpx(125), height = ::hdpx(10)
      }).__merge({ margin = ::hdpx(5) })
      mkSkillPoints(hasCompleted)
      !hasCompleted ? iconSquadPoints : null
      !hasCompleted && monetization.value ? buyLevelBtn : null
    ]
  })
}

local squadNameBlock = @() {
  watch = [curSquadData, curSquadNameLocId]
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    mkSquadPremIcon(curSquadData.value?.premIcon)
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      font = Fonts.medium_text
      color = activeTxtColor
      text = curSquadNameLocId.value ? ::loc(curSquadNameLocId.value) : null
    }
  ]
}

local wndHeader = {
  size = flex()
  padding = [0 , bigGap]
  gap = bigGap
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [SIZE_TO_CONTENT, flex()]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      squadNameBlock
      squadProgressBlock
    ]
  }
}

local function table() {
  local TSC = tableStructureCalculator(tableStructure.value)
  local tableHeight = (TSC.rowsTotal > 0 ? TSC.rowsTotal : 2) * lineVertDistance + tablePadding * 2
  return {
    watch = [tableStructure, researchStatuses]
    size = [flex(), tableHeight]
    xmbNode = ::XmbContainer({
      canFocus = @() false
      scrollSpeed = 5.0
      isViewport = true
    })
    children = [
      getLinesLayer(tableHeight)
      itemsLayer(tableHeight)
    ]
  }
}

local currentTableResearchCounter = @(idx, bgColor) function() {
  local researches = (armiesResearches.value?[playerSelectedArmy.value].researches ?? [])
    .filter(@(research) research.squad_id == viewSquadId.value && research.page_id == idx)
  local completed = researches.filter(@(researchDef) researchStatuses.value?[researchDef.research_id] == RESEARCHED)
  local hasPageCompleted = completed.len() >= researches.len()
  return {
    watch = [researchStatuses, viewSquadId]
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = researches.len() > 0
      ? [
          txt({
            text = $"{completed.len()}/{researches.len()}"
            color = bgColor
            brightness = 0.7
          })
          hasPageCompleted
            ? {
                rendObj = ROBJ_STEXT
                text = fa["check-circle"]
                font = Fonts.fontawesome
                color = bgColor
                brightness = 0.7
              }
            : null
        ]
      : null
  }
}

local function unseenInPageIcon(squadId, pageId) {
  local hasUnseen = ::Computed(function() {
    local researches = armiesResearches.value?[viewArmy.value].researches ?? {}
    local unseen = unseenResearches.value?[viewArmy.value]
    return researches.findindex(@(r) r.research_id in unseen && r.squad_id == squadId && r.page_id == pageId) != null
  })
  return @() {
    watch = hasUnseen
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    children = hasUnseen.value ? unseenSignal() : null
  }
}

local mkImageByTemplate = ::kwarg(function(width, height, templateId, templateOverride = null) {
  local tmplParams = templateOverride ?? {}
  local scale = tmplParams?.scale ?? 1.0
  tmplParams = tmplParams.__merge({
    width = width * scale
    height = width * scale
    shading = "silhouette"
    silhouette = [255, 255, 255, 255]
  })
  return iconByGameTemplate(templateId, tmplParams)
})

local getSquarePicture = @(image, size) (image ?? "") == "" ? null
  : ::Picture(image.slice(-4) == ".svg" ? $"!{image}:{size.tointeger()}:{size.tointeger()}:K" : $"{image}?Ac")

local mkImageByIcon = ::kwarg(function(width, height, iconPath, iconOverride = null) {
  local iconSize = min(width, height)
  local resized = (iconSize * (iconOverride?.scale ?? 1.0)).tointeger()
  local pos = iconOverride?.pos ?? [0, 0]
  return {
    size = [iconSize, iconSize]
    children = {
      rendObj = ROBJ_IMAGE
      size = [resized, resized]
      image = getSquarePicture(iconPath, resized)
      pos = [(iconSize - resized) * pos[0],  (iconSize - resized) * pos[1]]
    }
  }
})

local function mkPageIcon(closestResearchDef, page) {
  local width = researchItemSize[0]
  local height = researchItemSize[1]
  return function() {
    local researchDef = closestResearchDef.value
    local templateId = researchDef?.gametemplate ?? ""
    local iconPath = researchIcons?[researchDef?.icon_id]
      ?? (templateId == "" ? researchIcons?[page?.icon_id] : null)
    return {
      watch = closestResearchDef
      rendObj = ROBJ_SOLID
      size = [tabIconBlockSize, tabIconBlockSize]
      padding = bigPadding
      color = Color(100, 100, 100, 100)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        templateId == "" ? null : mkImageByTemplate({
          width = width
          height = height
          templateId = templateId
          templateOverride = researchDef?.templateOverride
        })
        iconPath == null ? null : mkImageByIcon({
          width = width
          height = height
          iconPath = iconPath
          iconOverride = researchDef?.iconOverride
        })
        currentTableResearchCounter(page.page_id, page.bg_color)
      ]
    }
  }
}

local mkPageInfoText = @(page, isSelected) {
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = tabIconBlockSize
  flow = FLOW_VERTICAL
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      font = isWide ? Fonts.big_text : Fonts.medium_text
      text = ::loc(page.name)
      color = isSelected ? activeTxtColor : defTxtColor
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      font = Fonts.small_text
      text = ::loc(page.description)
      color = isSelected ? activeTxtColor : defTxtColor
    }
  ]
}

local function upgradePageTab(page, pageId) {
  local stateFlags = ::Watched(0)
  local unseenIcon = unseenInPageIcon(page.squad_id, pageId)
  local closestResearchDef = ::Computed(@() closestResearchByPages.value?[pageId])

  return function() {
    local isSelected = selectedTable.value == pageId
    local isHovered = stateFlags.value & S_HOVER
    return {
      size = [flex(), SIZE_TO_CONTENT]
      maxHeight = hdpx(220)
      watch = [stateFlags, selectedTable]
      rendObj = ROBJ_BOX
      borderWidth = isSelected || isHovered ? researchListTabBorder : 0

      borderColor = Color(205, 205, 220, 255)
      padding = researchListTabPadding
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = bigGap
      fillColor = page.bg_color

      behavior = Behaviors.Button
      sound = buttonSound
      onClick = @() selectedTable(pageId)
      onElemState = @(sf) stateFlags.update(sf)

      children = [
        mkPageIcon(closestResearchDef, page)
        mkPageInfoText(page, isSelected)
        unseenIcon
      ]
    }
  }
}

local function researchesPageBranch() {
  return scrollbar.makeVertScroll(table, {
    scrollHandler = tblScrollHandler
    rootBase = class {
      size = flex()
      behavior = Behaviors.Pannable
      wheelStep = 1.58
      skipDirPadNav = true
    }
    barStyle = @(has_scroll) class {
      _width = sh(1)
      _height = sh(1)
      skipDirPadNav = true
    }
    knobStyle = class {
      skipDirPadNav = true
      hoverChild = function(sf) {
        return {
          rendObj = ROBJ_BOX
          size = [hdpx(8), flex()]
          borderWidth = [hdpx(6), hdpx(2), hdpx(6), hdpx(1)]
          borderColor = Color(0, 0, 0, 0)
          fillColor = (sf & S_ACTIVE) ? Color(255,255,255)
              : (sf & S_HOVER)  ? Color(110, 120, 140, 80)
                                : Color(110, 120, 140, 160)
        }
      }
    }
  })
}

local emptyResearchesText = {
  rendObj = ROBJ_DTEXT
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  font = Fonts.medium_text
  text = ::loc("researches/willBeAvailableSoon")
}

local lowCampaignLevelText = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_DTEXT
      font = Fonts.medium_text
      text = ::loc("researches/levelTooLowForWorkshop")
    }
    PrimaryFlat(::loc("menu/campaignRewards"), function(){
        setCurSection("SQUADS")
      }, {
        hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
      }
    )
  ]
}

local promoSquadResearches = @() {
  watch = monetization
  size = flex()
  valign = ALIGN_BOTTOM
  children = monetization.value
    ? promoSmall("premium/buyForExperience", {
        rendObj = ROBJ_SOLID
        color = defBgColor
        padding = bigGap
      }, null, "researches_sections")
    : null
}

local function researchesTable() {
  local res = {
    size = flex()
    watch = [tableStructure, maxCampaignLevel, selectedTable]
    onAttach = @() isResearchListVisible(true)
    onDetach = @() isResearchListVisible(false)
  }
  local pagesAmount = (tableStructure.value?.pages ?? []).len()
  local isBranchEmpty = (tableStructure.value?.researches ?? {}).len() == 0
  local isCampaignLevelLow = maxCampaignLevel.value < WORKSHOP_UNLOCK_LEVEL && selectedResearch?.value.page_id == WORKSHOP_PAGE_ID
  local isLocked = isBranchEmpty || isCampaignLevelLow

  if (pagesAmount == 0)
    return res.__update({
      rendObj = ROBJ_SOLID
      color = ModalBgTint
      children = emptyResearchesText
    })

  local listSize = [isLocked ? flex() : pw(45), flex()]
  local listColor = tableStructure.value.pages?[selectedTable.value].bg_color ?? ModalBgTint

  return res.__update({
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      {
        size = [pw(30), flex()]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = tableStructure.value.pages.map(upgradePageTab).append(promoSquadResearches)
      }
      {
        rendObj = ROBJ_SOLID
        size = listSize
        color = listColor
        children = isBranchEmpty ? emptyResearchesText
          : isCampaignLevelLow ? lowCampaignLevelText
          : researchesPageBranch
      }
      isLocked ? null : researchInfoPlace
    ]
  })
}

local armySelectWithMarks = armySelect({
  function addChild(armyId, sf) {
    local count = ::Computed(function() {
      local researches = armiesResearches.value?[armyId].researches ?? {}
      local unseenSquads = {}
      foreach(id, _ in unseenResearches.value?[armyId] ?? {}) {
        local squadId = researches?[id].squad_id
        if (squadId != null)
          unseenSquads[squadId] <- true
      }
      return unseenSquads.len()
    })
    return function() {
      local res = { watch = count, pos = [hdpx(25), 0], key = armyId }
      if(count.value <= 0)
        return res
      return blinkingIcon("arrow-up", count.value, false).__update(res)
    }
  }
})

local mkSquadExp = function(squadId) {
  local exp = ::Computed(@() allSquadsPoints.value?[squadId] ?? 0)
  return @(sf, selected) @() mkActiveBlock(sf, selected, [
    mkCardText(exp.value, sf, selected)
    iconSquadPoints
  ]).__update({
    watch = exp
    valign = ALIGN_CENTER
    gap = ::hdpx(3)
  })
}

local function unseenInSquadIcon(squadId) {
  local hasUnseen = ::Computed(function() {
    local researches = armiesResearches.value?[viewArmy.value].researches ?? {}
    local unseen = unseenResearches.value?[viewArmy.value]
    return researches.findindex(@(r) r.research_id in unseen && r.squad_id == squadId) != null
  })
  return @() {
    watch = hasUnseen
    hplace = ALIGN_RIGHT
    children = hasUnseen.value ? unseenSignal(0.7) : null
  }
}

local mkSquadMkChild = @(squadId) @(sf, selected) {
  hplace = ALIGN_RIGHT
  margin = smallPadding
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = [
    mkSquadExp(squadId)(sf, selected)
    unseenInSquadIcon(squadId)
  ]
}

local researchesSquads = ::Computed(@() (curUnlockedSquads.value ?? [])
  .map(@(s) s.__merge({
    mkChild = mkSquadMkChild(s.squadId)
    level = curArmySquadsProgress.value?[s.squadId].level ?? 0
  })))

return {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL

      children = [
        armySelectWithMarks
        wndHeader
        campaignTitle
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      size = [pageWidth, flex()]
      gap = bigPadding
      children = [
        mkCurSquadsList({
          curSquadsList = researchesSquads
          curSquadId = viewSquadId
        })
        researchesTable
      ]
    }
  ]
} 