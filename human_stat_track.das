require ecs
require game.es.events
require app
require math
require DaWeaponProps
require dm
require strings
require game.es.stat_bq_common
require daslib/strings_boost

[event(unicast)]
struct CommitHumanStat {}

let
  BOT_OWNER = 0
  PLAYER_OWNER = 1

[private]
def remove_sub_template_name(template_name : string; sub : string)
  let parts <- split(template_name, "+{sub}")
  return length(parts) == 0 ? template_name : join(parts, "")

[private]
def get_weapon_name_by_props_shell_id(human_weap_dot_gunEids : EidList; gun_props_id, shell_id : int16)
  for gun in human_weap_dot_gunEids
    if get_int(gun, "gun.propsId") ?? -1 == int(gun_props_id)
      let res = remove_sub_template_name(getEntityTemplateName(gun), "attached_to_parent")
      if gun |> has("grenade_thrower")
        let entProps = get_shell_entity_props(int(shell_id))
        if entProps != null
          return "{res}_{entProps.templName}"
      return res
  return ""

[private]
def try_inc_object_value(var map : Object?; field : string)
  if map != null
    let count = get_int(*map, field) ?? 0
    set(*map, field, count + 1)

[es (tag=server)]
def human_stat_on_kill(evt:EventAnyEntityDied)
  query(evt.offender) <| $[es](isInVehicle: bool; human_weap_dot_gunEids : EidList;
                              var human_stat_tracking_dot_killsPerWeapon : Object?;
                              var human_stat_tracking_dot_botsKillsPerWeapon : Object?;
                              var human_stat_tracking_dot_killsDistance, human_stat_tracking_dot_maxKillsDistance : float&;
                              var human_stat_tracking_dot_killsCount, human_stat_tracking_dot_botsKillsCount, human_stat_tracking_dot_inVehicleKillsCount : int&)
    let botTarget = get_int(evt.victim, "human_stat_tracking.ownedBy") ?? -1 == BOT_OWNER
    if human_stat_tracking_dot_killsPerWeapon != null || human_stat_tracking_dot_botsKillsPerWeapon != null
      let gunPropsId = int(evt.deathDesc.gunPropsId)
      var weaponName = get_weapon_name_by_props_shell_id(human_weap_dot_gunEids, evt.deathDesc.gunPropsId, evt.deathDesc.shellId)
      if !empty(weaponName)
        try_inc_object_value(human_stat_tracking_dot_killsPerWeapon, weaponName)
        if botTarget
          try_inc_object_value(human_stat_tracking_dot_botsKillsPerWeapon, weaponName)

    if isInVehicle
      human_stat_tracking_dot_inVehicleKillsCount++
      return
    human_stat_tracking_dot_killsCount++

    let offenderTransform = get_TMatrix(evt.offender, "transform")
    let victimTransform = get_TMatrix(evt.victim, "transform")
    if offenderTransform != null && victimTransform != null
      let dist = distance((*offenderTransform)[3], (*victimTransform)[3])
      human_stat_tracking_dot_killsDistance += dist
      if dist > human_stat_tracking_dot_maxKillsDistance
        human_stat_tracking_dot_maxKillsDistance = dist
    if botTarget
      human_stat_tracking_dot_botsKillsCount++

