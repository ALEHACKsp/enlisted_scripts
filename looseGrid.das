require ecs
require DagorMath
require LooseGrid

[generic]
def gather_entities_in_loose_grid(name : string const; from, to : float3; subexpr:block<(data:array<ecs::EntityId>):void>)
  _builtin_entities_in_loose_grid_box(name, from, to, subexpr)

[generic]
def gather_entities_in_loose_grid(name : string const; from : float3; radius : float; subexpr:block<(data:array<ecs::EntityId>):void>)
  _builtin_entities_in_loose_grid_sphere(name, from, radius, subexpr)
