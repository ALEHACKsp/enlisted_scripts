local style = require("enlisted/enlist/viewConst.nut")
local JB = require("ui/control/gui_buttons.nut")
local textButton = require("enlist/components/textButton.nut")
local client = require("enlisted/enlist/meta/clientApi.nut")
local { configs } = require("enlisted/enlist/configs/configs.nut")

local { get_time_msec } = require("dagor.time")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { getObjectName, getItemDesc } = require("itemsInfo.nut")
local itemTier = require("components/itemTier.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")
local { sceneWithCameraAdd, sceneWithCameraRemove } = require("enlisted/enlist/sceneWithCamera.nut")
local { curSelectedItem } = require("enlisted/enlist/showState.nut")
local mkAnimatedItemsBlock = require("enlisted/enlist/soldiers/mkAnimatedItemsBlock.nut")
local { collectSoldierData } = require("enlisted/enlist/soldiers/model/collectSoldierData.nut")
local { prepareItems, preferenceSort } = require("model/items_list_lib.nut")
local { sound_play } = require("sound")

local { curCampItems, curCampSoldiers } = require("model/state.nut")
local { items, soldiers } = require("enlisted/enlist/meta/profile.nut")

const SHOW_ITEM_DELAY = 1.0 //wait for fadeout
const ITEM_SELECT_DELAY = 0.01
const ANIM_TRIGGER = "reward_items_wnd_anim"
const ANIM_TEXT_TRIGGER = "reward_text_wnd_anim"
const ANIM_TITLE_TRIGGER = "reward_title_wnd_anim"

local newItemsWnd = @() null
local unseenPack = ::Computed(function() {
  if ("items_templates" not in configs.value)
    return null

  local itemsGuids = []
  foreach (guid, item in curCampItems.value)
    if (!(item?.wasSeen ?? true))
      itemsGuids.append(guid)

  local soldiersGuids = []
  foreach (guid, soldier in curCampSoldiers.value)
    if (!(soldier?.wasSeen ?? true))
      soldiersGuids.append(guid)

  local unseenGuids = [].extend(itemsGuids).extend(soldiersGuids)
  return unseenGuids.len() > 0
    ? {
        header = ::loc("battleRewardTitle")
        allItems = prepareItems(unseenGuids)
          .sort(preferenceSort)
          .map(@(item) item?.itemtype == "soldier" ? collectSoldierData(item) : item)
        itemsGuids = itemsGuids
        soldiersGuids = soldiersGuids
      }
    : null
})

local curItem = Watched(null)
curItem.subscribe(function(v) {
  gui_scene.setTimeout(ITEM_SELECT_DELAY, function() {
    curSelectedItem(v)
    ::anim_start(ANIM_TEXT_TRIGGER)
  })
})


local isMarkSeenInProgress = ::Watched(false)

local markSeenGuids = @(watch, guids)
  watch(function(v) {
    foreach(guid in guids)
      if (guid in v)
        v[guid].wasSeen <- true
  })

local function markSeen() {
  if (isMarkSeenInProgress.value || unseenPack.value == null)
    return

  local { itemsGuids, soldiersGuids } = unseenPack.value
  isMarkSeenInProgress(true)
  client.mark_as_seen(itemsGuids, soldiersGuids, @(res) isMarkSeenInProgress(false))

  //no need to wait for server answer to close this window
  markSeenGuids(soldiers, soldiersGuids)
  markSeenGuids(items, itemsGuids)
}

local animEndTime = -1

local function tryMarkSeen() {
  if (animEndTime > get_time_msec()) {
    ::anim_skip($"{ANIM_TRIGGER}_skip")
    ::anim_skip_delay(ANIM_TRIGGER)
    animEndTime = -1
    return
  }
  markSeen()
}

local function close() {
  sceneWithCameraRemove(newItemsWnd)
  curSelectedItem(null)
}

local textAnimations = @(trigger = null) [
  { trigger = trigger, prop = AnimProp.opacity,
    from = 0, to = 1, duration = 0.8, play = true, easing = InOutCubic }
  { trigger = trigger, prop = AnimProp.scale,
    from = [1.5, 2], to = [1, 1], duration = 0.3, play = true, easing = InOutCubic }
]

