[generic]
def BBox3(bbox : bbox3f)
  return <- BBox3(bbox.bmin.xyz, bbox.bmax.xyz)