[es (tag=server)]
def human_stat_on_hit(evt:EventOnEntityHit)
  let damage = evt.damageDesc.damageType
  if damage != DamageType DM_COLLISION && damage != DamageType DM_DISCONNECTED
    query(evt.offender) <| $[es](isInVehicle: bool; human_weap_dot_gunEids : EidList;
                                var human_stat_tracking_dot_hitsPerWeapon : Object?;
                                var human_stat_tracking_dot_botsHitsPerWeapon : Object?;
                                var human_stat_tracking_dot_hitsDistance : float&;
                                var human_stat_tracking_dot_hitsCount, human_stat_tracking_dot_botsHitsCount, human_stat_tracking_dot_inVehicleHitsCount : int&)
      let botTarget = get_int(evt.victim, "human_stat_tracking.ownedBy") ?? -1 == BOT_OWNER
      if human_stat_tracking_dot_hitsPerWeapon != null || human_stat_tracking_dot_botsHitsPerWeapon != null
        var weaponName = get_weapon_name_by_props_shell_id(human_weap_dot_gunEids, evt.damageDesc.gunPropsId, evt.damageDesc.shellId)
        if !empty(weaponName)
          try_inc_object_value(human_stat_tracking_dot_hitsPerWeapon, weaponName)
          if botTarget
            try_inc_object_value(human_stat_tracking_dot_botsHitsPerWeapon, weaponName)

      if isInVehicle
        human_stat_tracking_dot_inVehicleHitsCount ++
        return

      human_stat_tracking_dot_hitsCount++

      let offenderTransform = get_TMatrix(evt.offender, "transform")
      let victimTransform = get_TMatrix(evt.victim, "transform")
      if offenderTransform != null && victimTransform != null
        human_stat_tracking_dot_hitsDistance += distance((*offenderTransform)[3], (*victimTransform)[3])
      if botTarget
        human_stat_tracking_dot_botsHitsCount++

[es (tag=server, no_order)]
def human_stat_on_shoot(info : UpdateStageInfoAct; human_weap_dot_lastShotAtTime : float; isInVehicle: bool;
                        human_weap_dot_currentGunEid : EntityId;
                        var human_stat_tracking_dot_shotsPerWeapon : Object?;
                        var human_stat_tracking_dot_prevShootAtTime : float&;
                        var human_stat_tracking_dot_shotsCount, human_stat_tracking_dot_inVehicleShotsCount : int&)
  if human_stat_tracking_dot_prevShootAtTime != human_weap_dot_lastShotAtTime
    human_stat_tracking_dot_prevShootAtTime = human_weap_dot_lastShotAtTime

    if human_stat_tracking_dot_shotsPerWeapon != null && !!human_weap_dot_currentGunEid
      let weaponName = remove_sub_template_name(getEntityTemplateName(human_weap_dot_currentGunEid), "attached_to_parent")
      if !empty(weaponName)
        try_inc_object_value(human_stat_tracking_dot_shotsPerWeapon, weaponName)

    if isInVehicle
      human_stat_tracking_dot_inVehicleShotsCount++
    else
      human_stat_tracking_dot_shotsCount++

[es (tag=server)]
def human_stat_create_track(evt : EventEntityCreated; var human_stat_tracking_dot_ownedBy : int&;
                            var human_stat_tracking_dot_spawnTime, human_stat_tracking_dot_ownerTime : float&)
  human_stat_tracking_dot_spawnTime = get_sync_time()
  human_stat_tracking_dot_ownerTime = human_stat_tracking_dot_spawnTime
  human_stat_tracking_dot_ownedBy = BOT_OWNER

[es (tag=server, track=possessedByPlr)]
def human_stat_hero_change(evt:Event; eid : EntityId; possessedByPlr : EntityId; isAlive : bool; beh_tree_dot_enabled : bool;
                           var human_stat_tracking_dot_spawnTime, human_stat_tracking_dot_ownerTime : float&;
                           var human_stat_tracking_dot_ownedBy : int&)
  if !isAlive
    return
  let atTime = get_sync_time()
  let owner = possessedByPlr != INVALID_ENTITY_ID && !beh_tree_dot_enabled ? PLAYER_OWNER : BOT_OWNER
  let justSpawned = atTime - human_stat_tracking_dot_spawnTime < 1.0
  let shortBattleTime = atTime - human_stat_tracking_dot_ownerTime < 1.0
  if human_stat_tracking_dot_ownedBy != owner && !justSpawned && !shortBattleTime
    human_stat_tracking_dot_spawnTime = -1.
    sendEventImmediate(eid, [[CommitHumanStat]])
  human_stat_tracking_dot_ownedBy = owner
  human_stat_tracking_dot_ownerTime = atTime

