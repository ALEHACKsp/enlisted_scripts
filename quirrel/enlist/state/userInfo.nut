local sharedWatched = require("globals/sharedWatched.nut")
//null or {userId=-1 userIdStr="" name=string or null, token=string or null}
return sharedWatched("userInfo", @() null)
 