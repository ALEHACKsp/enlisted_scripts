local scrollbar = require("daRg/components/scrollbar.nut")
local style = require("enlisted/enlist/viewConst.nut")
local modalPopupWnd = require("enlist/components/modalPopupWnd.nut")
local pkg = require("components/perksPackage.nut")
local soldierPerks = require("model/soldierPerks.nut")
local perksPoints = require("enlisted/enlist/soldiers/model/perks/perksPoints.nut")
local perksList = require("enlisted/enlist/soldiers/model/perks/perksList.nut")


local function open(targetRect, content, header) {
  modalPopupWnd.add(targetRect, {
    uid = "tier_perks_list"
    size = [style.soldierWndWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = style.bigPadding
    popupFlow = FLOW_HORIZONTAL
    popupValign = ALIGN_TOP
    popupOffset = style.bigPadding
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [0, 0, 0, style.smallPadding] //same offset as tier header
        children = {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = style.noteTxtColor
          font = Fonts.tiny_text
          text = header
        }
      },
      scrollbar.makeVertScroll({
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = content
      }, {
        size = [flex(), SIZE_TO_CONTENT]
        maxHeight = sh(70)
        needReservePlace = false
      })
    ]
  })
}

local function removeOnce(arr, val) {
  local idx = arr.indexof(val)
  if (idx != null)
    arr.remove(idx)
}

local function mkTierPossiblePerks(tier, pointsInfo) {
  local perks = clone tier.perks
  tier.slots.each(@(perkId) removeOnce(perks, perkId))
  if (!perks.len())
    return null

  local paramsList = pkg.uniteEqualPerks(perks)
  paramsList.each(function(p) {
    p.totalCost <- 0
    p.isAvailable <- true
    p.costMask <- 0
    local perkCost = perksList?[p.perkId].cost ?? {}
    foreach (idx, pPointId in perksPoints.pPointsList) {
      local cost = perkCost?[pPointId] ?? 0
      p.totalCost += cost
      p.isAvailable = p.isAvailable
        && (cost + (pointsInfo.used?[pPointId] ?? 0) <= (pointsInfo.total?[pPointId] ?? 0))
      if (pPointId in perkCost)
        p.costMask = p.costMask | (1 << idx)
    }
  })

  paramsList.sort(@(a, b) a.costMask <=> b.costMask || b.totalCost <=> a.totalCost)

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      pkg.tierTitle(tier)
      pkg.mkPerksList(paramsList)
    ]
  }
}

local function openAvailablePerks(targetRect, sPerks) {
  local tiers = sPerks?.tiers ?? []
  if (!tiers.len())
    return

  local pointsInfo = soldierPerks.getPerkPointsInfo(sPerks)
  local content = tiers.map(@(t) mkTierPossiblePerks(t, pointsInfo))
    .filter(@(c) c != null)
  open(targetRect, content, ::loc("possible_perks_list/desc"))
}

local function openCurrentPerks(targetRect, sPerks, exclude = []) {
  local tiers = sPerks?.tiers ?? []
  local content = tiers.map(function(tier) {
    local slots = tier.slots.filter(@(p) p != null && exclude.indexof(p) == null)
    if (!slots.len())
      return null
    return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = [
        pkg.tierTitle(tier)
        pkg.mkPerksList(slots.map(@(p) { perkId = p }))
      ]
    }
  }).filter(@(c) c != null)
  open(targetRect, content, content.len() ? ::loc("current_perks_list") : ::loc("no_current_perks"))
}

return {
  openAvailablePerks = openAvailablePerks
  openCurrentPerks = openCurrentPerks
}
 