local string = require("string")
local logo_size=sh(6)

local function image_from_attr(image_name) {
  ::assert(::type(image_name)=="string" || image_name==null, "image_name should be string")
  if (image_name==null)
    return null
  if (string.endswith(image_name, "svg"))
    return Picture("{0}:{1}:{1}:K".subst(image_name,logo_size.tointeger()))
  return Picture("{0}".subst(image_name))
}

local mk_team_image = @(state) @() {
  rendObj = ROBJ_IMAGE
  watch = state
  image = image_from_attr(state.value)
}

return mk_team_image 