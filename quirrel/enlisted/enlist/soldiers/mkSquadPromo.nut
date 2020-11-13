local { squadBigIconSize, squadMediumIconSize, titleTxtColor, activeTxtColor, unlockedSquadBgColor, lockedSquadBgColor,
  smallPadding, bigPadding, defTxtColor, darkBgColor, squadElemsBgColor } = require("enlisted/enlist/viewConst.nut")
local { isGamepad } = require("ui/control/active_controls.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local perksPackage = require("components/perksPackage.nut")
local { classIcon, className } = require("components/soldiersUiComps.nut")
local {
  allItemTemplates, findItemTemplate
} = require("model/all_items_templates.nut")
local { iconByGameTemplate, getItemName } = require("itemsInfo.nut")
local textButton = require("enlist/components/textButton.nut")
local { textMargin } = require("daRg/components/textButton.style.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")
local { sound_play } = require("sound")

local saBorders = safeAreaBorders.value

local mkText = @(txt) {
  rendObj = ROBJ_DTEXT
  font = Fonts.medium_text
  color = defTxtColor
  text = txt
}

local mkSquadHead = ::kwarg(@(campaignNameBlock, customStyle, lockedBlock, nameLocId = null, titleLocId = null, icon = null) {
  size = [flex(), SIZE_TO_CONTENT]
  margin = [customStyle.saBorders[0], 0, 0, 0]
  children = [
    {
      rendObj = ROBJ_SOLID
      size = [flex(), customStyle.headHeight + 2 * bigPadding]
      padding = [0, customStyle.saBorders[1], 0, customStyle.saBorders[3]]
      color = darkBgColor
      children = lockedBlock
    }
    {
      size = [customStyle.headWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      padding = bigPadding
      gap = bigPadding
      hplace = ALIGN_CENTER
      children = [
        icon != null ? {
          rendObj = ROBJ_IMAGE
          size = customStyle.iconSize
          padding = bigPadding
          keepAspect = true
          image = ::Picture(icon)
        } : null
        {
          size = [flex(), customStyle.headHeight]
          flow = FLOW_VERTICAL
          valign = ALIGN_CENTER
          children = [
            campaignNameBlock
            mkText(::loc(nameLocId ?? ""))
              .__update({ font = Fonts.big_text })
            { size = flex() }
            mkText(::loc(titleLocId ?? ""))
              .__update({ font = Fonts.big_text, color = Color(200,150,100) })
          ]
        }
      ]
    }
  ]
})


local mkBodyTextBlock = @(txt, customStyle = {}) (txt ?? "").len() > 0
  ? {
      padding = bigPadding
      children = {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        font = Fonts.small_text
        color = defTxtColor
        text = txt
      }
    }.__update(customStyle)
  : null

local mkBodyBgBlock = @(customStyle = {}) {
  rendObj = ROBJ_SOLID
  color = darkBgColor
}.__update(customStyle)

local mkSquadDesc = ::kwarg(function(announceLocId = null, sClassAnnounce = null, weaponAnnounceLocId = null) {
  local announceText = ::loc(announceLocId ?? "")
  local sClassAnnounceText = (sClassAnnounce ?? "") == "" ? ""
    : "{0}\n{1}".subst(::loc($"classannounce/{sClassAnnounce}", ""),
        ::loc($"soldierClass/{sClassAnnounce}/desc", ""))
  local weaponAnnounceText = ::loc(weaponAnnounceLocId ?? "")

  if (announceText.len() == 0 && sClassAnnounceText.len() == 0 && weaponAnnounceText.len() == null)
    return null

  return {
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          sClassAnnounceText.len() ? mkBodyBgBlock({ size = [pw(30), flex()] }) : null
          announceText.len() ? mkBodyBgBlock({ size = flex() }) : { size = flex() }
          weaponAnnounceText.len() ? mkBodyBgBlock({ size = [pw(30), flex()] }) : null
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          mkBodyTextBlock(sClassAnnounceText, {size = [pw(30), SIZE_TO_CONTENT]})
          mkBodyTextBlock(announceText, {size = [flex(), SIZE_TO_CONTENT]}) ?? { size = flex() }
          mkBodyTextBlock(weaponAnnounceText, {size = [pw(30), SIZE_TO_CONTENT]})
        ]
      }
    ]
  }
})

