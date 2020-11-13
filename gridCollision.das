require GridCollision

[generic]
def for_each_object_in_grid(grid_type : GridType; bbox : BBox3; subexpr:block<(data:TraceableGridCollision#):void>) : void
  for_each_object_in_grid(grid_type, bbox, false, subexpr)

