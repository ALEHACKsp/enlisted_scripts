local json = require("json")
local http = require("dagor.http")
local userInfo = require("enlist/state/userInfo.nut")

local hasLog = {}
local function logByUrlOnce(url, text) {
  if (url in hasLog)
    return
  hasLog[url] <- true
  ::log(text)
}

local function requestData(url, params, onSuccess, onFailure=null) {
  http.request({
    method = "POST"
    url = url
    data = params
    callback = function(response) {
      if (response.status != http.SUCCESS || !response?.body) {
        onFailure?()
        return
      }

      try {
        local str = response.body.tostring()
        if (str.len() > 6 && str.slice(0, 6) == "<html>") { //error 404 and other html pages
          logByUrlOnce(url, $"ShopState: Request result is html page instead of data {url}\n{str}")
          onFailure?()
          return
        }
        local data = json.parse(str)
        if(data?.status == "OK")
          onSuccess(data)
        else
          onFailure?()
      }
      catch(e) {
        logByUrlOnce(url, $"ShopState: Request result error {url}")
        onFailure?()
      }
    }
  })
}

local function createGuidsRequestParams(guids) {
  local res = guids.reduce(@(res, guid) $"{res}guids[]={guid}&", "")
  res = $"{res}token={userInfo.value?.token ?? ""}&special=1"
  return res
}

return {
  requestData = requestData
  createGuidsRequestParams = createGuidsRequestParams
} 