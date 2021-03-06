                                                   
                                                          
                                                                                       
                                                                                                             
                                                   
local { logerr } = require("dagor.debug")
local { changeIndex } = require("enlisted/enlist/meta/metalink.nut")

local queueByUid = {}

local function applyOrder(listWatch, order) {
  listWatch(function(list) {
    foreach(data in order)
      if (data.guid in list)
        changeIndex(list[data.guid], data.to)
  })
}

local function restoreOrder(listWatch, order) {
  listWatch(function(list) {
    foreach(data in order)
      if (data.guid in list)
        changeIndex(list[data.guid], data.from)
  })
}

local function calcNewOrder(orderedList, idxFrom, idxTo) {
  local newOrder = array(orderedList.len())
  local move = idxFrom < idxTo ? -1 : 1
  foreach(idx, obj in orderedList) {
    local data = {
      guid = obj.guid
      from = idx
      to = idx
    }
    if (idx >= ::min(idxTo, idxFrom) && idx <= ::max(idxTo, idxFrom)) {
      local newIdx = (idx == idxFrom) ? idxTo : idx + move
      data.to = newIdx
    }
    newOrder[data.to] = data
  }
  ::assert(newOrder.indexof(null) == null)
  return newOrder
}

local function prepareNewOrder(curOrder, newOrder) {
  local res = array(curOrder.len())
  local addIdx = newOrder.len()
  foreach(idx, obj in curOrder) {
    local newIdx = newOrder.indexof(obj.guid) ?? addIdx++
    ::assert(newIdx in res)
    res[newIdx] = {
      guid = obj.guid
      from = idx
      to = newIdx
    }
  }
  return res
}

local function mkValidatedOrder(orderedList, newOrder, logId) {
  local list = clone orderedList
  foreach(data in newOrder) {
    local { guid } = data
    data.from = list.findindex(@(obj) obj.guid == guid)
    if (data.from != null)
      list.remove(data.from)
  }

  if (list.len() == 0 && newOrder.len() == orderedList.len())
    return list

  //new obj appear or something disappear
  ::log($"[ChangeOrder] {logId} list changed during wait for order")
  newOrder = newOrder.filter(@(d) d.from == null)
  newOrder.each(function(d, idx) { d.to = idx })
  foreach(obj in list)
    newOrder.append({
      guid = obj.guid
      from = orderedList.indexof(obj)
      to = newOrder.len()
    })
  return newOrder
}

local requestByUid = null //forward declaration

local function continueQueue(uid) {
  if (queueByUid?[uid].isRequested ?? false) {
    delete queueByUid[uid]
    return
  }

  local { listGetter, newOrder, listWatch, logId } = queueByUid[uid]
  newOrder  = mkValidatedOrder(listGetter(), newOrder, logId)
  if (newOrder.findindex(@(d) d.to != d.from) == null) {
    delete queueByUid[uid]
    return
  }
  applyOrder(listWatch, newOrder)
  requestByUid(uid)
}

requestByUid = function(uid) {
  if (!(uid in queueByUid))
    return
  local { request, newOrder, listWatch } = queueByUid[uid]
  queueByUid[uid].isRequested = true
  request(newOrder.map(@(d) d.guid),
    function(res) {
      if ("error" in res)
        restoreOrder(listWatch, newOrder)
      continueQueue(uid)
    })
}

local function changeOrderQueue(uid, listGetter, listWatch, request,
  logId = "unknown list", order = null, idxFrom = 0, idxTo = 0
) {
  local list = listGetter()
  if (!(idxFrom in list) || !(idxTo in list)) {
    logerr($"Change {logId} order out of list from {idxFrom} to {idxTo}, when total soldiers {list.len()}")
    return
  }
  local newOrder = order != null ? prepareNewOrder(list, order) : calcNewOrder(list, idxFrom, idxTo)
  applyOrder(listWatch, newOrder)

  local isRequested = uid in queueByUid
  queueByUid[uid] <- {
    uid = uid
    logId = logId
    newOrder = newOrder
    listWatch = listWatch
    listGetter = listGetter
    request = request
    isRequested = false
  }

  if (!isRequested)
    requestByUid(uid)
}

return ::kwarg(changeOrderQueue) 