options remove_unused_symbols = false
module app_common
require app
require DagorDataBlock

def is_dev_circuit()
  var isDev = false
  get_circuit_conf() <| $(var blk: DataBlock?)
    isDev = datablock_getStr(blk, "environment", "") != "production"
  return isDev

def is_production_circuit()
  return !is_dev_circuit()