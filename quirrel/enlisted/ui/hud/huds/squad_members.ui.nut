local {AI_ACTION_UNKNOWN, AI_ACTION_STAND, AI_ACTION_HEAL,
  AI_ACTION_HIDE, AI_ACTION_MOVE, AI_ACTION_ATTACK, order_squad_start_artillery_strike} = require("ai")
local { fabs } = require("math")
local {
  watchedHeroSquadMembers, HEAL_RES_COMMON, HEAL_RES_REVIVE
} = require("enlisted/ui/hud/state/squad_members.nut")
local { controlledHeroEid, isDowned } = require("ui/hud/state/hero_state_es.nut")
local { inVehicle } = require("ui/hud/state/vehicle_state.nut")
local { HUD_TIPS_FAIL_TEXT_COLOR, SUCCESS_TEXT_COLOR, DEFAULT_TEXT_COLOR, DEAD_TEXT_COLOR } = require("ui/hud/style.nut")
local { canChangeRespawnParams } = require("enlisted/ui/hud/state/respawnState.nut")
local soldiers = require("enlisted/ui/hud/state/soldiersData.nut")
local orderItem = require("squad_order_item.nut")
local { classIcon } = require("enlisted/enlist/soldiers/components/soldiersUiComps.nut")
local memberHpBlock = require("squad_member_health_sign.ui.nut")
local {playerEvents} = require("ui/hud/state/eventlog.nut")
local { secondsToStringLoc } = require("utils/time.nut")
local { artilleryIsAvailable, artilleryAvailableTimeLeft, artilleryIsReady, isHeroRadioman
} = require("enlisted/ui/hud/state/artillery.nut")
local grenadeIcon = require("ui/hud/huds/player_info/grenadeIcon.nut")
local {HIT_RES_KILLED, HIT_RES_DOWNED, HIT_RES_NORMAL} = require("dm")

local sIconSize = ::hdpx(15).tointeger()
local iconSize = ::hdpx(40).tointeger()
local gap = ::hdpx(5)
local smallGap = ::hdpx(2)


local wasKills = {}
local function updateKillsAnim() {
  local kills = {}
  foreach(m in watchedHeroSquadMembers.value ?? []) {
    kills[m.eid] <- m.kills
    if (m.kills > (wasKills?[m.eid] ?? 0))
      ::anim_start($"member_kill_{m.eid}")
  }
  wasKills = kills
}
updateKillsAnim()
watchedHeroSquadMembers.subscribe(@(_) updateKillsAnim())

local function show_artillery_cooldown_hint(){
  local timeLeft = artilleryAvailableTimeLeft.value
  if (timeLeft <= 0)
    return
  local timeLeftStr = secondsToStringLoc(timeLeft)
  playerEvents.pushEvent({
    text = ::loc("artillery/cooldown", {timeLeft = timeLeftStr})
    color = HUD_TIPS_FAIL_TEXT_COLOR
  })
}

local function order_start_artillery_strike(eid) {
  if (isDowned.value)
    return
  if (artilleryIsReady.value){
    if (isHeroRadioman.value) {
      ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.CmdArtillerySelfOrder())
    } else {
      order_squad_start_artillery_strike(eid)
    }
  } else
    show_artillery_cooldown_hint()
}