local mkPerkBlock = @(perkId) perkId ? {
  rendObj = ROBJ_SOLID
  size = [flex(), hdpx(90)]
  valign = ALIGN_CENTER
  color = squadElemsBgColor
  children = perksPackage.perkUi({ perkId = perkId })
} : null

local mClassIconBlock = @(sClassId) sClassId ? {
  rendObj = ROBJ_BOX
  size = [hdpx(90), hdpx(90)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  fillColor = darkBgColor
  borderWidth = hdpx(2)
  borderColor = squadElemsBgColor
  children = classIcon(sClassId, hdpx(70))
} : null

local mClassDescBlock = @(sClassId, isLocked) sClassId
  ? {
      flow = FLOW_VERTICAL
      children = [
        isLocked
          ? mkText(::loc("mainmenu/newInfantryClass")).__update({
              font = Fonts.small_text
              color = Color(255, 255,255)
            })
          : null
        className(sClassId).__update({
          font = Fonts.big_text
          color = Color(255, 255,255)
        })
      ]
    }
  : null

local function mNewItemBlock(armyId, itemId, itemWidth, isLocked) {
  local item = findItemTemplate(allItemTemplates, armyId, itemId)
  if (item == null)
    return null

  local gametemplate = item?.gametemplate
  return gametemplate != null
    ? {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            halign = ALIGN_RIGHT
            children = [
              isLocked
                ? mkText(::loc(item?.itemtype == "vehicle"
                    ? "mainmenu/newVehicle"
                    : "mainmenu/newWeapon"))
                      .__update({
                        font = Fonts.small_text
                        color = Color(255, 255,255)
                      })
                : null
              mkText(getItemName(item)).__update({
                font = Fonts.big_text
                color = Color(255, 255,255)
              })
            ]
          }
          {
            rendObj = ROBJ_SOLID
            size = [flex(), hdpx(90)]
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            color = darkBgColor
            children = iconByGameTemplate(gametemplate, {
              width = itemWidth
              height = hdpx(90)
            })
          }
        ]
      }
    : null
}

local mkSquadBodyBottom = ::kwarg(@(armyId, newClass, newPerk, newWeapon, customStyle, locked) {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_BOTTOM
  children = [
    {
      size = [customStyle.leftBlockWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        mClassDescBlock(newClass, locked)
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            mClassIconBlock(newClass)
            mkPerkBlock(newPerk)
          ]
        }
      ]
    }
    customStyle.separationBlock
    {
      size = [customStyle.rightBlockWidth, SIZE_TO_CONTENT]
      children = mNewItemBlock(armyId, newWeapon, customStyle.itemWidth, locked)
    }
  ]
})

local mkBgImg = @(img) {
  rendObj = ROBJ_IMAGE
  size = flex()
  keepAspect = true
  imageValign = ALIGN_TOP
  image = ::Picture(img)
}

local mkBackWithImage = @(img, customStyle) {
  rendObj = ROBJ_SOLID
  size = [pw(100), pw(75)]
  margin = [customStyle.headHeight + 2 * bigPadding, 0,0,0]
  color = Color(0,0,0)
  children = mkBgImg(img)
}

local lockedOverBlock = {
  rendObj = ROBJ_SOLID
  size = [pw(100), pw(75)]
  color = Color(0,0,0)
  opacity = 0.5
}

local function mkSquadBody(squadData) {
  local { customStyle, descBlock, addBodyChild = null } = squadData
  return {
    size = flex()
    margin = [customStyle.headHeight + 2 * bigPadding, 0,0,0]
    children = [
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = bigPadding
        padding = [0, customStyle.saBorders[1], bigPadding, customStyle.saBorders[3]]
        children = [
          addBodyChild
          mkSquadBodyBottom(squadData)
          descBlock
        ]
      }
    ]
  }
}

local mkUnlockInfo = @(t) {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  margin = hdpx(1)
  halign = ALIGN_CENTER
  color = lockedSquadBgColor
  children = mkText(t).__update({
    margin = textMargin
    color = activeTxtColor
  })
}

local backBtn = @(cb) cb != null
  ? @() {
      watch = isGamepad
      children = !isGamepad.value
        ? textButton.Flat(::loc("Back"), cb, { margin = hdpx(1) })
        : null
    }
  : null


