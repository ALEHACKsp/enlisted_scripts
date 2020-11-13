require ecs
require player
require HumanPhys
require enlisted.game.es.artillery_radio_common

[es (tag=gameClient, REQUIRE=(heroSquad,isAlive,isDowned,human_weap_dot_gunEids), track=(isAlive,isDowned,human_weap_dot_gunEids), on_event=EventComponentsAppear)]
def artillery_radio_available(evt : Event)
  let available = find_query() <| $ [es (REQUIRE=heroSquad)] (human_weap_dot_gunEids : EidList;
                                                              isAlive : bool;
                                                              isDowned : bool)
    let gunne = human_weap_dot_gunEids[int(HUWeaponSlots EWS_SECONDARY)]
    var radio = false
    query(gunne) <| $ [es (REQUIRE=radio_use)] ()
      radio = true
    return isAlive && !isDowned && has_radio(human_weap_dot_gunEids)
  setOptional(get_local_player_eid(), "artillery.available", available)

[es (tag=gameClient, REQUIRE=(radio_use), on_event=(EventEntityCreated, EventComponentsAppear))]
def artillery_radio_available_radio_created(evt : Event; gun_dot_owner : EntityId)
  query(gun_dot_owner) <| $[es (REQUIRE=heroSquad)](isAlive : bool; isDowned : bool)
    query() <| $[es (REQUIRE=player)] (var artillery_dot_available : bool&)
      artillery_dot_available ||= (isAlive && !isDowned)

def track_artillery_was_available_for_squad()
  query() <| $[es (REQUIRE=player)] (possessed : EntityId;
                                     artillery_dot_available : bool;
                                     var artillery_dot_wasAvailableForSquad : EntityId&)
    let heroSquad = get_Eid(possessed, "squad_member.squad") ?? INVALID_ENTITY_ID
    if heroSquad == INVALID_ENTITY_ID
      artillery_dot_wasAvailableForSquad = INVALID_ENTITY_ID
      return
    if artillery_dot_wasAvailableForSquad != heroSquad
      artillery_dot_wasAvailableForSquad = artillery_dot_available ? heroSquad : INVALID_ENTITY_ID

[es (tag=gameClient, REQUIRE=(player,artillery_dot_available), track=artillery_dot_available, on_event=EventComponentsAppear)]
def artillery_radio_was_available_for_squad_player(evt : Event)
  track_artillery_was_available_for_squad()

[es (tag=gameClient, REQUIRE=(hero,squad_member_dot_squad), track=squad_member_dot_squad, on_event=EventComponentsAppear)]
def artillery_radio_was_available_for_squad_changed_squad(evt : Event)
  track_artillery_was_available_for_squad()
