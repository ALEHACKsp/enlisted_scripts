local navState = require("enlist/navState.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")
local style = require("enlisted/enlist/viewConst.nut")
local mkSquadPromo = require("mkSquadPromo.nut")
local { squadsCfgById } = require("model/config/squadsConfig.nut")
local { openChooseSquadsWnd } = require("model/chooseSquadsState.nut")

local {
  curArmy, curArmyData, armySquadsById, curArmyLimits, curChoosenSquads
} = require("model/state.nut")
local {
  curArmySquadsUnlocks, curUnlockedSquadId, unlockSquad, viewSquadId,
  curArmyNextUnlockLevel, forceScrollToLevel
} = require("model/armyUnlocksState.nut")

local bigPadding = style.bigPadding

local viewData = ::Computed(function() {
  local squadId = viewSquadId.value
  if (squadId == null)
    return null
  local armyId = curArmy.value
  local squad = armySquadsById.value?[armyId][squadId]
  if (squad == null)
    return null
  local squadCfg = squadsCfgById.value?[armyId][squadId]
  if (squadCfg == null)
    return null
  return { armyId, squadId, squad, squadCfg }
})

local function open(squad) {
  local squadId = squad?.value.squadId
  if (squadId != null)
    viewSquadId(squadId)
}

local function close() {
  viewSquadId(null)
  curUnlockedSquadId(null)
}

local function closeAndKeepLevel() {
  local unlock = curArmySquadsUnlocks.value
    .findvalue(@(u) u.unlockType == "squad" && u.unlockId == viewSquadId.value)
  forceScrollToLevel(unlock?.level)
  close()
}

local saBorders = safeAreaBorders.value
local function unlockSquadWnd() {
  if (viewData.value == null)
    return null

  local { armyId, squadId, squad, squadCfg } = viewData.value
  local ctor = curUnlockedSquadId.value == null
    ? mkSquadPromo.mkSquadBigCard
    : mkSquadPromo.mkSquadUnlockCard
  local maxChoosenSquadsCount = curArmyLimits.value?.maxSquadsInBattle ?? 0
  local curChoosenSquadsCount = curChoosenSquads.value.len()

  return {
    watch = [viewData, curUnlockedSquadId, curArmyNextUnlockLevel]
    rendObj = ROBJ_BOX
    size = flex()
    vplace = ALIGN_CENTER
    children = {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      size = flex()
      color = Color(150,150,150,255)
      children = [
        ctor({
          squad = squad
          squadCfg = squadCfg
          armyId = armyId
          unlockInfo = ::Computed(function() {
            local armyData = curArmyData.value
            local unlock = curArmySquadsUnlocks.value
              .findvalue(@(u) u.unlockType == "squad" && u.unlockId == squadId)

            if (unlock == null)
              return null

            local reqLevel = unlock.level
            local isNext = curArmyNextUnlockLevel.value == reqLevel
            local canUnlock = armyData.level >= reqLevel && armyData.exp >= unlock.exp
            return squad.locked
              ? {
                  unlockText = !canUnlock ? ::loc("squads/unlockInfo", { level = reqLevel })
                    : !isNext ? ::loc("squads/needUnlockPrev") : ""
                  unlockCb = isNext && canUnlock
                    ? function() {
                        unlockSquad(squadId)
                      }
                    : null
                }
              : null
          })
          cbData = {
            manageBtnLocId = curChoosenSquadsCount < maxChoosenSquadsCount
              ? "btn/addToSquads" : "btn/later"
            manageCb = function() {
              close()
              openChooseSquadsWnd(curArmy.value, squadId, true)
            }
            closeCb = curArmySquadsUnlocks.value?[0].unlockId == squadId
              ? null : closeAndKeepLevel
          }
        })
        curUnlockedSquadId.value == null
          ? closeBtnBase({ onClick = closeAndKeepLevel }).__update({
              margin = [saBorders[0] + bigPadding, saBorders[3] + bigPadding, bigPadding, bigPadding]
            })
          : null
      ]
    }
  }
}

if (viewData.value != null)
  navState.addScene(unlockSquadWnd)

curUnlockedSquadId.subscribe(
  function(val) {
    if (val != null)
      viewSquadId(val)
  }
)

viewData.subscribe(
  function(val) {
    if (val)
      navState.addScene(unlockSquadWnd)
    else
      navState.removeScene(unlockSquadWnd)
  }
)

return {
  open = open
}
 