local {spawn_zone_markers} = require("enlisted/ui/hud/state/spawn_zones_markers.nut")
local {verPadding, horPadding} = require("globals/safeArea.nut")
local {secondsToTimeSimpleString} = require("utils/time.nut")
local {bigPadding, smallPadding, blurBgColor} = require("enlisted/enlist/viewConst.nut")
local txt = require("ui/components/text.nut")
local textarea = require("ui/components/textarea.nut")
local {mkCountdownTimerPerSec} = require("ui/helpers/timers.nut")
local { isGamepad } = require("ui/control/active_controls.nut")
local { missionName } = require("enlisted/ui/hud/state/mission_params.nut")
local { isFirstSpawn, spawnCount, spawnSquadId, squadIndexForSpawn,
        squadsList, curSquadData, canSpawnCurrent, canSpawnCurrentSoldier, vehicleRespawnsBySquad,
        canUseRespawnbaseByType } = require("enlisted/ui/hud/state/respawnState.nut")
local { localPlayerTeamSquadsCanSpawn, localPlayerTeamInfo } = require("enlisted/ui/hud/state/teams.nut")

local {respawnTimer, forceSpawnButton, panel, headerBlock} = require("enlisted/ui/hud/respawn_parts.nut")
local respawnSquadInfoUi = require("respawn_squad_info.ui.nut")
local {mkCurSquadsList} = require("enlisted/enlist/soldiers/mkSquadsList.nut")
local squadsUiComps = require("enlisted/enlist/soldiers/components/squadsUiComps.nut")
local { mkHotkey } = require("ui/components/uiHotkeysHint.nut")


local blocksGap = smallPadding

local bgConfig = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  padding = bigPadding
  color = blurBgColor
}

local function spawnsLeftText() {
  local maxSpawn = localPlayerTeamInfo.value?["team.eachSquadMaxSpawns"] ?? 0
  return {
    size = [flex(), SIZE_TO_CONTENT]
    watch = [spawnCount, localPlayerTeamInfo]
    children = maxSpawn <= 0 ? null
      : textarea(::loc("respawn/leftRespawns", { num = maxSpawn - spawnCount.value }),
          {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            font = Fonts.small_text
          })
  }
}

local vehicleIcon = {
  rendObj = ROBJ_IMAGE
  size = [hdpx(28), hdpx(28)]
  image = ::Picture("ui/skin#tank_icon.svg")
}

local curVehicle = ::Computed(@() curSquadData.value?.vehicle)
local maxSpawnVehiclesOnPoint = ::Computed(@() vehicleRespawnsBySquad.value?[squadIndexForSpawn.value].maxSpawnVehiclesOnPoint ?? -1)
local respInVehicleEndTime = ::Computed(@() vehicleRespawnsBySquad.value?[squadIndexForSpawn.value].respInVehicleEndTime ?? -1.0)
local timeToCanRespawnOnVehicle = mkCountdownTimerPerSec(respInVehicleEndTime)

local vehicleSpawnText = ::Computed(function() {
    local time = timeToCanRespawnOnVehicle.value
    local limit = maxSpawnVehiclesOnPoint.value
    local vehicle = curVehicle.value
    if (vehicle == null)
      return ""
    if (time > 0)
      return "{0}{1}".subst(::loc("respawn/timeToSpawn"), secondsToTimeSimpleString(time))
    if (limit > 0)
      return "{0}/{0}{1}".subst(limit, ::loc("respawn/vehicleUsed"))
    return ""
})

local vehicleSpawnInfoBlock = @() {
  watch = vehicleSpawnText
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = vehicleSpawnText.value.len() > 0
    ? [
        vehicleIcon
        txt(vehicleSpawnText.value, { font = Fonts.small_text })
      ]
    : null
}

