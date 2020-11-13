require ecs
require game.es.events
require DagorMath
require game.utils.team
require math
require app
require player

[es (track=respawner_dot_respStartTime, after=respawn_camera_apply_target_es)]
def respawn_camera_delay_change_target_es(evt : Event;
                                          respawner_dot_respStartTime : float;
                                          team : int;
                                      var respawner_dot_changeCameraAtTime : float&)
  if respawner_dot_respStartTime <= 0.0
    return
  ecs::query() <| $[es](respawnCameraForTeam : int; respawnCamera_dot_showDelay : float)
    if is_teams_friendly(team,respawnCameraForTeam) || respawnCameraForTeam == TEAM_UNASSIGNED
      respawner_dot_changeCameraAtTime = get_sync_time() + respawnCamera_dot_showDelay

def setup_camera_as_active(cam_eid: EntityId)
  query(get_local_player_eid()) <| $[es](var activeCamEid: EntityId&; var activeCamName: das_string)
    activeCamEid = cam_eid
    activeCamName := "respawnCam"

def create_respawn_cam(fromEid, toEid : EntityId; transform : float3x4)
  ecs::query(toEid) <| $ [es] (respawnCameraTemplate: string; respawnCameraForTeam: int)
    let respawnCam = createEntity(respawnCameraTemplate) <| $ (var init: ComponentsInitializer)
      set(init, "camera.target", fromEid)
      set(init, "camera.active", true)
      set(init, "transform", transform)
      set(init, "team", respawnCameraForTeam)
      set(init, "shooter_cam.lastPos", transform[3])
      set(init, "respawnCameraTargerPoint", toEid)
    setup_camera_as_active(respawnCam)

[es (REQUIRE=respawnCamera, after=lut_switcher_on_vehicle_gain_input_es)]
def respawn_camera_apply_target_test_es(info: UpdateStageInfoAct;
                                        var camera_dot_target: EntityId&;
                                        var shooter_cam_dot_alternative_settings: bool&;
                                        respawnCameraTargerPoint: EntityId)
  camera_dot_target = respawnCameraTargerPoint
  shooter_cam_dot_alternative_settings = true

def set_respawn_cam(targetEid : EntityId)
  query() <| $[es](var camera_dot_active : bool&; camera_dot_target : EntityId; transform: float3x4)
    if !camera_dot_active
      return
    camera_dot_active = false
    create_respawn_cam(camera_dot_target, targetEid, transform)

def respawn_camera_apply_target(team : int; var respawner_dot_changeCameraAtTime : float&)
  if respawner_dot_changeCameraAtTime <= 0.0 || get_sync_time() < respawner_dot_changeCameraAtTime
    return
  ecs::query() <| $[es](eid : EntityId; respawnCameraForTeam : int)
    if is_teams_friendly(team,respawnCameraForTeam) || respawnCameraForTeam == TEAM_UNASSIGNED
      set_respawn_cam(eid)
      ecs::find_query() <| $ [es(REQUIRE=color_grading)] (eid : EntityId)
        sendEvent(eid, [[EventLutSwitcherAliveState]])
        return true
  respawner_dot_changeCameraAtTime = 0.0

[es (tag=gameClient, after=lut_switcher_on_vehicle_gain_input_es, REQUIRE=respawner)]
def respawn_camera_apply_target_respawner_es(info: UpdateStageInfoAct;
                                             team : int;
                                             respawner_dot_player : EntityId;
                                             var respawner_dot_changeCameraAtTime : float&)
  if respawner_dot_player != get_local_player_eid()
    return
  respawn_camera_apply_target(team, respawner_dot_changeCameraAtTime)

[es (tag=gameClient, after=lut_switcher_on_vehicle_gain_input_es, REQUIRE_NOT=respawner)]
def respawn_camera_apply_target_squad_member_es(info: UpdateStageInfoAct;
                                                team : int;
                                                bindedCamera : EntityId;
                                                squad_member_dot_squad : EntityId;
                                                var respawner_dot_changeCameraAtTime : float&)
  let hasAliveSquadMembers = (get_int(squad_member_dot_squad, "squad.numAliveMembers") ?? 0) > 0
  if !bindedCamera || hasAliveSquadMembers
    return
  respawn_camera_apply_target(team, respawner_dot_changeCameraAtTime)

def find_middle_resp_point(respTeam : int)
  var pos = float3(0.0,0.0,0.0)
  var respsFound = 0
  ecs::query() <| $[es (REQUIRE=respbase, REQUIRE_NOT=aircraftRespbase)](team: int; active : bool; transform: float3x4)
    if active && (is_teams_friendly(team,respTeam) || team == TEAM_UNASSIGNED)
      respsFound++
      pos += transform[3]
  if respsFound > 0
    pos = pos / float(respsFound)
  return pos

def find_middle_capture_zones_point()
  var pos = float3(0.0,0.0,0.0)
  var zonesFound = 0
  ecs::query() <| $[es (REQUIRE=capzone)](active : bool; transform: float3x4)
    if active
      zonesFound++
      pos += transform[3]
  if zonesFound > 0
    pos = pos / float(zonesFound)
  return [[auto zonesFound, pos]]

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventLevelLoaded, track=active, REQUIRE=active, REQUIRE=respbase)]
def respawn_camera_set_target_params_es(evt : Event; team : int)
  ecs::query() <| $[es](moveCameraToHeight: float;
                    var respawnCameraLookFrom: float3&;
                        respawnCameraForTeam : int;
                        respawnSelectorDistanceMult : float)
    if !(is_teams_friendly(respawnCameraForTeam, team) || respawnCameraForTeam == TEAM_UNASSIGNED)
      return
    var lookAt = find_middle_resp_point(team)
    let lookTo = find_middle_capture_zones_point()
    var found = false
    ecs::find_query() <| $[es](respawnBaseGroup : int)
      if respawnBaseGroup != -1
        found = true
      return found
    if found
      let diff = lookAt - lookTo._1
      lookAt += diff * respawnSelectorDistanceMult
    lookAt[1] = lookAt[1] + moveCameraToHeight
    respawnCameraLookFrom = lookAt;

[es (tag=gameClient, on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventLevelLoaded, track=active, REQUIRE=active, REQUIRE=capzone)]
def respawn_camera_zone_changed_params_es(evt : Event)
  ecs::query() <| $[es](respawnCameraLookFrom: float3;
                        var camera_dot_lookDir : float3&)
    let lookTo = find_middle_capture_zones_point()
    if lookTo._0 > 0
      camera_dot_lookDir = lookTo._1 - respawnCameraLookFrom

[es (tag=gameClient, on_event=(EventEntityCreated, EventComponentsAppear), track=respawnCameraLookFrom)]
def respawn_camera_set_position_params_es(evt : Event;
                                          respawnCameraLookFrom: float3;
                                      var camera_dot_look_at : DPoint3;
                                      var camera_dot_lookDir : float3&;
                                      var transform: float3x4)
  transform[3] = respawnCameraLookFrom
  let lookTo = find_middle_capture_zones_point()
  if lookTo._0 > 0
    camera_dot_lookDir = lookTo._1 - respawnCameraLookFrom
  camera_dot_look_at.x = double(respawnCameraLookFrom[0])
  camera_dot_look_at.y = double(respawnCameraLookFrom[1])
  camera_dot_look_at.z = double(respawnCameraLookFrom[2])