local title = @(titleText) {
  rendObj = ROBJ_DTEXT
  size = SIZE_TO_CONTENT
  margin = [style.bigPadding * 4, 0]
  transform = {}
  animations = textAnimations(ANIM_TITLE_TRIGGER)
  font = Fonts.big_text
  text = ::loc(titleText)
}

local curItemDescription = @(item) {
  size = [sw(50), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  margin = [0, 0, hdpx(25), 0]
  font = Fonts.medium_text
  text = getItemDesc(item?.basetpl)
  transform = {}
  animations = textAnimations(ANIM_TEXT_TRIGGER)
}

local curItemName = @(item) {
  flow = FLOW_HORIZONTAL

  gap = style.bigPadding
  valign = ALIGN_CENTER
  padding = [style.bigPadding, 0]
  transform = {}
  animations = textAnimations(ANIM_TEXT_TRIGGER)
  children = [
    itemTier(item)
    {
      rendObj = ROBJ_DTEXT
      size = SIZE_TO_CONTENT
      font = Fonts.big_text
      text =  getObjectName(item)
    }
  ]
}

local underline = {
  rendObj = ROBJ_SOLID
  size = [pw(80), hdpx(1)]
  color = Color(100, 100, 100, 50)
}

local function newIemsWndContent() {
  if (!unseenPack.value)
    return null

  local itemsCount = unseenPack.value.itemsGuids.len()
  local soldiersCount = unseenPack.value.soldiersGuids.len()
  local subtitle = itemsCount > 1 ? "delivery/items"
    : itemsCount == 1 ? "delivery/item"
    : soldiersCount > 1 ? "delivery/soldiers"
    : "delivery/soldier"

  sound_play( itemsCount > 0 ? "ui/weaponry_delivery" : "ui/troops_reinforcement")

  local animBlock = mkAnimatedItemsBlock({ items = unseenPack.value.allItems }, {
    width = sw(80)
    addChildren = []
    hasAnim = true
    baseAnimDelay = SHOW_ITEM_DELAY
    animTrigger = ANIM_TRIGGER
    hasItemTypeTitle = false
    selectedKey = curItem
    onItemClick = @(item) curItem(item)
    onVisibleCb = function() {
      sound_play("ui/debriefing/new_equip")
    }
    isDisarmed = true
  })

  animEndTime = get_time_msec() + 1000 * animBlock.totalTime
  return {
    watch = unseenPack
    size = flex()
    flow = FLOW_VERTICAL
    gap = style.bigPadding
    halign = ALIGN_CENTER

    children = [
      title(unseenPack.value.header)
      underline
      @() {
        size = flex()
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        watch = curItem
        children = [
          curItemName(curItem.value)
          { size = flex() }
          curItemDescription(curItem.value)
        ]
      }
      underline
      title(subtitle)
      { size = [0, hdpx(25)] }
      animBlock.component
    ]
  }
}

newItemsWnd = @() {
  key = $"newItemsWindow"
  size = flex()
  padding = safeAreaBorders.value
  watch = [ safeAreaBorders ]
  halign = ALIGN_CENTER
  behavior = Behaviors.Button
  flow = FLOW_VERTICAL
  children = [
    {
      margin = [style.bigPadding * 4, 0, 0, 0]
      hplace = ALIGN_RIGHT
      children = closeBtnBase({
        onClick = tryMarkSeen
      })
    }
    newIemsWndContent
    textButton(::loc("Ok"), tryMarkSeen, {
      hotkeys = [["^{0} | Esc | Space".subst(JB.B), { description = ::loc("Close") }]]
    })
  ]
}

unseenPack.subscribe(function(pack) {
  local allItems = pack?.allItems ?? []
  if (allItems.len() == 0)
    return close()

  ::anim_start(ANIM_TITLE_TRIGGER)
  sceneWithCameraAdd(newItemsWnd, "new_items")
  curItem(allItems[0])
})

return null 