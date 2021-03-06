local function addLink(obj, link, link_type) {
  obj.links[link] <- link_type
}

local function delLink(obj, link) {
  delete obj.links[link]
}

local function delLinkByType(obj, link_type) {
  foreach (k,v in obj.links) {
    if (v == link_type) {
      delete obj.links[k]
    }
  }
}

local hasLinkByType = @(obj, link_type)
  obj.links.findindex(@(v) v == link_type) != null

local function getLinkedObjects(where, linked) {
  local res = []
  foreach (k,v in where) {
    local linkType = v.links?[linked]
    if (linkType) {
      res.append({
        key = k
        value = v
        type = linkType
      })
    }
  }

  return res
}


local function getLinkedObjectsValues(where, linked) {
  local res = []
  foreach (v in where)
    if (v.links?[linked])
      res.append(v)

  return res
}


local isObjectLinkedToAny = @(obj, linkedList)
  linkedList.findvalue(@(linked) obj.links?[linked] != null) != null


local function getObjectsByLink(where, linked, link_type) {
  local res = []
  foreach (v in where)
    if (v.links?[linked] == link_type)
      res.append(v)

  return res
}


local function getObjectsByLinkType(where, link_type) {
  local res = []
  foreach (k,v in where) {
    foreach(to,linkType in v) {
      if (linkType == link_type) {
        res.append({
          key = k
          value = v
        })
        break
      }
    }
  }

  return res
}

local function getObjectsTableByLinkType(where, link_type) {
  local res = {}
  foreach (k,v in where)
    foreach(to,linkType in v.links)
      if (linkType == link_type) {
        if (to not in res)
          res[to] <- []
        res[to].append(v)
        break
      }
  return res
}

local function getLinksByType(obj, link_type) {
  return obj.links.filter(@(v) v == link_type).keys()
}

local getFirstLinkByType = @(obj, link_type)
  getLinksByType(obj, link_type)?[0]

local getItemIndex = @(_) (getLinksByType(_, "index")?[0].tointeger()) ?? -1

local function changeIndex(obj, newIndex) {
  delLinkByType(obj, "index")
  if (newIndex >= 0)
    addLink(obj, newIndex.tostring(), "index")
}

local getObjectsByLinkSorted = @(objects, squadGuid, linkType)
  getObjectsByLink(objects, squadGuid, linkType)
    .sort(@(a,b) getItemIndex(a) <=> getItemIndex(b))

local function isObjLinkedToAnyOfObjects(obj, objects) {
  foreach (k, v in obj?.links ?? {})
    if (k in objects)
      return true
  return false
}

local function getLinkedSlotData(obj) {
  foreach(linkVal, linkType in obj.links)
    if (linkType != "index" && linkType != "army")
      return { linkTgt = linkVal, linkSlot = linkType }
  return null
}

return {
  addLink = addLink
  delLink = delLink
  hasLinkByType = hasLinkByType
  delLinkByType = delLinkByType
  getLinkedObjects = getLinkedObjects
  getLinkedObjectsValues = getLinkedObjectsValues
  isObjectLinkedToAny = isObjectLinkedToAny
  getObjectsByLink = getObjectsByLink
  getObjectsByLinkType = getObjectsByLinkType
  getObjectsTableByLinkType = getObjectsTableByLinkType
  getLinksByType = getLinksByType
  getFirstLinkByType = getFirstLinkByType
  getLinkedArmyName = @(_) getLinksByType(_, "army")?[0]
  getLinkedSquadGuid = @(_) getLinksByType(_, "squad")?[0]
  getItemIndex = getItemIndex
  changeIndex = changeIndex
  getObjectsByLinkSorted = getObjectsByLinkSorted
  isObjLinkedToAnyOfObjects = isObjLinkedToAnyOfObjects
  getLinkedSlotData = getLinkedSlotData
}
 