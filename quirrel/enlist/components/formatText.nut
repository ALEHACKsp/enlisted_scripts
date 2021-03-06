local formatters = require("textFormatters.nut")
local platform = require("globals/platform.nut")
local {defStyle} = formatters
local curPlatform = platform.id
local filter =  function(object) {
  return !(object?.platform == null || object.platform.indexof(curPlatform)!=null || (platform.is_pc && object.platform.indexof("pc")!=null))
}
local formatText = require("daRg/components/mkFormatAst.nut")({formatters=formatters, style=defStyle, filter=filter})

return {
  formatText = formatText
  defStyle = defStyle
}
 