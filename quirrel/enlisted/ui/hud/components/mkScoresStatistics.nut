local scrollbar = require("daRg/components/scrollbar.nut")
local remap_nick = require("globals/remap_nick.nut")
local { tooltip } = require("ui/style/cursors.nut")
local style = require("ui/hud/style.nut")
local { round_by_value } = require("std/math.nut")

local bigGap = hdpx(10)

local HEADER_H = hdpx(40).tointeger()
local LINE_H = HEADER_H
local MAX_ROWS_TO_SCROLL = 20
local NUM_COL_WIDTH = hdpx(50)
local SCORE_COL_WIDTH = hdpx(75)

local smallPadding = hdpx(4)
local iconSize = (LINE_H - smallPadding).tointeger()
local borderWidth = ::hdpx(1)
local statisticsRowBgDarken = Color(0, 0, 0, 20)
local statisticsRowBgLighten = Color(10, 10, 10, 20)

local yourTeamColor = Color(18, 68, 91)
local enemyTeamColor = Color(107, 48, 45)

local statisticsScrollHandler = ::ScrollHandler()

local mkHeaderIcon = @(image) {
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  image = ::Picture(image.slice(-4) == ".svg" ? $"!{image}:{iconSize}:{iconSize}:K" : image)
}

local rowText = @(txt, w, playerData) {
  size = [w, LINE_H]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_DTEXT
    font = Fonts.small_text
    text = txt
    color = playerData.isLocal ? style.MY_SQUAD_TEXT_COLOR
      : playerData.player["possessed"] == INVALID_ENTITY_ID ? Color(100,100,100,100)
      : playerData.isAlly ? style.TEAM0_TEXT_COLOR
      : style.TEAM1_TEXT_COLOR
  }
}

local columns = [
  {
    width = NUM_COL_WIDTH
    mkHeader = @(p) null
    mkContent = @(playerData, idx) rowText(idx.tostring(), flex(), playerData)
  }
  {
    width = flex()
    mkHeader = @(p) [
      p.teamIcon == null ? null : {
        rendObj = ROBJ_IMAGE
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        image = ::Picture("{0}:{1}:{1}:K".subst(p.teamIcon, (0.7 * HEADER_H).tointeger()))
        margin = [0, 0, 0, bigGap]
      }
      {
        rendObj = ROBJ_DTEXT
        margin = [0, bigGap, 0, bigGap]
        font = Fonts.medium_text
        text = ::loc(p.teamText)
      }
      p.addChild
    ]
    headerOverride = { flow = FLOW_HORIZONTAL, halign = ALIGN_LEFT }
    mkContent = @(playerData, idx) rowText(remap_nick(playerData.player.name), flex(), playerData)
      .__update({ halign = ALIGN_LEFT, padding = [0, 2 * bigGap] })
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#statistics_kills_icon.svg"
    field = "scoring_player.kills"
    locId = "scoring/kills"
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#kills_technics_icon.svg"
    locId = "scoring/killsVehicles"
    mkContent = @(playerData, idx) rowText((playerData.player?["scoring_player.tankKills"] ?? 0)
      + (playerData.player?["scoring_player.planeKills"] ?? 0), flex(), playerData)
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#kills_assist_icon.svg"
    field = "scoring_player.assists"
    locId = "scoring/killsAssist"
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#zone_defense_icon.svg"
    field = "scoring_player.defenseKills"
    locId = "scoring/killsDefense"
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#captured_zones_icon.svg"
    locId = "scoring/captures"
    mkContent = @(playerData, idx)
      rowText(round_by_value(playerData.player?["scoring_player.captures"] ?? 0, 0.5),
        flex(), playerData)
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "!ui/skin#lb_deaths"
    field = "scoring_player.squadDeaths"
    locId = "scoring/deathsSquad"
  }
  {
    width = SCORE_COL_WIDTH
    headerIcon = "!ui/skin#lb_score"
    field = "score"
    locId = "scoring/total"
  }
]
columns.each(function(c) {
  c.mkHeader <- c?.mkHeader ?? @(p) mkHeaderIcon(c.headerIcon)
  c.mkContent <- c?.mkContent
    ?? @(playerData, idx) rowText(playerData.player?[c.field].tostring() ?? "0", flex(), playerData)
})


local function playerElem(params, idx, playerData = null, borderColor = 0x00000000) {
  local bgColor = (idx % 2) ? statisticsRowBgDarken : statisticsRowBgLighten
  idx ++
  local player = playerData?.player

  local elem = {
    size = [flex(), LINE_H]
    flow = FLOW_HORIZONTAL
    gap = -borderWidth
    children = columns.map(@(c) {
      size = [c.width, flex()]
      rendObj = ROBJ_BOX
      fillColor = bgColor
      borderWidth = [0, borderWidth, 0, borderWidth]
      borderColor = borderColor
      children = player ? c.mkContent(playerData, idx) : null
    })
  }

  if (!player)
    return elem

  return elem.__update({
    key = playerData.eid
  })
}

