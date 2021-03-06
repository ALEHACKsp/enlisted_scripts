local dagor_shell = require("dagor.shell")
local string = require("string")
local auth = require("auth")
local steam = require("steam")
local platform = require("globals/platform.nut")
local regexp2 = require("regexp2")

local function open_url(url) {
  if (::type(url)!="string" || (!string.startswith(url, "http://") && !string.startswith(url, "https://")))
    return false
  if (platform.is_sony)
    require("sony.www").open(url, @(_) null)
  else if (platform.is_gdk)
    require("xbox_gdk.app").launch_browser(url)
  else if (platform.is_nswitch)
    require("nswitch.network").openUrl(url)
  else if (platform.is_pc)
    dagor_shell.shell_execute({file=url})
  else
    ::log_for_user("Open url not implemented on this platform")
  return true
}

const URL_ANY_ENDING = @"(\/.*$|\/$|$)"
const AUTH_TOKEN_HOST = "store.gaijin.net"

local tokenHostBySsoService = {
  zendesk = "https://login.gaijin.net/sso/getShortToken"
  gss = "https://login.gaijin.net/sso/getShortToken",
}

local addEnding = @(url) $"{url}{URL_ANY_ENDING}"

local urlTypes = [
  {
    typeName = "marketplace"
    autologin = true
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/trade\.gaijin\.net")),
      regexp2(addEnding(@"^https?:\/\/store\.gaijin\.net")),
      regexp2(addEnding(@"^https?:\/\/inventory-test-01\.gaijin\.lan")),
    ]
  },
  {
    typeName = "steam_market"
    autologin = false
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/store\.steampowered\.com"))
    ]
  },
  {
    typeName = "gaijin_support"
    autologin = true
    ssoService = "zendesk"
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/support\.gaijin\.net"))
    ]
  },
  {
    typeName = "gss"
    autologin = true

    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/gss\.gaijin\.net"))
    ]
  },
  {
    typeName = "match any url"
    autologin = false
    urlRegexpList = null
  },
]

local function getUrlTypeByUrl(url) {
  foreach(urlType in urlTypes) {
    if (!urlType.urlRegexpList)
      return urlType

    foreach(r in urlType.urlRegexpList)
      if (r.match(url))
        return urlType
  }

  return null
}

local function openUrl(baseUrl, isAlreadyAuthenticated = false, shouldExternalBrowser = false, goToUrl = null) {
  local url = baseUrl ? string.strip(baseUrl) : ""
  if (url == "") {
    log("Error: tried to openUrl an empty url")
    return
  }

  local urlType = getUrlTypeByUrl(url)
  log($"Open type<{urlType.typeName}> url: {url}")
  log($"Base Url = {baseUrl}")

  if (goToUrl == null)
    goToUrl = (!shouldExternalBrowser && steam.is_overlay_enabled()) ? steam.open_url : open_url

  if (urlType.typeName == "steam_market" && !steam.is_overlay_enabled())
    log("Warning: trying to open steam url without steam overlay")

  if (isAlreadyAuthenticated || !urlType.autologin) {
    goToUrl(url)
    return
  }

  local goToAuthenticatedUrl = function(result)  {
    if (result.status == auth.YU2_OK) {
      // use result.url string
      goToUrl(result.url)
      return
    }
    log($"Error: failed to get_authenticated_url, status = {result.status}")
    goToUrl(baseUrl) // anyway open url without authentication
  }

  local { ssoService = null } = urlType
  if (ssoService == null || auth?.get_authenticated_url_sso == null)
    auth.get_authenticated_url(baseUrl, AUTH_TOKEN_HOST, goToAuthenticatedUrl);
  else
    auth.get_authenticated_url_sso(baseUrl, tokenHostBySsoService?[ssoService] ?? AUTH_TOKEN_HOST,
      ssoService, goToAuthenticatedUrl)
}

return openUrl
 