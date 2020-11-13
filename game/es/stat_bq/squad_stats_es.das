require ecs
require enlisted.game.es.enlisted_events
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq

[es]
def send_new_player_order_bq(evt : RequestSquadOrder; squad_dot_leader : EntityId)
  new_player_order_bq(squad_dot_leader, "{evt.orderType}")

[es]
def send_new_player_mate_order_bq(evt : RequestSquadMateOrder; squad_dot_leader : EntityId)
  new_player_order_bq(squad_dot_leader, "{evt.orderType}")