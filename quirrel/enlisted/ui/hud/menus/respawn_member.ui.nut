local { logerr } = require("dagor.debug")
local JB = require("ui/control/gui_buttons.nut")

local armyData = require("enlisted/ui/hud/state/armyData.nut")
local soldiersData = require("enlisted/ui/hud/state/soldiersData.nut")

local { localPlayerSquadMembers } = require("enlisted/ui/hud/state/squad_members.nut")
local respawnState = require("enlisted/ui/hud/state/respawnState.nut")
local respawnSelection = require("enlisted/ui/hud/state/respawnSelection.nut")

local {squadBlock, headerBlock, panel, respawnTimer, forceSpawnButton} = require("enlisted/ui/hud/respawn_parts.nut")
local {controlledHeroEid} = require("ui/hud/state/hero_state_es.nut")

local forceRespawn = @() respawnState.respRequested(true)

local mkSoldierCard = require("enlisted/enlist/soldiers/mkSoldierCard.nut")
local memberHpBlock = require("enlisted/ui/hud/huds/squad_member_health_sign.ui.nut")

local {CmdNextRespawnEntity} = require("gameevents")

local requestRespawnToEntity = @(eid) ::ecs.g_entity_mgr.sendEvent(controlledHeroEid.value, CmdNextRespawnEntity(eid))

local spawnSquadLocId = ::Computed(function() {
  local guid = localPlayerSquadMembers.value?[0].guid
  local squadsList = armyData.value?.squads
  if (guid == null || (squadsList?.len() ?? 0) == 0)
    return null

  local squad = squadsList.findvalue(
    @(sq) sq.squad.findindex(@(soldier) soldier.guid == guid) != null)
  return squad?.locId
})

local function currentSquadButtons(membersList, activeTeammateEid, infoByGuid) {
  local items = []
  foreach (memberIter in membersList) {
    local member = memberIter
    local soldierInfo = infoByGuid?[member.guid]
    local isCurrent = (member.eid == activeTeammateEid)
    if (!soldierInfo) {
      logerr($"Not found member info for respawn screen {member.guid}")
      continue
    }

    local group = ::ElemGroup()
    local function button(sf) {
      return {
        behavior = member.isAlive ? Behaviors.Button : null
        group = group
        children = mkSoldierCard({
          soldierInfo = soldierInfo
          sf = sf
          group = group
          isSelected = isCurrent
          isDead = !member.isAlive
          addChild = @(s, isSelected) memberHpBlock(member)
        })

        onClick = function() {
          requestRespawnToEntity(member.eid)
          if (isCurrent)
            forceRespawn()
        }
        onDoubleClick = forceRespawn

        animations = [
          {
            prop=AnimProp.fillColor
            from=Color(200,200,200,160)
            duration=0.25
            easing=OutCubic
            trigger=$"squadmate:{member.eid}"
          }
        ]
      }
    }

    items.append(::watchElemState(button))
  }
  return items
}

local memberSpawnList = @() {
  watch = [localPlayerSquadMembers, respawnSelection, soldiersData]
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = sh(40)
  halign = ALIGN_CENTER
  gap = sh(1)
  flow = FLOW_VERTICAL
  children = localPlayerSquadMembers.value ? currentSquadButtons(localPlayerSquadMembers.value, respawnSelection.value, soldiersData.value) : null
}

local function changeRespawn(delta) {
  local alive = []
  local curEid = respawnSelection.value
  local curIdx = 0

  if (localPlayerSquadMembers.value) {
    foreach (entity in localPlayerSquadMembers.value) {
      if (entity.isAlive) {
        alive.append(entity.eid)
        if (entity.eid == curEid) {
          curIdx = alive.len()-1
        }
      }
    }
  }

  if (alive.len()) {
    local idx = (curIdx + delta + alive.len()) % alive.len()
    local eid = alive[idx]
    requestRespawnToEntity(eid)
    ::anim_start($"squadmate:{eid}")
  }
}

local squadInfoBlock = @() {
  watch = spawnSquadLocId
  size = [flex(), SIZE_TO_CONTENT]
  children = squadBlock(::loc(spawnSquadLocId.value ?? "unknown"))
}

local memberRespawn = @() panel(
  [
    headerBlock("\n".concat(::loc("Controlled soldier died."), ::loc("Select another squadmate to control")))
    squadInfoBlock
    memberSpawnList
    forceSpawnButton({ size = [flex(), sh(8)] })
    respawnTimer(::loc("respawn/respawn_in_bot"), { font = Fonts.small_text })
  ],
  {
    hotkeys = [
      ["^Up | J:D.Up", @() changeRespawn(-1)],
      ["^Down | J:D.Down",  @() changeRespawn(1)],
      ["^Enter| {0}".subst(JB.A),  function() {forceRespawn()}]
    ]
  }
)

return memberRespawn

 