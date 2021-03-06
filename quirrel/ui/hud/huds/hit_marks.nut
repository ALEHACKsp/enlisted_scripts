local {Point3} = require("dagor.math")
local {cos, sin, PI} = require("math")
local {hitMarks, downedColor, hitColor, killColor, killSize, hitSize, killTtl, hitTtl, showWorldKillMark} = require("ui/hud/state/hit_marks_es.nut")
local u = require("std/underscore.nut")
local {HIT_RES_DOWNED, HIT_RES_KILLED, HIT_RES_NORMAL} = require("dm")

local animations = [
  { prop=AnimProp.opacity, from=0.2, to=1, duration=0.1, play=true, easing=InCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop = AnimProp.scale, from =[0.25, 0.25], to = [1, 1], duration = 0.1, easing = InCubic, play = true}
]

local function mkAnimations(duration=0.4, appearPart = 0.15, stayPart = 0.25, fadePart = 0.65){
  duration = min(duration, 100)
  local appearDur = appearPart*duration
  local stayDur = stayPart*duration
  local fadeDur = fadePart*duration
  return [
    { prop=AnimProp.opacity, from=0.1, to=1.0, duration=appearDur, play=true, easing=InCubic, onExit="fadeOut"}
    { prop=AnimProp.scale, from=[0.75, 0.75], to = [1, 1], duration = appearDur*1.5, easing = InQuart }
    { prop=AnimProp.opacity, from=1.0, to=0.0, delay = stayDur, duration=fadeDur, easing = InCubic, trigger = "fadeOut", onExit="faded"}
    { prop=AnimProp.opacity, from=0.0, to=0.0, duration=max(duration*3,100), trigger = "faded"}//just huge number to keep it hided, until it removed

    { prop=AnimProp.scale, from=[1,1], to=[1.2,1.2], duration=0.15, playFadeOut=true, easing = InOutCubic, onExit = "fadeMore"}
  ]
}

local function build_hitmarks_commands(marksCount) {
  local commands = [[VECTOR_WIDTH, ::hdpx(1.8)]]
  local markSize = 100
  local percentile = 0.5
  local initAngle = PI * 0.5 / (marksCount + 1);
  local center = {
    x = 50
    y = 50
  }
  for (local markId = 0; markId < marksCount; ++markId) {
    //four lines for each mark
    for (local i = 0; i < 2; ++i) {
      local angle = initAngle*(markId + 1) - PI*0.5*i
      local c = cos(angle)
      local s = sin(angle)
      for (local j = -1; j <= 1; j += 2) {
        local coor = {
          x = markSize * c * j
          y = markSize * s * j
        }
        commands.append([VECTOR_LINE,
          center.x + coor.x * percentile, center.y + coor.y * percentile,
          center.x + coor.x, center.y + coor.y])
      }
    }
  }
  return commands
}

const maxHitCount = 1
local hitHairMap = {}
for(local i = 1; i <= maxHitCount; i += 2)
  hitHairMap[i] <- build_hitmarks_commands(i)

local simpleHitMark = hitHairMap[1]


local hitMarkParams
local posHitMarksParams
local showWorldKillMarkCached
local function updateLocalCache(...){
  local commonHitMarkAnims = mkAnimations(hitTtl.value/3.0) //this is needed because of different time scale. Hitmarks can disappear with not smooth animation
  local commonKillMarkAnims = mkAnimations(killTtl.value/3.0)
  hitMarkParams = {
    [HIT_RES_NORMAL] = {size = hitSize.value, color = hitColor.value, animations = commonHitMarkAnims},
    [HIT_RES_DOWNED] = {size = killSize.value, color = downedColor.value, animations = commonHitMarkAnims},
    [HIT_RES_KILLED] = {size = killSize.value, color = killColor.value, animations = commonKillMarkAnims}
  }
  showWorldKillMarkCached = showWorldKillMark.value
  posHitMarksParams = {
    [HIT_RES_NORMAL] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = hitSize.value transform = {} color = hitColor.value},
    [HIT_RES_DOWNED] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = killSize.value transform = {} color = downedColor.value},
    [HIT_RES_KILLED] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = killSize.value transform = {} color = killColor.value},
  }
}
{
  [downedColor, hitColor, killColor, killSize, hitSize, killTtl, hitTtl, showWorldKillMark]
    .map(@(v) v.subscribe(updateLocalCache))
    .each(@(v) v.trigger())
}
/*
  TODO:
   - to show multiple shots (very fast weapons or grenade or shortgun it is better to show some elements like in WT or Apex
   - melee probably can looks better when shown as kill Marks in World, espically in TPS view
  Notes:
  - animations could possible be better if made with transitions. however currently it's fine

*/
local currentHitMark = Watched(null)
local posHitMarks = Watched([])

local function isPositionalHitMark(v){
  if (v?.hitPos==null)
    return false
  if (showWorldKillMarkCached){
    return v?.isMelee || (!v?.isKillHit && !v?.isDownedHit)
  }
  return v?.isMelee
}
local function updateHitMarks(hitMarksRes){
  local res = u.partition(hitMarksRes, isPositionalHitMark)
  posHitMarks(res[0])
  local hitms = res[1]
  currentHitMark((hitms?.len() ?? 0)>0 ? hitms?[hitms.len()-1] : null)
}
hitMarks.subscribe(updateHitMarks).trigger()

local function hitHair() {
  local curHitMark = currentHitMark.value
  local key = curHitMark?.id ?? {}
  return {
    watch = [hitMarks]
    size = SIZE_TO_CONTENT
    children = {
      rendObj = ROBJ_VECTOR_CANVAS
      transform = {}
      key = key
      commands = curHitMark!=null ? simpleHitMark : null
    }.__update(hitMarkParams?[curHitMark?.hitRes] ?? hitMarkParams[HIT_RES_NORMAL])
  }
}

local function mkPosHitMark(mark){
  local pos = mark.hitPos
  return {
    data = {
      minDistance = 0.1
      clampToBorder = true
      worldPos = Point3(pos[0], pos[1], pos[2])
    }
    animations = animations
    transform = {}
    children = posHitMarksParams?[mark?.hitRes] ?? posHitMarksParams[HIT_RES_NORMAL]
    key = mark?.id ?? {}
  }
}

local function posHitMarksComp() {
  return {
    watch = [posHitMarks]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [sw(100), sh(100)]
    children = posHitMarks.value.map(mkPosHitMark)
    behavior = Behaviors.Projection
  }
}

return {
  hitMarks = hitHair
  posHitMarks = posHitMarksComp
  _updateLocalCache = updateLocalCache
}
 