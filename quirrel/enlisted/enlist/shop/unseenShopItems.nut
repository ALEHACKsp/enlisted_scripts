local { settings } = require("enlist/options/onlineSettings.nut")

const SEEN_ID = "seen/currencies"

local seenShopItems = ::Computed(@() settings.value?[SEEN_ID])

local function markShopItemSeen(shopItem) {
  if (!(seenShopItems.value?[shopItem] ?? false))
    settings(function(set) {
      set[SEEN_ID] <- (set?[SEEN_ID] ?? {}).__merge({
        [shopItem] = true
      })
    })
}

local function excludeShopItemSeen(excludeList) {
  settings(function(set) {
    local saved = clone (set?[SEEN_ID] ?? {})
    local updatesSaved = saved.filter(@(v, name) excludeList.findindex(@(v) v == name) == null)
    set[SEEN_ID] <- updatesSaved
  })
}

console.register_command(@() settings(@(s) delete s[SEEN_ID]), "meta.resetSeenShopItems")

return {
  seenShopItems
  markShopItemSeen
  excludeShopItemSeen
}
 