[es (tag=server, on_event=CommitHumanStat, on_event=EventEntityDied)]
def human_stat_died_track(evt:Event; eid, possessedByPlr : EntityId; team : int; isAlive : bool;
                            human_stat_tracking_dot_spawnTime : float;
                            human_stat_tracking_dot_ownerTime : float;
                            human_stat_tracking_dot_ownedBy : int;
                            var human_stat_tracking_dot_targetTracesCount : int&;
                            var human_stat_tracking_dot_killsCount : int&;
                            var human_stat_tracking_dot_botsKillsCount : int&;
                            var human_stat_tracking_dot_killsPerWeapon : Object?;
                            var human_stat_tracking_dot_botsKillsPerWeapon : Object?;
                            var human_stat_tracking_dot_inVehicleKillsCount : int&;
                            var human_stat_tracking_dot_hitsCount : int&;
                            var human_stat_tracking_dot_hitsPerWeapon : Object?;
                            var human_stat_tracking_dot_botsHitsPerWeapon : Object?;
                            var human_stat_tracking_dot_inVehicleHitsCount : int&;
                            var human_stat_tracking_dot_shotsCount : int&;
                            var human_stat_tracking_dot_botsHitsCount : int&;
                            var human_stat_tracking_dot_shotsPerWeapon : Object?;
                            var human_stat_tracking_dot_inVehicleShotsCount : int&;
                            var human_stat_tracking_dot_maxKillsDistance : float&;
                            var human_stat_tracking_dot_killsDistance : float&;
                            var human_stat_tracking_dot_hitsDistance : float&;
                            var human_stat_tracking_dot_totalDangers : float&)
  let curTime = get_sync_time()
  let liveTime = human_stat_tracking_dot_spawnTime < 0. ? -1. : curTime - human_stat_tracking_dot_spawnTime
  let battleTime = curTime - human_stat_tracking_dot_ownerTime
  let name = human_stat_tracking_dot_ownedBy == PLAYER_OWNER ? "human" : "bot"
  let offenderType = human_stat_tracking_dot_ownedBy == PLAYER_OWNER ? "human" : "human_bot"
  var userId = get_int64_t(possessedByPlr, "userid") ?? int64(0)
  if userId < int64(0)
    userId = int64(0)
  send_event_bq_with_header("unit_stat") <| $(var jw: JsonWriter)
    add_user_id(jw, userId)
    jw_key_value(jw, "offender_type", offenderType)
    jw_key_value(jw, "live_time", liveTime)
    jw_key_value(jw, "battle_time", battleTime)
    jw_key_value(jw, "shots", human_stat_tracking_dot_shotsCount)
    jw_key_value(jw, "hits", human_stat_tracking_dot_hitsCount)
    jw_key_value(jw, "kills", human_stat_tracking_dot_killsCount)
    jw_key_value(jw, "hits_bots", human_stat_tracking_dot_botsHitsCount)
    jw_key_value(jw, "kills_bots", human_stat_tracking_dot_botsKillsCount)
    jw_key_value(jw, "shots_in_vehicle", human_stat_tracking_dot_inVehicleShotsCount)
    jw_key_value(jw, "hits_in_vehicle", human_stat_tracking_dot_inVehicleHitsCount)
    jw_key_value(jw, "kills_in_vehicle", human_stat_tracking_dot_inVehicleKillsCount)
    jw_key_value(jw, "traces", human_stat_tracking_dot_targetTracesCount)
    jw_key_value(jw, "distance", human_stat_tracking_dot_hitsDistance)
    jw_key_value(jw, "kill_distance", human_stat_tracking_dot_killsDistance)
    jw_key_value(jw, "max_kill_distance", human_stat_tracking_dot_maxKillsDistance)

  print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} live time {liveTime} battle time {battleTime}"
      + " Traces {human_stat_tracking_dot_targetTracesCount} Kills {human_stat_tracking_dot_killsCount} Hits {human_stat_tracking_dot_hitsCount}"
      + " Shots {human_stat_tracking_dot_shotsCount} HDistance {human_stat_tracking_dot_hitsDistance}"
      + " KDistance {human_stat_tracking_dot_killsDistance} MaxKDistance {human_stat_tracking_dot_maxKillsDistance}"
      + " TotalDangers {human_stat_tracking_dot_totalDangers} VehicleShots {human_stat_tracking_dot_inVehicleShotsCount} VehicleHits {human_stat_tracking_dot_inVehicleHitsCount}"
      + " VehicleKills {human_stat_tracking_dot_inVehicleKillsCount} BotsHits {human_stat_tracking_dot_botsHitsCount} BotsKills {human_stat_tracking_dot_botsKillsCount}")

  if (human_stat_tracking_dot_shotsPerWeapon != null && human_stat_tracking_dot_hitsPerWeapon != null && human_stat_tracking_dot_killsPerWeapon != null
      && human_stat_tracking_dot_botsHitsPerWeapon != null && human_stat_tracking_dot_botsKillsPerWeapon != null)
    for it in *human_stat_tracking_dot_shotsPerWeapon
      let key = it.key
      let shots = get_int(it.value) ?? 0
      print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} shot per weapon {key} {shots}")
      var hits = 0
      var botsHits = 0
      var kills = 0
      var botsKills = 0

      for hitData in *human_stat_tracking_dot_hitsPerWeapon
        if hitData.key == key
          hits = get_int(hitData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} hit per weapon {key} {hits}")

      for hitData in *human_stat_tracking_dot_botsHitsPerWeapon
        if hitData.key == key
          botsHits = get_int(hitData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} bots hit per weapon {key} {hits}")

      for killData in *human_stat_tracking_dot_killsPerWeapon
        if killData.key == key
          kills = get_int(killData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} kill per weapon {it.key} {kills}")

      for killData in *human_stat_tracking_dot_botsKillsPerWeapon
        if killData.key == key
          botsKills = get_int(killData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} bots kill per weapon {it.key} {kills}")

      send_event_bq_with_header("unit_weapon_stat") <| $(var jw: JsonWriter)
        add_user_id(jw, userId)
        jw_key_value(jw, "offender_type", offenderType)
        jw_key_value(jw, "weapon_template", key)
        jw_key_value(jw, "shots", shots)
        jw_key_value(jw, "hits", hits)
        jw_key_value(jw, "hits_bots", botsHits)
        jw_key_value(jw, "kills", kills)
        jw_key_value(jw, "kills_bots", botsKills)

    if isAlive
      clear(*human_stat_tracking_dot_shotsPerWeapon)
      clear(*human_stat_tracking_dot_hitsPerWeapon)
      clear(*human_stat_tracking_dot_killsPerWeapon)
  if isAlive
    human_stat_tracking_dot_targetTracesCount = 0
    human_stat_tracking_dot_killsCount = 0
    human_stat_tracking_dot_botsKillsCount = 0
    human_stat_tracking_dot_inVehicleKillsCount = 0
    human_stat_tracking_dot_hitsCount = 0
    human_stat_tracking_dot_botsHitsCount = 0
    human_stat_tracking_dot_inVehicleHitsCount = 0
    human_stat_tracking_dot_shotsCount = 0
    human_stat_tracking_dot_inVehicleShotsCount = 0
    human_stat_tracking_dot_killsDistance = 0f
    human_stat_tracking_dot_maxKillsDistance = 0f
    human_stat_tracking_dot_hitsDistance = 0f
    human_stat_tracking_dot_totalDangers = 0f
