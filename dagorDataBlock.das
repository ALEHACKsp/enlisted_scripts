require DagorDataBlock
require DagorMath

[generic]
def datablock_clear_data(var blk: DataBlock)
  unsafe
    addr(blk) |> datablock_clear_data()

[generic]
def datablock_reset(var blk: DataBlock)
  unsafe
    addr(blk) |> datablock_reset()

[generic]
def datablock_load(var blk: DataBlock; fname: string)
  unsafe
    return addr(blk) |> datablock_load(fname)

[generic]
def datablock_get_block(var blk: DataBlock; block_number: int)
  unsafe
    return addr(blk) |> datablock_get_block(block_number)

[generic]
def datablock_get_block_by_name(var blk: DataBlock; name: string)
  unsafe
    return addr(blk) |> datablock_get_block_by_name(name)

[generic]
def datablock_find_param(var blk: DataBlock; name_id: int)
  unsafe
    return addr(blk) |> datablock_find_param(name_id)

[generic]
def datablock_param_exists(var blk: DataBlock; name_id: int)
  unsafe
    return addr(blk) |> datablock_param_exists(name_id)

[generic]
def datablock_add_block(var blk: DataBlock; name: string)
  unsafe
    return addr(blk) |> datablock_add_block(name)

[generic]
def datablock_add_new_block(var blk: DataBlock; name: string)
  unsafe
    return addr(blk) |> datablock_add_new_block(name)

[generic]
def datablock_get_param_name(var blk: DataBlock; param_number: int)
  unsafe
    return addr(blk) |> datablock_get_param_name(param_number)

[generic]
def datablock_getStr(var blk: DataBlock; param_name: string; default_value: string)
  unsafe
    return addr(blk) |> datablock_getStr(param_name, default_value)

[generic]
def datablock_getBool(var blk: DataBlock; param_name: string; default_value: bool)
  unsafe
    return addr(blk) |> datablock_getBool(param_name, default_value)

[generic]
def datablock_getInt(var blk: DataBlock; param_name: string; default_value: int)
  unsafe
    return addr(blk) |> datablock_getInt(param_name, default_value)

[generic]
def datablock_getReal(var blk: DataBlock; param_name: string; default_value: float)
  unsafe
    return addr(blk) |> datablock_getReal(param_name, default_value)

[generic]
def datablock_getPoint2(var blk: DataBlock; param_name: string; default_value: float2)
  unsafe
    return addr(blk) |> datablock_getPoint2(param_name, default_value)

[generic]
def datablock_getPoint3(var blk: DataBlock; param_name: string; default_value: float3)
  unsafe
    return addr(blk) |> datablock_getPoint3(param_name, default_value)

[generic]
def datablock_getPoint4(var blk: DataBlock; param_name: string; default_value: float4)
  unsafe
    return addr(blk) |> datablock_getPoint4(param_name, default_value)

[generic]
def datablock_getIPoint2(var blk: DataBlock; param_name: string; default_value: int2)
  unsafe
    return addr(blk) |> datablock_getIPoint2(param_name, default_value)

[generic]
def datablock_getIPoint3(var blk: DataBlock; param_name: string; default_value: int3)
  unsafe
    return addr(blk) |> datablock_getIPoint3(param_name, default_value)

[generic]
def datablock_getE3dcolor(var blk: DataBlock; param_name: string; default_value: E3DCOLOR)
  unsafe
    return addr(blk) |> datablock_getE3dcolor(param_name, default_value)

[generic]
def datablock_setStr(var blk: DataBlock; name: string; value: string)
  unsafe
    return addr(blk) |> datablock_setStr(name, value)

[generic]
def datablock_setBool(var blk: DataBlock; name: string; value: bool)
  unsafe
    return addr(blk) |> datablock_setBool(name, value)

[generic]
def datablock_setInt(var blk: DataBlock; name: string; value: int)
  unsafe
    return addr(blk) |> datablock_setInt(name, value)