local artilleryAvailableTimeLeftComp = @(){
  watch = artilleryAvailableTimeLeft
  rendObj = ROBJ_DTEXT
  color = Color(255, 255, 255)
  text = secondsToStringLoc(artilleryAvailableTimeLeft.value)
  font = Fonts.medium_text
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

local artilleryOrder = orderItem({
  hotkey = "Human.ArtilleryStrike"
  text = ::loc("squad_orders/artillery_strike", "Artillery strike!")
  handler = order_start_artillery_strike
  showIfNoHotkey = false
})

local artilleryIconHgt = calc_comp_size(artilleryOrder)[1]
local artilleryIcon = ::Picture("ui/skin#artillery_strike.svg:{0}:{0}:K".subst(artilleryIconHgt))
local artilleryIconComp = @() {
  rendObj = ROBJ_IMAGE
  image = artilleryIcon
  color = artilleryIsReady.value ? Color(255, 255, 255) : Color(120, 120, 120, 200)
  watch = artilleryIsReady
}

local artilleryOrderFull = @(){
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  watch = [artilleryIsReady, artilleryIsAvailable]
  gap = gap
  valign = ALIGN_CENTER
  children = artilleryIsAvailable.value
    ? [
        artilleryOrder
        artilleryIsReady.value ? artilleryIconComp : artilleryAvailableTimeLeftComp
      ]
    : null
}

local blurBack = {
  size = flex()
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = Color(220, 220, 220, 220)
}

local animByTrigger = @(color, time, trigger) trigger
  ? { prop=AnimProp.color, from=color, easing=OutCubic, duration=time, trigger=trigger }
  : null

local function statusIcon(member, isSelf, addChild = null) {
  local soldier = soldiers.value?[member.guid]
  return {
    size = [iconSize, iconSize]
    children = [
      blurBack
      {
        size = flex()
        rendObj = ROBJ_SOLID
        color = 0
        animations = [
          animByTrigger(Color(200, 0, 0, 200), 1.0, member?.hitTriggers[HIT_RES_NORMAL])
          animByTrigger(Color(200, 100, 0, 200), 3.0, member?.hitTriggers[HIT_RES_DOWNED])
          animByTrigger(Color(200, 0, 0, 200), 3.0, member?.hitTriggers[HIT_RES_KILLED])
          animByTrigger(Color(0, 200, 100, 200), 1.0, member?.hitTriggers[HEAL_RES_COMMON])
          animByTrigger(Color(0, 100, 200, 200), 3.0, member?.hitTriggers[HEAL_RES_REVIVE])
        ]
        children = member.isAlive
          ? classIcon(soldier?.sClass, iconSize, soldier?.sClassRare).__update({
              color = isSelf ? SUCCESS_TEXT_COLOR : DEFAULT_TEXT_COLOR
              vplace = ALIGN_CENTER
            })
          : {
              rendObj = ROBJ_IMAGE
              size = flex()
              vplace = ALIGN_CENTER
              image = ::Picture("ui/skin#lb_deaths")
              tint = DEAD_TEXT_COLOR
            }
      }
      addChild
    ]
  }
}

local getGrenadeIcon = function(member) {
  local gType = member.grenadeType
  return member.isAlive && gType != null
    ? {
        rendObj = ROBJ_IMAGE
        image = grenadeIcon(gType, [sIconSize, sIconSize])
        tint = ::Color(220, 220, 220)
      }
    : null
}

local aiActionIcons = {
  [AI_ACTION_UNKNOWN] = null,
  [AI_ACTION_STAND]   = "stand_icon.svg",
  [AI_ACTION_HEAL]    = "healing_icon.svg",
  [AI_ACTION_HIDE]    = "hide_tree_icon.svg",
  [AI_ACTION_MOVE]    = "move_icon.svg",
  [AI_ACTION_ATTACK]  = "attack_icon.svg",
}

local function getAiActionIcon(member) {
  local image = aiActionIcons?[member.currentAiAction]
  if (member.eid == controlledHeroEid.value || !member.isAlive || !image)
    return null

  return {
    size = [sIconSize, sIconSize]
    rendObj = ROBJ_IMAGE
    image = ::Picture("ui/skin#{0}:{1}:{1}:K".subst(image, sIconSize))
  }
}

local function splitOnce(name) {
  local idx = name.indexof(" ")
  local found = null
  local minDist = name.len()
  local middle = minDist / 2
  while (idx != null) {
    local dist = fabs(middle - idx)
    if (dist < minDist) {
      found = idx
      minDist = dist
    }
    idx = name.indexof(" ", idx + 1)
  }
  return found == null
    ? name
    : $"{name.slice(0, found)}\n{name.slice(found + 1)}"
}

local memberName = @(member) {
  size = [SIZE_TO_CONTENT, iconSize]
  valign = ALIGN_CENTER
  clipChildren = true
  children = [
    blurBack
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      font = Fonts.tiny_text
      text = splitOnce(member.name)
      color = SUCCESS_TEXT_COLOR
      indent = gap
      transform = {}
      animations = [
        { prop = AnimProp.translate, from = [-::hdpx(100), 0], to = [0, 0], duration = 0.2, easing = OutCubic, play = true }
      ]
    }
  ]
}

local statusRow = @(member) {
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = smallGap
  children = [
    getAiActionIcon(member)
    getGrenadeIcon(member)
  ]
}

local killRow = @(member) {
  key = member.eid
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = smallGap
  children = [
    {
      size = [sIconSize, sIconSize]
      rendObj = ROBJ_IMAGE
      image = ::Picture("ui/skin#kills_icon.svg:{0}:{0}:K".subst(sIconSize))
    }
    {
      children = [
        blurBack
        {
          minWidth = sIconSize
          halign = ALIGN_CENTER
          rendObj = ROBJ_DTEXT
          font = Fonts.tiny_text
          color = DEFAULT_TEXT_COLOR
          text = member.kills

          animations = [{ prop = AnimProp.color, from = SUCCESS_TEXT_COLOR, to = DEFAULT_TEXT_COLOR,
            duration = 5, easing = InOutCubic, trigger = $"member_kill_{member.eid}" }]
        }
      ]
    }
  ]

  transform = {}
  animations = [{ prop = AnimProp.scale, from = [1,1], to = [2,2], duration = 0.5, easing = CosineFull,
      trigger = $"member_kill_{member.eid}" }]
}

local function memberUi(member) {
  local isSelf = member.eid == controlledHeroEid.value
  local isAliveAI = !isSelf && member.isAlive && member.hasAI
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_TOP
    children = [
      {
        size = [iconSize, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = smallGap
        children = [
          statusIcon(member, isSelf, isAliveAI ? memberHpBlock(member) : null)
          killRow(member)
          statusRow(member)
        ]
      }
      isSelf && member.isAlive ? memberName(member) : null
    ]
  }
}

local squadMembersList = @(squadMembersV) {
  flow = FLOW_HORIZONTAL
  gap = gap
  children = squadMembersV.map(memberUi)
}

local function members() {
  local res = { watch = [watchedHeroSquadMembers, canChangeRespawnParams, controlledHeroEid, inVehicle] }
  if ((watchedHeroSquadMembers.value?.len() ?? 0) <= 1 || canChangeRespawnParams.value)
    return res

  return res.__update({
    flow = FLOW_VERTICAL
    gap = gap
    children = [
      inVehicle.value ? null : squadMembersList(watchedHeroSquadMembers.value)
      artilleryOrderFull
    ]
  })
}

::ecs.register_es("artillery_hero_show_cooldown_hint_es",
  {
    [::ecs.sqEvents.CmdShowArtilleryCooldownHint] = @(evt, eid, comp) show_artillery_cooldown_hint()
  },
  { comps_rq = ["player"] },
  { tags="gameClient" }
)

console.register_command(function(hitr) {
  local trigger = watchedHeroSquadMembers.value?.top().hitTriggers[hitr]
  if (trigger != null)
    ::anim_start(trigger)
}, "hud.debugHitMember")

console.register_command(
  function() {
    local member = watchedHeroSquadMembers.value?.top()
    if (member != null)
      ::anim_start($"member_kill_{member.eid}")
  }
  "hud.debugMemberKills")

return members
 