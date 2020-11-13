require ecs
require game.es.lut_switcher_common

[es (track=(isOutsideBattleArea, input_dot_enabled), on_event=EventComponentsAppear, REQUIRE=(hero, watchedByPlr))]
def tonemapper_switcher_outside_battle_area(evt : Event; isOutsideBattleArea : bool; input_dot_enabled : bool)
  query() <| $ [es] (var color_grading_items : Array; color_grading_dot_outOfbattleArea : Object)
    switch_color_grading(ecs_hash("battle_area"), color_grading_items, color_grading_dot_outOfbattleArea, isOutsideBattleArea && input_dot_enabled)