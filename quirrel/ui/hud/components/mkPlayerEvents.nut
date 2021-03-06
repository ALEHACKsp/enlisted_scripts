local {DEFAULT_TEXT_COLOR, TEAM0_TEXT_COLOR, TEAM1_TEXT_COLOR, MY_SQUAD_TEXT_COLOR} = require("ui/hud/style.nut")

local defTextAnims = [
  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.33, play=true, easing=OutCubic }
]

local function killEventText(victim){
  local text = null
  if (victim.isHero)
    text = ::loc("log/local_player_suicide")
  else {
//      text = victim.inMyTeam ? "Killed a teammate" : "Killed an enemy"
    local victimName = victim.name ?? (
      victim?.inMyTeam
        ? victim.inMySquad ? ::loc("log/squadmate") : ::loc("log/teammate")
        : null
    )
    local color = victim?.inMyTeam
      ? victim?.inMySquad ? MY_SQUAD_TEXT_COLOR : TEAM0_TEXT_COLOR
      : TEAM1_TEXT_COLOR

    text = (victimName != null)
      ? ::loc("log/eliminated", {user = "<color={0}>{1}</color>".subst(color, victimName)})
      : victim.inMyTeam
        ? ::loc("log/eliminated_teammate")
        : ::loc("log/eliminated_enemy")
  }
  return text
}

local function makeDefText(item) {
  local color = item?.color
  if (("myTeamScores" in item) && color == null)
    color = item.myTeamScores ? TEAM0_TEXT_COLOR : TEAM1_TEXT_COLOR
  color = color ?? DEFAULT_TEXT_COLOR
  local animations = item?.animations ?? defTextAnims
  local text = ::type(item)=="table"
    ? (item?.event=="kill" && "victim" in item)
      ? killEventText(item.victim)
      : item?.text
    : item
  return {
    size = [flex(), SIZE_TO_CONTENT]
    animations = animations
    key = item
    transform = {
      pivot = [0, 1]
    }
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      font = Fonts.big_text
      fontFx = FFT_BLUR
      fontFxColor = Color(0,0,0,50)
      fontFxFactor = 64, fontFxOffsY=hdpx(0.9)
      text = text
      color = color
    }
  }
}

local function makeEventItem(item){
  if ("ctor" in item)
    return item.ctor(item)
  return makeDefText(item)
}

return {
  makeItem = makeEventItem
  mkPlayerEvents = @(eventsState, makeItem = makeEventItem) eventsState.value.map(makeItem)
}

 