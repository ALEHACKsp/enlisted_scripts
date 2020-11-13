require ecs
require EnlistedWalkerai
require math

let
  HALF_PI = PI / 2.0
  predefined_angles = [[ float[4] -HALF_PI; HALF_PI; -HALF_PI * 1.5f; HALF_PI * 1.5f ]]

def recalc_member_offset(member_idx : int; spread : float) : float3
  let ang = predefined_angles[member_idx % length(predefined_angles)]
  var sine, cosine : float
  sincos(ang, sine, cosine)
  let offset = float((member_idx / length(predefined_angles)) + 1) * spread
  return float3(cosine * offset, 0.0, sine * offset)

[es (tag=server, before=(squad_es))]
def squad_members_count_es(act : ecs::UpdateStageInfoAct; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId;
                           squad_dot_orderType : int; squad_dot_orderUseEntity : EntityId;
                           squad_dot_shouldStandExactAtOrderPoint : bool; squad_dot_spreadAroundOrderPoint : float2;
                           var squad_dot_numAliveMembers : int&;
                           var squad_dot_numMembers : int&; var squad_dot_isCheckMembersDeffered : bool&)
  if squad_dot_isCheckMembersDeffered
    squad_dot_isCheckMembersDeffered = false
    var numMembers = 0
    var numAliveMembers = 0
    var memberIdx = 0
    let squad_eid = eid
    var shouldStandExactAtOrderPoint = squad_dot_shouldStandExactAtOrderPoint && squad_dot_orderType == int(SquadOrder ESO_DEFEND_POINT) && squad_dot_orderUseEntity == INVALID_ENTITY_ID
    ecs::query() <| $ [es] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId;
                            var squad_member_dot_offset : float3&; isAlive : bool; isDowned = false)
      if squad_eid != squad_member_dot_squad
        return
      numMembers++
      if isAlive
        numAliveMembers++
      if (eid != squad_dot_leader) && !shouldStandExactAtOrderPoint
        squad_member_dot_offset = recalc_member_offset(memberIdx++, squad_dot_spreadAroundOrderPoint.y)
      elif isAlive && !isDowned
        shouldStandExactAtOrderPoint = false
        squad_member_dot_offset = float3(0.0, 0.0, 0.0)

    squad_dot_numMembers = max(squad_dot_numMembers, numMembers)
    squad_dot_numAliveMembers = numAliveMembers
