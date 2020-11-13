require ecs
require EnlistedHuman

[es(on_event=EventComponentChanged, track=human_state_dot_lockCrawl)]
def human_lock_crawl_es_event_handler(evt : Event; human_state_dot_lockCrawl : bool; var human_net_phys : HumanActor)
  human_net_phys.phys.canCrawl = !human_state_dot_lockCrawl

[es(on_event=EventComponentChanged, track=human_state_dot_lockCrouch)]
def human_lock_crouch_es_event_handler(evt : Event; human_state_dot_lockCrouch : bool; var human_net_phys : HumanActor)
  human_net_phys.phys.canCrouch = !human_state_dot_lockCrouch

[es(tag=gameClient, track=isInVehicle, REQUIRE=(human_input, isInVehicle))]
def human_input_enter_exit(evt : Event; eid : EntityId)
  human_input_set_stand_state(eid, 0)