local function spawnInfoBlock() {
  local { canSpawn = false, readinessPercent = 0 } = curSquadData.value
  local spawnInfo = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = [
        vehicleSpawnInfoBlock
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = [
            squadsUiComps.mkSquadSpawnIcon(canSpawn, readinessPercent, canSpawnCurrentSoldier.value, hdpx(32).tointeger())
            squadsUiComps.mkSquadSpawnDesc(canSpawn, readinessPercent, canSpawnCurrentSoldier.value)
          ]
        }
      ]
    }
  ]

  local children = !canSpawnCurrent.value ? []
    : localPlayerTeamSquadsCanSpawn.value
      ? [
          respawnTimer(::loc("respawn/respawn_squad"), { font = Fonts.small_text })
          forceSpawnButton({})
          spawnsLeftText
        ]
      : [
          textarea(::loc("respawn/no_spawn_scores"), {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            font = Fonts.small_text
          })
        ]

  return {
    watch = [curSquadData, localPlayerTeamSquadsCanSpawn, canSpawnCurrent, canSpawnCurrentSoldier]
    minHeight = fontH(370) //timer appears and change size
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    gap = bigPadding
    children = children.extend(spawnInfo)
  }
}

local changeSquadParams = ::Computed(function() {
  local squadId = spawnSquadId.value
  local idx = squadsList.value.findindex(@(s) s.squadId == squadId) ?? -1
  return {
    idx = idx
    canPrev = idx > 0
    canNext = idx < squadsList.value.len() - 1
  }
})

local function changeSquad(dir) {
  local idx = changeSquadParams.value.idx + dir
  if (idx in squadsList.value)
    spawnSquadId(squadsList.value[idx].squadId)
}

local squadShortcuts = @() {
  watch = [isGamepad, changeSquadParams]
  flow = FLOW_HORIZONTAL
  children = !isGamepad.value ? null
    : [
        mkHotkey("^J:LB", @() changeSquad(-1), { opacity = changeSquadParams.value.canPrev ? 1.0 : 0.5 })
        mkHotkey("^J:RB", @() changeSquad(1), { opacity = changeSquadParams.value.canNext ? 1.0 : 0.5 })
      ]
}

local squadsListUI = mkCurSquadsList({
  curSquadsList = ::Computed(@() squadsList.value
    .map(@(s) s.__merge({ addedRightObj = squadsUiComps.mkSquadSpawnIcon(s.canSpawn, s.readinessPercent) })))
  curSquadId = spawnSquadId
  bgOverride = { rendObj = null, padding = 0 }
  addedObj = squadShortcuts
})

local squadSpawnList = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        squadsListUI
        @() respawnSquadInfoUi.__update({ padding = 0, rendObj = null })
      ]
    }
    spawnInfoBlock
  ]
}.__update(bgConfig)


local squadRespawn = panel(
  {
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    gap = blocksGap
    children = [
      headerBlock(isFirstSpawn.value
        ? ::loc("respawn/shooseSquad")
        : ::loc("respawn/squadIsDead")).__update(bgConfig)
      squadSpawnList
    ]
  }
  {
    rendObj = null
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_HORIZONTAL
    gap = blocksGap
  }
)

local titlePadding = sh(4)
local missionNameUI = @() {
  rendObj = ROBJ_DTEXT
  text = ::loc(missionName.value)
  font = Fonts.huge_text
  margin = [verPadding.value + titlePadding, horPadding.value + titlePadding]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  watch = [verPadding, missionName]
  fontFxColor = Color(0, 0, 0, 180)
  fontFxFactor = min(64, hdpx(64))
  fontFx = FFT_GLOW
}


local selectSpawnTitle = @() {
  rendObj = ROBJ_DTEXT
  text = ::loc("select_spawn")
  font = Fonts.big_text
  fontFxColor = Color(0, 0, 0, 90)
  fontFxFactor = min(64, hdpx(64))
  fontFx = FFT_GLOW
}
local isThereSpawnZones = Computed(@() spawn_zone_markers.value.values().map(function(v) {
  local iconType = v?.iconType
  if (canUseRespawnbaseByType.value != iconType)
    throw null
  return iconType
}).len()>0)

local showSpawnHint = Computed(@() !isFirstSpawn.value && isThereSpawnZones.value)

local selectSpawnHint = @(){
  watch = [showSpawnHint, verPadding]
  hplace = ALIGN_CENTER
  pos = [0, verPadding.value + sh(16)]
  children = showSpawnHint.value ? selectSpawnTitle : null
}
return {
  children = [
    squadRespawn
    selectSpawnHint
    missionNameUI
  ]
  size = flex()
}
 