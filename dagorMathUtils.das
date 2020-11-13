[generic]
def test_segment_sphere_intersection(segment_start; segment_end; sphere_center; squared_sphere_radius)
  var dist: float
  return test_segment_sphere_intersection(segment_start, segment_end, sphere_center, squared_sphere_radius, dist)
