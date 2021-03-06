local fa = require("daRg/components/fontawesome.map.nut")
local { endswith } = require("string")
local {
  smallPadding, activeBgColor, hoverBgColor, defBgColor, listCtors,
  defTxtColor, spawnNotReadyColor, spawnReadyColor, spawnPreparationColor,
  multySquadPanelSize
} = require("enlisted/enlist/viewConst.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local soldierClasses = require("enlisted/enlist/soldiers/model/soldierClasses.nut")

const ICON_SCALE = 0.85
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"

local squadTypeIconSize = [::hdpx(30), ::hdpx(30)]
local premIconSize = [::hdpx(26), ::hdpx(26)]

local squadTypeSvg = soldierClasses.map(@(c) c.icon)
  .__update({
      tank = "tank_icon.svg"
      aircraft = "aircraft_icon.svg"
    })
  .map(@(key) $"ui/skin#{key}")

local getSquadTypeIcon = @(squadType) squadTypeSvg?[squadType] ?? "ui/skin#rifle.svg"

local mkText = @(text) {
  rendObj = ROBJ_DTEXT
  font = Fonts.small_text
  text = text
  color = defTxtColor
}

local mkTextArea = @(text) mkText(text).__update({
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = SIZE_TO_CONTENT
  maxWidth = pw(80)
})

local mkSquadSpawnColor = @(canSpawnSquad, readiness, canSpawnSoldier = true)
  !canSpawnSquad || readiness == 0 || !canSpawnSoldier ? spawnNotReadyColor
  : readiness == 100 ? spawnReadyColor
  : spawnPreparationColor

local function mkSquadSpawnDesc(canSpawnSquad, readiness, canSpawnSoldier = true) {
  if (canSpawnSquad == null || readiness == null)
    return mkTextArea(::loc("respawn/squadNotChoosen"))

  local descKeyId = !canSpawnSquad && readiness == 100 ? "respawn/squadNotParticipate"
    : !canSpawnSquad ? "respawn/squadNotReady"
    : !canSpawnSoldier ? "respawn/soldierNotReady"
    : readiness == 100 ? "respawn/squadReady"
    : "respawn/squadPartiallyReady"
  return mkTextArea(::loc(descKeyId, { number = readiness }))
}

local mkSquadSpawnIcon = @(canSpawnSquad, readiness, canSpawnSoldier = true, size = hdpx(20).tointeger())
  canSpawnSquad != null && readiness != null
    ? {
        rendObj = ROBJ_IMAGE
        margin = smallPadding
        hplace = ALIGN_RIGHT
        size = [size, size]
        keepAspect = true
        image = ((canSpawnSquad && canSpawnSoldier) ? null : ::Picture($"ui/skin#ban_icon.svg:{size}:{size}:K"))
        color = mkSquadSpawnColor(canSpawnSquad, readiness, canSpawnSoldier)
      }
    : null

local function mkSquadIcon(img, override = {}) {
  if ((img ?? "") == "")
    return {
      rendObj = ROBJ_BOX
      size = flex()
    }
  if (endswith(img, "svg") && "size" in override) {
    local size = override.size
    if (typeof size == "array")
      img = $"{img}:{size[0].tointeger()}:{size[1].tointeger()}:K"
  }
  return {
    rendObj = ROBJ_IMAGE
    size = flex()
    keepAspect = true
    image = ::Picture(img)
  }.__update(override)
}

local squadBgColor = @(flags, selected, hasAlertStyle = false)
  selected ? activeBgColor
    : flags & S_HOVER ? hoverBgColor
    : hasAlertStyle ? Color(30,0,0,150) : defBgColor


local blockActiveBgColor = ::mul_color(activeBgColor, 0.5)
local blockHoverBgColor = ::mul_color(hoverBgColor, 0.5)
local squadBlockBgColor = @(flags, isSelected)
  isSelected ? blockActiveBgColor
    : flags & S_HOVER ? blockHoverBgColor
    : defBgColor

local mkCardText = @(t, sf, selected) txt({
  text = t
  color = listCtors.txtColor(sf, selected)
})

local mkSquadTypeIcon = @(squadType, sf, selected, size = squadTypeIconSize) {
  padding = [0, smallPadding]
  children = {
    size = size
    rendObj = ROBJ_IMAGE
    image = ::Picture("{0}:{1}:{2}:K".subst(getSquadTypeIcon(squadType), size[0].tointeger(), size[1].tointeger()))
    keepAspect = true
    color = listCtors.txtColor(sf, selected)
  }
}

local mkActiveBlock = @(sf, selected, content) {
  rendObj = ROBJ_SOLID
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  color = squadBlockBgColor(sf, selected)
  children = content
}

local mkSquadUnits = @(amount, squadType, sf, selected, addedRightObj, mkChild = null) {
  size = flex()
  children = [
    addedRightObj
    mkChild?(sf, selected)
    mkActiveBlock(sf, selected, mkSquadTypeIcon(squadType, sf, selected))
      .__update({
        hplace = ALIGN_LEFT
        vplace = ALIGN_BOTTOM
      })
    mkActiveBlock(sf, selected,
      [
        mkCardText(amount, sf, selected)
        mkCardText(fa["user-o"], sf, selected).__update({
          rendObj = ROBJ_STEXT
          font = Fonts.fontawesome
          fontSize = hdpx(12)
        })
      ]).__update({
        padding = smallPadding
        gap = ::hdpx(3)
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
      })
  ]
}

local mkSquadLevel = @(level, sf, selected) level == null ? null
  : mkActiveBlock(sf, selected,
      mkCardText(::loc("level/short", { level = level + 1 }), sf, selected)
        .__update({ margin = smallPadding }))

local mkSquadPremIcon = @(premIcon, override = null) premIcon == null ? null : {
  rendObj = ROBJ_IMAGE
  size = premIconSize
  keepAspect = true
  image = ::Picture($"{premIcon}:{premIconSize[0].tointeger()}:{premIconSize[1].tointeger()}:K")
}.__update(override ?? {})

local mkSquadCard = ::kwarg(function (idx, isSelected, addChild = null, icon = "",
  name = null, squadType = null, squadSize = null, level = null, isFaded = false,
  premIcon = null, onClick = null, addedRightObj = null, mkChild = null
) {
  local stateFlags = ::Watched(0)
  local selected = isSelected.value
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon

  return function() {
    local sf = stateFlags.value
    return {
      rendObj = ROBJ_SOLID
      size = multySquadPanelSize
      color = squadBgColor(sf, selected)
      key = $"squad{idx}"
      behavior = Behaviors.Button
      xmbNode = ::XmbNode()
      opacity = isFaded ? 0.7 : 1.0
      onElemState = @(nsf) stateFlags(nsf)
      onClick = onClick
      watch = stateFlags
      children = [
        mkSquadIcon(icon, {
          size = multySquadPanelSize.map(@(val) val * ICON_SCALE)
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
        })
        mkSquadUnits(squadSize, squadType, sf, selected, addedRightObj, mkChild)
        premIcon != null
          ? mkSquadPremIcon(premIcon, { margin = [0, ::hdpx(6)] })
          : mkSquadLevel(level, sf, selected)
      ].append(addChild)
    }
  }
})


return {
  mkSquadCard = mkSquadCard
  mkSquadIcon = mkSquadIcon
  mkSquadTypeIcon = mkSquadTypeIcon
  mkSquadPremIcon = mkSquadPremIcon
  squadBgColor = squadBgColor
  mkCardText = mkCardText
  mkActiveBlock = mkActiveBlock
  mkSquadSpawnIcon = mkSquadSpawnIcon
  mkSquadSpawnDesc = mkSquadSpawnDesc
}
 