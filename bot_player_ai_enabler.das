require ecs

[es (tag=server, track=possessed, REQUIRE=botAiEnabler)]
def bot_player_ai_enabler_es(evt:Event; possessed:ecs::EntityId)
  ecs::query(possessed) <| $ [es] (var beh_tree_dot_enabled : bool&; var respawner_dot_allowForceRespawn : bool&)
    beh_tree_dot_enabled = true
    respawner_dot_allowForceRespawn = true
