require vehicle

[generic]
def find_index_if(arr : vehicle::VehicleSeatOwners; condition : block<(elem : VehicleSeatsOwner):bool>) : int
  for i in iter_range(arr)
    if invoke(condition, arr[i])
      return i
  return -1