[generic]
def datablock_setReal(var blk: DataBlock; name: string; value: float)
  unsafe
    return addr(blk) |> datablock_setReal(name, value)

[generic]
def datablock_setPoint2(var blk: DataBlock; name: string; value: float2)
  unsafe
    return addr(blk) |> datablock_setPoint2(name, value)

[generic]
def datablock_setPoint3(var blk: DataBlock; name: string; value: float3)
  unsafe
    return addr(blk) |> datablock_setPoint3(name, value)

[generic]
def datablock_setPoint4(var blk: DataBlock; name: string; value: float4)
  unsafe
    return addr(blk) |> datablock_setPoint4(name, value)

[generic]
def datablock_setIPoint2(var blk: DataBlock; name: string; value: int2)
  unsafe
    return addr(blk) |> datablock_setIPoint2(name, value)

[generic]
def datablock_setIPoint3(var blk: DataBlock; name: string; value: int3)
  unsafe
    return addr(blk) |> datablock_setIPoint3(name, value)

[generic]
def datablock_setE3dcolor(var blk: DataBlock; name: string; value: E3DCOLOR)
  unsafe
    return addr(blk) |> datablock_setE3dcolor(name, value)

[generic]
def datablock_addStr(var blk: DataBlock; name: string; value: string)
  unsafe
    return addr(blk) |> datablock_addStr(name, value)

[generic]
def datablock_addBool(var blk: DataBlock; name: string; value: bool)
  unsafe
    return addr(blk) |> datablock_addBool(name, value)

[generic]
def datablock_addInt(var blk: DataBlock; name: string; value: int)
  unsafe
    return addr(blk) |> datablock_addInt(name, value)

[generic]
def datablock_addReal(var blk: DataBlock; name: string; value: float)
  unsafe
    return addr(blk) |> datablock_addReal(name, value)

[generic]
def datablock_addPoint2(var blk: DataBlock; name: string; value: float2)
  unsafe
    return addr(blk) |> datablock_addPoint2(name, value)

[generic]
def datablock_addPoint3(var blk: DataBlock; name: string; value: float3)
  unsafe
    return addr(blk) |> datablock_addPoint3(name, value)

[generic]
def datablock_addPoint4(var blk: DataBlock; name: string; value: float4)
  unsafe
    return addr(blk) |> datablock_addPoint4(name, value)

[generic]
def datablock_addIPoint2(var blk: DataBlock; name: string; value: int2)
  unsafe
    return addr(blk) |> datablock_addIPoint2(name, value)

[generic]
def datablock_addIPoint3(var blk: DataBlock; name: string; value: int3)
  unsafe
    return addr(blk) |> datablock_addIPoint3(name, value)

[generic]
def datablock_addE3dcolor(var blk: DataBlock; name: string; value: E3DCOLOR)
  unsafe
    return addr(blk) |> datablock_addE3dcolor(name, value)

[generic]
def datablock_remove_param(var blk: DataBlock; name: string)
  unsafe
    return addr(blk) |> datablock_remove_param(name)

[generic]
def datablock_remove_block(var blk: DataBlock; name: string)
  unsafe
    return addr(blk) |> datablock_remove_block(name)

[generic]
def datablock_save_to_text_file(var blk: DataBlock; filename: string)
  unsafe
    return addr(blk) |> datablock_save_to_text_file(filename)

[generic]
def datablock_save_to_binary_file(var blk: DataBlock; filename: string)
  unsafe
    return addr(blk) |> datablock_save_to_binary_file(filename)

[generic]
def datablock_change_block_name(var blk: DataBlock; name: string)
  unsafe
    addr(blk) |> datablock_change_block_name(name)

[generic]
def datablock_load_text(var blk: DataBlock; text: string; text_length: int)
  unsafe
    return addr(blk) |> datablock_load_text(text, text_length)

[generic]
def debug_print_datablock(name: string; blk: DataBlock)
  unsafe
    debug_print_datablock(name, addr(blk))