local mkSquadUnlockBlock = @(unlockInfo, customStyle, isSmall, cbData = null) function() {
  local res = {
    watch = unlockInfo
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    padding = [0, customStyle.saBorders[1], bigPadding, customStyle.saBorders[3]]
  }
  local unlock = unlockInfo.value
  if (unlock == null)
    return res.__update({
      children = [
        mkUnlockInfo(::loc("squad/unlocked"))
          .__update({ color = unlockedSquadBgColor })
        backBtn(cbData?.closeCb)
      ]
    })
  else if (unlock?.unlockCb != null)
    return res.__update({
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_RIGHT
          children = [
            textButton.Purchase(::loc("mainmenu/unlockNow"), unlock.unlockCb, {
              size = [flex(), SIZE_TO_CONTENT]
              margin = hdpx(1)
              animations = [{
                prop = AnimProp.opacity, from = 0.7, to = 1, duration = 1,
                play = true, loop = true, easing = Blink
              }]
              hotkeys = isSmall ? [] : [[ "^J:X | Enter", { description = {skip = true}} ]]
            })
            unseenSignal(0.8)
          ]
        }
        backBtn(cbData?.closeCb)
      ]
    })

  return res.__update({
    children = [
      mkUnlockInfo(unlock?.unlockText ?? "")
      backBtn(cbData?.closeCb)
    ]
  })
}

local animationsList = @(delay, onEnter = null, onFinish = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true, easing = InOutCubic }
  { prop = AnimProp.opacity, delay = delay, from = 0, to = 1, duration = 0.9, play = true, easing = InOutCubic }
  { prop = AnimProp.scale, delay = delay, from = [3,3], to = [1,1], duration = 0.9, play = true, easing = InOutCubic }
  { prop = AnimProp.translate, delay = delay, from = [sh(30),-sh(10)], to = [0,0], duration = 0.9, play = true, easing = InOutCubic,
    onEnter = onEnter, onFinish = onFinish }
]

local headTextParams = {
  fontFxColor = 0xFF000000
  fontFxFactor = 64
  fontFx = FFT_GLOW
}

local mkUnlockAnimation = @(squadData, cbData) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  margin = [sh(55),0,0,0]
  padding = sh(2)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    mkText(::loc("mainmenu/congratulations")).__update(headTextParams).__update({
      font = Fonts.giant_numbers
      color = titleTxtColor
      transform = {}
      animations = animationsList(0, @() sound_play("ui/squad_unlock_text"), @() sound_play("ui/squad_unlock_text_2"))
    })
    mkText(::loc("squad/gotNewSquad")).__update(headTextParams).__update(headTextParams).__update({
      font = Fonts.big_text
      color = titleTxtColor
      transform = {}
      animations = animationsList(0.6, null, @() sound_play("ui/squad_unlock_buttons"))
    })
    {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      margin = sh(2)
      transform = {}
      animations = animationsList(1.5)
      children = [
        mkText(::loc("squad/openManageRequeat")).__update(headTextParams).__update({
          font = Fonts.medium_text
          color = titleTxtColor
        })
        {
          flow = FLOW_HORIZONTAL
          children = [
            cbData?.manageCb != null
              ? textButton.Purchase(::loc("btn/squadManage"), cbData.manageCb, {
                  hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
                })
              : null
            cbData?.closeCb != null
              ? textButton.PrimaryFlat(::loc(cbData?.manageBtnLocId ?? "btn/later"),
                  cbData.closeCb,
                  { hotkeys = [[ "^J:B | Esc", { description = {skip = true}} ]] })
              : null
          ]
        }
      ]
    }
  ]
}

local function mkSquadSummary(squadData) {
  local children = []
  local locId = squadData?.summaryLocId
  if (locId) {
    local idx = 0
    local text = ::loc(locId, "")
    while (text != "") {
      children.append({
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_TOP
        behavior = Behaviors.TextArea
        font = Fonts.small_text
        text = text
      })
      text = ::loc($"{locId}_{++idx}", "")
    }
  }
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), ::hdpx(120)] // =5 lines of summary text
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    color = ::Color(40, 40, 40, 255)
    padding = [bigPadding, bigPadding]
    gap = bigPadding
    children = children
  }
}

