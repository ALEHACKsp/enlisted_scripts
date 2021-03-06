local { isGamepad } = require("ui/control/active_controls.nut")
local style = require("ui/hud/style.nut")
local { watchedHeroSquadMembers } = require("enlisted/ui/hud/state/squad_members.nut")
local vehicleSeatsState = require("ui/hud/state/vehicle_seats.nut")
local { watchedHeroEid } = require("ui/hud/state/hero_state_es.nut")
local {controlHudHint} = require("ui/hud/components/controlHudHint.nut")
local remapNick = require("globals/remap_nick.nut")

local NORMAL_HINT_SIZE = ::hdpx(20)
local GAMEPAD_HINT_SIZE = ::hdpx(36)

local colorBlue = Color(150, 160, 255, 180)
local blurBack = {size=flex() rendObj = ROBJ_WORLD_BLUR_PANEL color=Color(220,220,220,220)}

local memberTextColor = @(member) (member.eid == watchedHeroEid.value) ? style.SUCCESS_TEXT_COLOR
  : member.isAlive ? style.DEFAULT_TEXT_COLOR
  : style.DEAD_TEXT_COLOR

local function seatIcon(seat) {
  if (seat.seat?.locName == null)
    return null
  local owner = seat.owner
  local member = (watchedHeroSquadMembers.value ?? []).findvalue(@(v) v.eid == owner.eid)
  local color = member?.eid ? memberTextColor(member) : style.DEFAULT_TEXT_COLOR
  if (member == null && owner.eid != INVALID_ENTITY_ID)
    color = colorBlue
  return {
    rendObj = ROBJ_STEXT
    text = "[{0}]: ".subst(::loc(seat.seat.locName))
    color = color
    padding = [0,hdpx(2),0,hdpx(2)]
    minHeight = sh(2)
    valign = ALIGN_BOTTOM
  }
}

local function seatNameText(seat) {
  local owner = seat.owner
  local member = (watchedHeroSquadMembers.value ?? []).findvalue(@(v) v.eid == owner.eid)
  local name = member?.name
  local color = member?.eid ? memberTextColor(member) : style.DEFAULT_TEXT_COLOR
  if (member == null) {
    if (owner.isPlayer)
      name = remapNick(::ecs.get_comp_val(owner.player, "name")) ?? ::ecs.get_comp_val(owner.eid, "name")
    else if (owner.eid != INVALID_ENTITY_ID)
      name = ::ecs.get_comp_val(owner.eid, "name") ?? "<Unknown>"
    if (name != null)
      color = colorBlue
  }
  local freeSeatName = @() seat.order.canPlaceManually ? ::loc("vehicle_seats/free_seat") : "..."
  return {
    rendObj = ROBJ_DTEXT
    text = name ?? freeSeatName()
    color = color
    padding = [0,hdpx(2),0,hdpx(2)]
    minHeight = sh(2)
    valign = ALIGN_BOTTOM
  }
}

local mkEmptyHint = @(width) {
  size = [width, SIZE_TO_CONTENT]
}

local function mkSeat(seat, isGpad) {
  local hintWidth = isGpad ? GAMEPAD_HINT_SIZE : NORMAL_HINT_SIZE
  local hint = seat.order.canPlaceManually
    ? controlHudHint({
      id = "Human.Seat0{0}".subst(seat.order.seatNo + 1)
      size = [hintWidth, SIZE_TO_CONTENT]
      hplace = ALIGN_RIGHT
      text_params = {font = Fonts.small_text}, frame=false
    })
    : mkEmptyHint(hintWidth)
  return {
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = [
      hint
      seatIcon(seat)
      { children = [blurBack, seatNameText(seat)] }
    ]
  }
}

local function vehicleSeats() {
  local data = vehicleSeatsState?.value?.data ?? []
  local children = data.map(@(seat) mkSeat(seat, isGamepad.value))

  return {
    watch = [watchedHeroSquadMembers, vehicleSeatsState, watchedHeroEid, isGamepad]
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    hplace = ALIGN_RIGHT
    padding = sh(1)
    gap = hdpx(2)
    children = children
  }
}

return vehicleSeats 