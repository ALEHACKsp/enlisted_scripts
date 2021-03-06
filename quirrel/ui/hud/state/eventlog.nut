local { setIntervalForUpdateFunc } = require("ui/helpers/timers.nut")
local {sound_play} = require("sound")

local function getByPath(table, path) {
  local ret = table
  if (path==null)
    return null
  if (path.len() == 0 )
    return table
  foreach(i,p in path) {
    ret = ret?[p]
    if (ret==null)
      return null
  }
  return ret
}

local equalIgnore = { ttl = true, key = true, num = true }
local countNotIgnoreKeys = @(event) event.keys().reduce(@(res, key) equalIgnore?[key] ? res + 1 : res, 0)
local function isEventSame(event1, event2) {
  if (countNotIgnoreKeys(event1) != countNotIgnoreKeys(event2))
    return false
  foreach(key, value in event1)
    if (!equalIgnore?[key] && event2?[key] != value)
      return false
  return true
}

local function speedUpRemoveSame(eventList, event, maxTime) {
  for (local i = eventList.len() - 1; i >= 0; i--) {
    local eventToRemove = eventList[i]
    if (isEventSame(eventToRemove, event)) {
      eventToRemove.ttl = ::min(eventToRemove.ttl, maxTime)
      break;
    }
  }
}

local function playEventSound(event){
  if ("sound" in event)
    sound_play(event.sound, event?.volume ?? 1)
}

const MAX_EVENTS_DEFAULT = 10
local EventLogState = class{
  data = null
  events = null
  clearTime = -1
  maxEvents = MAX_EVENTS_DEFAULT

  constructor(persistId, clearSameTime = -1, maxActiveEvents = MAX_EVENTS_DEFAULT) {
    data = persist(persistId, @() { events = Watched([]), idCounter = 0 })
    events = data.events
    clearTime = clearSameTime
    maxEvents = maxActiveEvents
  }


  function pushEvent(eventExt, collapseBy=null) {
    local key = ++data.idCounter
    local ev = events?.value ?? []
    local lastev  = ev?[ev.len()-1]
    local event = clone eventExt

    events(function(_) {
      event.ttl <- (event?.ttl != null && event.ttl >= 0) ? event.ttl : 5.0
      if ((collapseBy==null) || getByPath(lastev,collapseBy) != getByPath(event,collapseBy) || ev.len() == 0) {
        event.key <- key
        if (clearTime >= 0)
          speedUpRemoveSame(ev, event, clearTime)
        ev.append(event)
        playEventSound(event)
      } else {
        local num = (lastev?.num != null) ? lastev.num+1 : 2
        event.num <- num
        event.key <- lastev?.key ?? key
        ev[ev.len()-1] = event
      }
      if (ev.len()>maxEvents) {
        ev.remove(0)
      }
    }.bindenv(this))
  }


  update = function(dt) {
    local modified = false
    for (local i=events.value.len()-1; i>=0; --i) {
      local e = events.value[i]
      e.ttl -= dt
      if (e.ttl <= 0.0) {
        events.value.remove(i)
        modified = true
      }
    }

    if (modified) {
      events.trigger()
    }
  }
}


local instances = {
  killLogState = EventLogState("killLogState")
  playerEvents = EventLogState("playerEvents", 0.15, 3)
  awards = EventLogState("awards")
  hints = EventLogState("hints", 0.15, 2)
}
{instances.map(@(v) @(dt) v.update(dt)).each(@(updateFunc) setIntervalForUpdateFunc(0.45, updateFunc))}

::console.register_command(function(text) {instances.eventLogState.pushEvent( {event={}, text=text ?? "sample log text" } )}, "ui.add_player_log")
::console.register_command(function(text) {instances.playerEvents.pushEvent( {event={}, text=text ?? "sample event" } )}, "ui.add_player_event")


return instances
 