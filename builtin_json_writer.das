
options indenting = 4

def jw_key_value(var jw; k : string; v)
    jw_key(jw, k)
    jw_value(jw, v)

def jw_writer(cb : block<(var JsonWriter):void>)
    __builtin_jw_writer(cb)
