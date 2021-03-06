local {DM_PROJECTILE, DM_MELEE, DM_EXPLOSION, DM_ZONE, DM_COLLISION, DM_HOLD_BREATH, DM_FIRE, DM_BACKSTAB, DM_BARBWIRE} = require("dm")
local {tostring_r} = require("std/string.nut")
local {killLogState} = require("ui/hud/state/eventlog.nut")
local namePrefixIcons = require("ui/style/namePrefixIcons.nut")
local platform = require("globals/platform.nut")
local style = require("ui/hud/style.nut")
local defTextColor = style.DEFAULT_TEXT_COLOR
local mySquadColor = style.MY_SQUAD_TEXT_COLOR
local teamColor = style.TEAM0_TEXT_COLOR
local enemyColor = style.TEAM1_TEXT_COLOR


local function textElem(text, color=null) {
  return {
    rendObj = ROBJ_DTEXT
    font = platform.is_console
                        ? Fonts.medium_text
                        : Fonts.small_text
    text = text
    color = color
  }
}

local fontLogSize = ::calc_comp_size(textElem("A"))[1]
local killIconHeight = (fontLogSize*0.9).tointeger()

local killIconsHeadshot = "killlog/kill_headshot.svg"

local damageTypeIcons = {
  [DM_PROJECTILE]  = null, //no need for icon in this case
  [DM_MELEE]       = "killlog/kill_melee.svg",
  [DM_EXPLOSION]   = "killlog/kill_explosion.svg",
  [DM_ZONE]        = "killlog/kill_zone_wh.svg",
  [DM_COLLISION]   = "killlog/kill_collision.svg",
  [DM_HOLD_BREATH] = "killlog/kill_asphyxia.svg",
  [DM_BACKSTAB]    = "killlog/kill_backstab.svg",
  [DM_FIRE]        = "killlog/kill_fire.svg",
  [DM_BARBWIRE]    = null
}

local getPicture = ::memoize(@(name) name!=null ? ::Picture("!ui/skin#{0}:{1}:{1}:K".subst(name, killIconHeight)) : null)

local mkIcon = ::memoize(function(image){
  return image != null ? {
    size = [fontLogSize, fontLogSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = [
      {
        rendObj = ROBJ_IMAGE
        image = image
        size = [SIZE_TO_CONTENT, fontLogSize*1.2]
      }
    ]
  } : null
})

local function mkKillEventIcon(data) {
  local image = null
  if (data?.nodeType == "head" && data?.damageType == DM_PROJECTILE) {
    image = getPicture(killIconsHeadshot)
  } else {
    image = getPicture(damageTypeIcons?[data?.damageType])
  }
  return mkIcon(image)
}

local killMsgAnim = [
  { prop=AnimProp.scale, from=[1,0.01], to=[1,1], duration=0.2, play=true, easing=OutCubic }
]
local blurColor = Color(170,170,170,170)
local function blurBack(){
  local children = {rendObj=ROBJ_WORLD_BLUR_PANEL size=flex() color = blurColor}
  return {
    children = children
    size = flex()
  }
}

local function nameAndColor(entity, is_killer = false) {//entity here is just table with description
  local name = entity?.name
  local prefixIcon = entity?.namePrefixIcon
  local color = enemyColor
  local icon = prefixIcon && prefixIcon !="" ? namePrefixIcons?[prefixIcon]  : null
  if (entity?.isHero) {
    name = ::loc("log/local_player")
    color = mySquadColor
  } else if (entity?.inMyTeam) {
    name = name != null ? ::loc(name)
      : entity.inMySquad ? ::loc("log/squadmate")
      : ::loc("log/teammate")
    color = (entity?.inMySquad ? mySquadColor : teamColor)
  } else if (is_killer && name != null && ("player_eid" in entity) && entity.player_eid == INVALID_ENTITY_ID) {
    name = ::loc(name)
  } else {
    name = name != null ? ::loc(name) : ::loc("log/enemy")
  }
  return {name=name, color=color, icon=icon}
}
local margin = [fontLogSize/4.0, 0]
local padding = [0,hdpx(2),0,hdpx(2)]

local function message(data) {
  local children = null
  local gunInfo = {
    flow = FLOW_HORIZONTAL
    gap = ::hdpx(5)
    children = [
      data?.gunName ? textElem(::loc(data.gunName), defTextColor) : null
      mkKillEventIcon(data)
    ]
  }
  if (data?.victim?.eid == data?.killer?.eid && data?.victim?.eid != null) {
    local info = nameAndColor(data.victim)
    children = data.victim.isHero
      ? [ textElem(::loc("log/local_player_suicide"), info.color) ]
      : [ textElem(::loc("log/player_suicide", {user=info.name}), info.color) ]
        .append(gunInfo)
  } else if (!(data?.victim?.isAlive ?? true)) {
    local victimInfo = nameAndColor(data.victim)
    local killerInfo = nameAndColor(data.killer, /* is_killer */ true)
    children = [
      mkIcon(getPicture((data?.killerAbility ?? "" ) != "" ? "ability/{0}.svg".subst(data?.killerAbility) : null))
      {
        flow = FLOW_HORIZONTAL
        gap = ::hdpx(5)
        children = [
          mkIcon(getPicture(killerInfo?.icon))
          textElem(killerInfo.name, killerInfo.color)
        ]
      }
      gunInfo
      textElem(victimInfo.name, victimInfo.color)
    ]

  } else if (data?.victim?.isDowned ?? false ) {
    local info = nameAndColor(data.victim)
    children = [
      data.victim.isHero
        ? textElem(::loc("log/local_player_downed"), mySquadColor)
        : textElem(::loc("log/player_downed", {user = info.name}), info.color)
    ]
  } else { //debug test message
    children = [
      textElem(data?.text ?? tostring_r(data))]
  }

  return {
    size = SIZE_TO_CONTENT
    children = [
      blurBack
      {
        size = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        halign = ALIGN_RIGHT
        valign = ALIGN_CENTER
        children = children
        margin = margin
        gap = ::hdpx(9)
        padding = padding
        key = data
        transform = {
          pivot = [0, 0.5]
        }
        animations = killMsgAnim
      }
    ]
  }
}

local itemAnim = [
  //{ prop=AnimProp.color, from=style.MESSAGE_BG_START, to=style.MESSAGE_BG_END,
  //    duration=0.5, play=true }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true}
  { prop=AnimProp.scale, from=[1,1], to=[1,0], duration=0.2, playFadeOut=true}
]

local function killLogRoot() {
  local children = killLogState.events.value.map(
    @(item) {
      size = SIZE_TO_CONTENT
      key = item
      color = style.MESSAGE_BG_END
      children = [message(item)]
      transform = {
        pivot = [0, 0]
      }
      animations = itemAnim
    }
  )

  return {
    size   = [sh(30), sh(50)]
//    color  = Color(50,50,50,50)
    halign = ALIGN_RIGHT
    behavior = Behaviors.SmoothScrollStack
    speed = sh(20)
    watch = killLogState.events
    children = children
  }
}

::console.register_command(@()  killLogState.pushEvent({text="TEST kill message Ä" }), "ui.killog")

return killLogRoot
 