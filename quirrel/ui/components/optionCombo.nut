local combobox = require("combobox.nut")

local function optionCombo(opt, group, xmbNode) {
  local ItemWrapper = class{
    item = null
    constructor(item_)   { item = item_ }
    function _tostring() { return opt.valToString(item) }
    function isCurrent() { return opt.isEqual(item, opt.var.value)}
    function value()     { return item }
  }
  local { available } = opt
  local items = available instanceof ::Watched
    ? ::Computed(@() available.value.map(@(v) ItemWrapper(v)))
    : available.map(@(v) ItemWrapper(v))

  return opt?.setValue
    ? combobox({ value = opt.var, update = opt.setValue, changeVarOnListUpdate = opt?.changeVarOnListUpdate ?? true },
               items,
               {useHotkeys = true, xmbNode=xmbNode})
    : combobox({ value = opt.var, _tostring = @() opt.valToString(opt.var.value), changeVarOnListUpdate = opt?.changeVarOnListUpdate ?? true },
               items,
               {useHotkeys = true, xmbNode=xmbNode})
}


return optionCombo
 