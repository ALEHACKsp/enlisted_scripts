local modalPopupWnd = require("enlist/components/modalPopupWnd.nut")

local { selectedQueue, isInQueue, selectQueue } = require("quickMatchQueue.nut")
local { matchingQueues } = require("matchingQueues.nut")

const QUEUE_ID = "queue_selector"
local popupWidth = hdpx(450)

local function mkButton(text, handler, style={}){
  //textfunc = ::type(textfunc)=="function" ? textfunc : @() textfunc
  local stateFlags = Watched(0)
  return function(){
    local sf = stateFlags.value
    return {
      rendObj = ROBJ_DTEXT
      text = text
      watch = stateFlags
      onElemState = @(s) stateFlags(s)
      behavior = Behaviors.Button
      onClick = handler
      color = sf & S_HOVER ? Color(255,255,255) : Color(128,128,128)
      skipDirPadNav = true
    }.__update(style)
  }
}

local function mkQueueTitle(queue, idx=""){
 local locId = queue?.locId ?? queue?.title
 if ((locId ?? "") == "")
   return queue?.id ?? "untitledQueue"
 return ::loc(locId)
}
local queueOption = @(option, idx) mkButton(mkQueueTitle(option, idx), @() selectQueue(option) ?? modalPopupWnd.remove(QUEUE_ID), {halign = ALIGN_RIGHT, size=[flex(), SIZE_TO_CONTENT]})

local queueSelector = @(){
  watch = matchingQueues
  flow = FLOW_VERTICAL
  size = [popupWidth, SIZE_TO_CONTENT]
  gap = hdpx(10)
  padding = [ hdpx(5), hdpx(20)]
  children = matchingQueues.value.map(queueOption)
}

local function openQueueMenu(event) {
  modalPopupWnd.add(event.targetRect, {
    uid = QUEUE_ID
    size = [popupWidth, SIZE_TO_CONTENT]
    children = queueSelector
    popupOffset = hdpx(5)
    popupHalign = ALIGN_LEFT
    fillColor = Color(0,0,0,200)
    borderColor = Color(30,30,30,30)
    borderWidth = hdpx(1)
  })
}
local selectedQueueTitle = Computed(@() mkQueueTitle(selectedQueue.value))

local function queueSelectBtn() {
  local text = $"{selectedQueueTitle.value}"
  return {
    watch = [isInQueue, selectedQueueTitle]
    children = !isInQueue.value
      ? mkButton(text, openQueueMenu)
      : @(){rendObj = ROBJ_DTEXT text = text, vplace = ALIGN_CENTER}
  }
}

return queueSelectBtn
 