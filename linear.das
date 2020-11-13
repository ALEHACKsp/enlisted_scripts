options remove_unused_symbols = false
module linear
require math
require math.base

[generic]
def closest_pt_on_seg(point, a, b)
  let abVec = b - a
  let abLen = length(abVec)
  let dir = abVec * rcp(abLen)
  let t = dot(point - a, dir)
  return a + dir * clamp(t, 0.0, abLen);

[generic]
def distance_sq_to_seg(point, a, b) : float
  let pt = closest_pt_on_seg(point, a, b)
  return length_sq(point - pt)

[generic]
def distance_to_line(point, a, dir) : float
  let t = dot(point - a, dir)
  let pt = a + dir * float3(t)
  return distance(point, pt)
