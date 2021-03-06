local Contact = require("enlist/contacts/contact.nut")

local class SquadMember {
  userId = null

  //persist data
  state = null

  //calculated data
  isLeader = null
  contact = null
  subscriptions = null
  persistKeys = ["state"]

  constructor(user_id, squadIdWatched) {
    userId = user_id
    contact = Contact.get(userId.tostring())

    // state is observable collection of data variables that
    // come from server
    state = Watched({name = contact.realnick})
    subscriptions = {}
    isLeader = ::Computed(@() squadIdWatched.value == user_id)
  }

  function setBySquadMember(member) {
    foreach(key in persistKeys)
      if (key in member)
        this[key] = member[key]
    return this
  }

  isOnline    = @() contact.online.value
  setOnline   = @(online) contact.onlineBySquad(online)

  function applyRemoteData(msquad_data) {
    log($"[SQUAD] SquadMember::applyRemoteData for {userId} from msquad")
    log(msquad_data)

    local newOnline = msquad_data?.online
    if (newOnline != null)
      setOnline(newOnline)

    local data = msquad_data?.data
    if (typeof(data) != "table")
      return {}

    local oldVal = state.value
    foreach(k,v in data){
      if (k in oldVal && oldVal[k] == v)
        continue
      state(oldVal.__merge(data))
      break
    }

    return data
  }

  function addSubscription(watch_name, watch, func) {
    if (watch == null)
      return
    if (watch_name in subscriptions)
      return
    watch.subscribe(func)
    subscriptions[watch_name] <- { watch = watch, func = func }
  }

  function clearSubscriptions() {
    foreach(k, v in subscriptions)
      v.watch.unsubscribe(v.func)
    subscriptions.clear()
  }

  function onRemove() {
    setOnline(null)
    clearSubscriptions()
  }
}

return SquadMember
 