local paneHeader = @(params) {
  rendObj = ROBJ_SOLID
  size = [flex(), HEADER_H]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  color = params.teamColor
  gap = -borderWidth
  children = columns.map(function(c, idx) {
      local children = c.mkHeader(params)
      local override = c?.headerOverride ?? {}
      if (c?.locId != null)
        override = override.__merge({
          behavior = Behaviors.Button
          inputPassive = true
          onHover = @(on) tooltip.state(on ? ::loc(c.locId) : null)
        })
      return children == null ? null : {
        size = [c.width, flex()]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = children
      }.__update(override)
    })
}


local function getEnemyTeam(teams, playerTeam) {
  if (teams)
    foreach (teamId, team in teams)
      if (teamId != playerTeam)
        return team

  return null
}

local function mkTeamPanel(players, params, minRows, bordersColor) {
  local ret = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = players.map(@(player, idx) playerElem(params, idx, player, bordersColor))
      .extend(array(::max(0, minRows - players.len()))
        .map(@(val, idx) playerElem(params, idx + players.len(), null, bordersColor)))
    clipChildren = true
  }
  ret.children.append({
    size = [flex(), hdpx(1)]
    rendObj = ROBJ_SOLID
    color = bordersColor
  })

  return ret
}

local function mkTwoColumnsTable(allies, enemies, params, minRows) {
  local scrollWidth = params.scrollIsPossible && minRows > MAX_ROWS_TO_SCROLL ? sh(1) : 0
  return [
    {
      size = [params.width - scrollWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      hplace = ALIGN_LEFT
      children = [
        paneHeader({
          teamIcon = params?.teams[params.myTeam.tostring()]?.icon,
          teamText = ::loc("debriefing/your_team"),
          addChild = params.additionalHeaderChild?(true)
          teamColor = yourTeamColor
        })
        paneHeader({
          teamIcon = getEnemyTeam(params?.teams, params.myTeam.tostring())?.icon,
          teamText = ::loc("debriefing/enemy_team"),
          addChild = params.additionalHeaderChild?(false)
          teamColor = enemyTeamColor
        })
      ]
    }
    params.scrollIsPossible && minRows > MAX_ROWS_TO_SCROLL
      ? scrollbar.makeVertScroll({
          size = [params.width - scrollWidth, SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            mkTeamPanel(allies,  params, ::max(enemies.len(), allies.len()), yourTeamColor)
            mkTeamPanel(enemies, params, ::max(enemies.len(), allies.len()), enemyTeamColor)
          ]
        },
        {
          size = [flex(), MAX_ROWS_TO_SCROLL * LINE_H]
          scrollHandler = statisticsScrollHandler
        })
      : {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          mkTeamPanel(allies,  params, ::max(enemies.len(), allies.len()), yourTeamColor)
          mkTeamPanel(enemies, params, ::max(enemies.len(), allies.len()), enemyTeamColor)
        ]
      }
  ]
}

local sortStatistics = @(a, b)
  (b.player?.score ?? 0) <=> (a.player?.score ?? 0)
  || (a.player?.lastUpdate ?? 0) <=> (b.player?.lastUpdate ?? 0)
  || (b.player?["scoring_player.kills"] ?? 0) <=> (a.player?["scoring_player.kills"] ?? 0) //compatibility with prev debriefing
  || a.eid <=> b.eid

local STATISTICS_VIEW_PARAMS = {
  localPlayerEid = INVALID_ENTITY_ID
  myTeam = 1
  width = sh(125)
  showBg = false
  scrollIsPossible = false
  additionalHeaderChild = null //@(isMyTeam) {}
  hotkeys = null
  title = null
}

local function mkTable(players, params = STATISTICS_VIEW_PARAMS) {
  params = STATISTICS_VIEW_PARAMS.__merge(params)

  local localPlayerEid = params.localPlayerEid
  local myTeam = params.myTeam
  local allies = []
  local enemies = []

  foreach (eid, player in players) {
    if (player.disconnected)
      continue

    local res = {
      player = player
      eid = eid
      isAlly = (player.team == myTeam)
      isLocal = (eid == localPlayerEid)
    }

    if (res.isAlly)
      allies.append(res)
    else
      enemies.append(res)
  }
  allies.sort(sortStatistics)
  enemies.sort(sortStatistics)

  local minRows = ::max(allies.len(), enemies.len())
  return {
    key = "scores"
    flow = FLOW_VERTICAL
    hotkeys = params.hotkeys
    children = [
      { size = [params.width, SIZE_TO_CONTENT], children = params.title }
      {
        size = [params.width, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        halign = ALIGN_BOTTOM
        children = mkTwoColumnsTable(allies, enemies, params, minRows)
      }
    ]
  }.__update(!params.showBg ? {} : {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    padding = [0, hdpx(10), hdpx(10), hdpx(10)]
    color = Color(150, 150, 150, 255)
  })
}

return mkTable
 