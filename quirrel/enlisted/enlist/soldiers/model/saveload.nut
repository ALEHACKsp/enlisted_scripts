local json = require("std/json.nut")
local { dd_file_exist } = require("dagor.fs")
local { DBGLEVEL } = require("dagor.system")

local logg = DBGLEVEL !=0 ? ::log_for_user : ::log.log

local function save(filename, data, pretty_print=true){
  json.save(filename, data, {pretty_print = pretty_print, logger = logg})
}

local function load(filename, initializer){
  assert(::type(initializer)=="function")
  assert(::type(filename)=="string")
  if (!dd_file_exist(filename))
    save(filename, initializer())
  return json.load(filename, {logger = logg})
}

return {
  load = load
  save = save
} 