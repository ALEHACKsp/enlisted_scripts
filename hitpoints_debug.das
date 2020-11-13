require ecs
require ecs.common
require DagorConsole
require game.utils.hero

[console_cmd(name="hitpoints.set_hero_hp")]
def set_hero_hp(value : float)
  query(get_controlled_hero()) <| $[es](var hitpoints_dot_hp : float&)
    hitpoints_dot_hp = value

[console_cmd(name="hitpoints.set_hero_maxhp")]
def set_hero_maxhp(value : float)
  query(get_controlled_hero()) <| $[es](var set_hero_maxhp : float&)
    set_hero_maxhp = value

[console_cmd(name="hitpoints.set_hero_downed")]
def set_hero_downed()
  query(get_controlled_hero()) <| $[es](var hitpoints_dot_hp : float&; var hitpoints_dot_alwaysAllowRevive : bool&)
    hitpoints_dot_hp = 0f
    hitpoints_dot_alwaysAllowRevive = true

[console_cmd(name="hitpoints.hero_god_mode")]
def hero_god_mode()
  set_hero_hp(999999f)

[console_cmd(name="hitpoints.set_players_downed")]
def set_players_downed(downed_timer : float = 15f)
  query() <| $[es] (possessedByPlr : EntityId;
                    var hitpoints_dot_alwaysAllowRevive : bool&; var hitpoints_dot_hp, hitpoints_dot_downedTimer : float&)
    if !possessedByPlr
      return
    hitpoints_dot_alwaysAllowRevive = true
    hitpoints_dot_hp = 0f
    hitpoints_dot_downedTimer = downed_timer

[console_cmd(name="hitpoints.set_players_hp")]
def set_players_hp(value : float = 20f)
  query() <| $[es] (possessedByPlr : EntityId; var hitpoints_dot_hp : float&)
    if !possessedByPlr
      return
    hitpoints_dot_hp = value

