local isWide = sw(100).tofloat() / sh(100) > 1.7

local selectedTxtColor = Color(0,0,0)
local deadTxtColor = Color(0,0,0)
local defTxtColor = Color(180,180,180)
local nameTxtColor = Color(255, 255, 255)
local weaponTxtColor = Color(170, 170, 170)
local disabledTxtColor = Color(100,100,100)
local hoverBgColor = Color(205,205,220)
local activeBgColor = Color(180,180,180,255)
local defBgColor = Color(0,0,0,120)
local airHoverBgColor = Color(205,205,220,200)
local airBgColor = Color(0,0,0,120)
local airSelectedBgColor = Color(150,150,150,150)
local defPanelBgColorVer_1 = Color(50,50,50,200)
local smallPadding = hdpx(4)
local bigPadding = hdpx(8)
local u = hdpx(45) //unit, 1920x1080 - 45x24)
local researchListTabBorder = ::hdpx(4)

local multySquadPanelSize = [(u * 2.4).tointeger(), (u * 2.4).tointeger()]
local squadSlotHorSize = [::hdpx(660).tointeger(), ::hdpx(80).tointeger()]

local soldierWndWidth = u * 11
local squadPanelWidth = u * 6
local fadedTxtColor = Color(130,130,130,150)

local style = {
  isWide
  bigGap = hdpx(10)
  gap = hdpx(5)
  //********************** Enlisted constants **************************/
  selectedBgColor = Color(220,220,220)
  u = u
  unitSize = u
  defBgColor = defBgColor
  darkBgColor = Color(0,0,0,180)
  defInsideBgColor = Color(25,25,25,120)
  blurBgColor = Color(150,150,150,255)
  blurBgColorVer_1 = Color(100,150,200,255)
  blurBgFillColor = Color(25, 25, 25, 25)
  textBgBlurColor = Color(200,200,200,255)
  hoverBgColor = hoverBgColor
  activeBgColor = activeBgColor
  opaqueBgColor = Color(20,20,20)
  blockedBgColor = Color(100, 10, 10)

  insideBorderColor = Color(50,50,40,5)

  airBgColor = airBgColor
  airHoverBgColor = airHoverBgColor
  airSelectedBgColor = airSelectedBgColor

  defTxtColor = defTxtColor
  fadedTxtColor = fadedTxtColor
  disabledTxtColor = disabledTxtColor
  activeTxtColor = Color(220, 220, 220, 255)
  hoverTxtColor = Color(0,0,0)
  noteTxtColor = fadedTxtColor
  selectedTxtColor = selectedTxtColor
  deadTxtColor = deadTxtColor
  defPanelBgColorVer_1 = defPanelBgColorVer_1
  msgHighlightedTxtColor = Color(210, 170, 20)
  blockedTxtColor = Color(200, 15, 10)
  hasPremiumColor = Color(210, 210, 100)

  titleTxtColor = Color(255, 255, 255)
  activeTitleTxtColor = Color(180, 180, 200)
  hoverTitleTxtColor = Color(220, 220, 230)

  detailsHeaderColor = Color(200,200,220)

  perkBgDarken = Color(0, 0, 0, 255)
  perkBgLighten = Color(20, 20, 20, 255)
  perkBgHover = Color(40, 40, 40, 255)
  perkBgSelected = Color(70, 70, 70, 255)

  debriefingTabsBarColor = Color(0,0,0,100)
  debriefingDarkColor = Color(0,0,0,180)

  blinkingSignalsGreenNormal = Color(61, 182, 19)
  blinkingSignalsGreenDark = Color(32, 125, 0)

  translucentBgColor = Color(0,0,0,75)
  soldierExpBgColor = Color(0, 0, 0, 100)
  soldierExpColor = Color(239, 219, 100)
  soldierLvlColor = Color(200, 180, 0, 150)
  soldierGainLvlColor = Color(255, 255, 150)
  soldierLockedLvlColor = Color(90, 90, 90)

  spawnReadyColor = Color(50, 150, 50)
  spawnNotReadyColor = Color(180, 70, 70)
  spawnPreparationColor = Color(150, 150, 50)

  smallPadding = smallPadding
  bigPadding = bigPadding

  windowsInterval = bigPadding

  /* army squad */
  multySquadPanelSize = multySquadPanelSize
  squadSlotHorSize = squadSlotHorSize
  squadBigIconSize = [hdpx(140), hdpx(160)]
  squadMediumIconSize = [hdpx(98), hdpx(112)]
  squadElemsBgColor = Color(60, 60, 60, 150)
  squadElemsBgHoverColor = Color(150, 150, 150, 150)
  squadPromoSlotSize = [flex(), hdpx(420)]
  lockedSquadBgColor = Color(99, 97, 98)
  unlockedSquadBgColor = Color(80, 117, 59)
  progressBorderColor = Color(48,62,66)
  progressExpColor = Color(185, 129, 49)
  progressAddExpColor = Color(205, 155, 60)

  soldierWndWidth = soldierWndWidth
  squadPanelWidth = squadPanelWidth
  perkIconSize = (u * 1.5 - 2 * smallPadding).tointeger()
  perkBigIconSize = [::hdpx(300).tointeger(), ::hdpx(400).tointeger()]
  awardIconSize = (u * 2).tointeger()
  awardIconSpacing = 2 * bigPadding

  soldierCardSize = [hdpx(92), hdpx(136)]
  soldierCardNameHeight = u.tointeger()
  soldierCardHeadHeight = 0.5 * u.tointeger()

  rarityColors = [defTxtColor, Color(220, 220, 100)]
  bonusColor = Color(120, 250, 120)
  warningColor = Color(230, 100, 100)

  slotBaseSize = [(6 * u).tointeger(), (1.5 * u).tointeger()]
  slotMediumSize = [(4 * u).tointeger(), (1.5 * u).tointeger()]

  listCtors = {
    nameColor = function(flags, selected){
      return (selected || (flags & S_HOVER)) ? selectedTxtColor : nameTxtColor
    }
    weaponColor = function(flags, selected){
      return (selected || (flags & S_HOVER)) ? selectedTxtColor : weaponTxtColor
    }

    txtColor = function(flags, selected){
      return (selected || (flags & S_HOVER)) ? selectedTxtColor : defTxtColor
    }
    txtDisabledColor = function(flags, selected){
      return (selected || (flags & S_HOVER)) ? selectedTxtColor : disabledTxtColor
    }
    bgColor = function(flags, selected, idx=0) {
      return selected ? activeBgColor
        : flags & S_HOVER ? hoverBgColor
        : (idx%2==0) ? defBgColor
        : ::mul_color(defBgColor, 0.65)
    }
  }


  listBtnAirStyle = function(isSelected, idx, total) {
    local res = {
      margin = 0
      textMargin = bigPadding
      borderWidth = 0
      borderRadius = 0
      rendObj = ROBJ_BOX
      style = {
        BgNormal  = airBgColor
        BgHover   = airHoverBgColor
        BgActive  = airHoverBgColor
        BgFocused = airHoverBgColor
      }
    }
    if (isSelected)
      return res.__update({
        fillColor = airSelectedBgColor
        textParams = { color = selectedTxtColor }
      })
    return res
  }

  scrollbarParams = {
    size = [SIZE_TO_CONTENT, flex()]
    skipDirPadNav = true
    barStyle = @(has_scroll) class {
      _width = sh(1)
      _height = sh(1)
      skipDirPadNav = true
    }
    knobStyle = class {
      skipDirPadNav = true
      hoverChild = @(sf) {
        rendObj = ROBJ_BOX
        size = [hdpx(8), flex()]
        borderWidth = [0, hdpx(1), 0, hdpx(1)]
        borderColor = Color(0, 0, 0, 0)
        fillColor = (sf & S_ACTIVE) ? Color(255,255,255)
          : (sf & S_HOVER) ? Color(110, 120, 140, 80)
          : Color(110, 120, 140, 160)
      }
    }
  }

  armyIconHeight = ::hdpx(50)
  researchItemSize = [::hdpx(110), ::hdpx(130)]
  researchListTabWidth = ::hdpx(440)
  researchListTabBorder = researchListTabBorder
  researchListTabPadding = researchListTabBorder + (isWide ? bigPadding * 2 : bigPadding)
  researchHeaderIconHeight = isWide ? ::hdpx(120) : ::hdpx(80)
  tablePadding = hdpx(120)
  scrollHeight = hdpx(36)
  vehicleListCardSize = [u*5, u*3]
  debriefingArmyIconHeight = ::hdpx(80)
  inventoryItemDetailsWidth = hdpx(400)
}

return style
 