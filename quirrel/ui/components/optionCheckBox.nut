local checkbox = require("ui/components/checkbox.nut")

local override = {
  size = flex()
  valign = ALIGN_CENTER
}

return @(opt, group, xmbNode)
  checkbox(opt.var, null, {
    group = group
    override = override.__merge({xmbNode=xmbNode})
    useHotkeys = true
    setValue = opt?.setValue
  })
 