local mkSquad = ::kwarg(@(squadData, unlockInfo = Watched(null), cbData = null, isSmall = false) {
  size = flex()
  padding = hdpx(1)
  clipChildren = true
  children = [
    squadData?.image
      ? mkBackWithImage(squadData.image, squadData.customStyle)
      : mkBodyBgBlock({ size = [pw(100), pw(75)], color = darkBgColor })
    squadData.locked ? lockedOverBlock : null
    {
      size = flex()
      flow = FLOW_VERTICAL
      margin = [0, 0, squadData.customStyle.saBorders[2], 0]
      children = [
        mkSquadBody(squadData)
        mkSquadUnlockBlock(unlockInfo, squadData.customStyle, isSmall, cbData)
        squadData?.summaryBlock
      ]
    }
    mkSquadHead(squadData)
    squadData?.unlockedBlock
  ]
})

local mkSquadBonusExp = @(squadCfg, getBonusExpText = @(bonus) null)
  (squadCfg?.battleExpBonus ?? 0) <= 0 ? null
    : {
        rendObj = ROBJ_TEXTAREA
        size = [pw(50), SIZE_TO_CONTENT]
        hplace = ALIGN_RIGHT
        halign = ALIGN_RIGHT
        behavior = Behaviors.TextArea
        font = Fonts.small_text
        text = getBonusExpText(squadCfg.battleExpBonus)
      }

local bonusText = @(val) "+{0}%".subst((100 * val).tointeger())

local mkBonusExpShort = @(squadCfg) mkSquadBonusExp(squadCfg,
  @(bonus) "".concat(::loc("battle_exp_bonus"), ::loc("ui/colon"), bonusText(bonus)))

local mkBonusExpLong = @(squadCfg) mkSquadBonusExp(squadCfg,
  @(bonus) "".concat(::loc("squad/expBonus/desc", { bonus = bonusText(bonus) })))

local mkSquadSmallCard = ::kwarg(@(squad, squadCfg, armyId, unlockInfo)
  mkSquad({
    squadData = squadCfg.__merge(squad).__merge({
      armyId = armyId
      customStyle = {
        headWidth = pw(100)
        headHeight = sh(6)
        leftBlockWidth = flex(1.8)
        rightBlockWidth = flex(1.2)
        itemWidth = hdpx(200)
        iconSize = squadMediumIconSize
        separationBlock = { size = flex(0.5) }
        saBorders = [0, bigPadding, 0, bigPadding]
      }
      descBlock = null
      campaignNameBlock = null
      lockedBlock = null
      summaryBlock = mkSquadSummary(squadCfg)
      addBodyChild = mkBonusExpShort(squadCfg)
    })
    unlockInfo = unlockInfo
    isSmall = true
  }))

local mkSquadBigCard = ::kwarg(@(squad, squadCfg, armyId, unlockInfo, cbData = null)
  mkSquad({
    squadData = squadCfg.__merge(squad).__merge({
      armyId = armyId
      customStyle = {
        headWidth = pw(70)
        headHeight = sh(9)
        leftBlockWidth = pw(30)
        rightBlockWidth = pw(30)
        itemWidth = hdpx(300)
        iconSize = squadBigIconSize
        separationBlock = { size = flex() }
        saBorders = saBorders
      }
      descBlock = mkSquadDesc(squadCfg)
      campaignNameBlock = mkText(squadCfg.campaignName)
      lockedBlock = null
      addBodyChild = mkBonusExpLong(squadCfg)
    })
    unlockInfo = unlockInfo
    cbData = cbData
  }))

local mkSquadUnlockCard = ::kwarg(@(squad, squadCfg, armyId, unlockInfo, cbData = null)
  mkSquad({
    squadData = squadCfg.__merge(squad).__merge({
      armyId = armyId
      customStyle = {
        headWidth = pw(70)
        headHeight = sh(9)
        leftBlockWidth = pw(30)
        rightBlockWidth = pw(30)
        itemWidth = hdpx(300)
        iconSize = squadBigIconSize
        separationBlock = { size = flex() }
        saBorders = saBorders
      }
      descBlock = null
      campaignNameBlock = mkText(squadCfg.campaignName)
      lockedBlock = null
      unlockedBlock = mkUnlockAnimation(squadCfg, cbData)
      addBodyChild = mkBonusExpLong(squadCfg)
    })
    unlockInfo = unlockInfo
  }))

return {
  mkSquadSmallCard = mkSquadSmallCard
  mkSquadBigCard = mkSquadBigCard
  mkSquadUnlockCard = mkSquadUnlockCard
}
 