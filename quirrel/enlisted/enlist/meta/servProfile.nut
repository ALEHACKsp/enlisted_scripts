local profile = {
  items = {}
  wallposters = {}
  soldiers = {}
  soldiersLook = {}
  squads = {}
  armies = {}
  trainings = {}
  soldierPerks = {}
  researches = {}
  deliveries = {}
  cratesContent = {
    items = {}
    soldiers = {}
    soldiersLook = {}
    soldierPerks = {}
  }
  armyEffects = {}
  savedEvents = {}
  boughtBonuses = {}
  purchasesCount = {}
  receivedUnlocks = {}
  rewardedSingleMissons = {}
  premium = {}
}.map(@(value, key) persist(key, @() Watched(value)))

return profile
 