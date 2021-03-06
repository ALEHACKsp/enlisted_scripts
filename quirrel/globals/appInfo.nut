local {get_setting_by_blk_path} = require("settings")
local {dd_file_exist} = require("dagor.fs")
local {Watched, Computed} = require("frp")
local { get_game_name, get_circuit_conf, get_circuit, get_exe_version, get_build_number } = require("app")

local circuit = Watched(get_circuit())
local exe_version = Watched(get_exe_version())
local build_number = Watched(get_build_number())

//fixme: probably should be done differently in dedicated, I guess yup file is not accessable there and in anywhere it has different name
//fixme: this is not correct in consoles, cause there are version for vroms (no api yet to get) and for main game
local project_yup_name = get_setting_by_blk_path("yupfile") ?? "{0}.yup".subst(get_game_name())
local yup_version = Watched(dd_file_exist(project_yup_name)
  ? require("yupfile_parse").getStr(project_yup_name, "yup/version")
  : null)

local circuitEnv = Watched(get_circuit_conf().getStr("environment", ""))
local version = Computed(@() yup_version.value ?? exe_version.value)
//FIXME - for unknown reason in internal tests (at least in dev exe circuitEnv=="")
local isProductionCircuit = Computed(@() !(circuitEnv.value!="production"))
local isInternalCircuit = Computed(@() circuitEnv.value=="test")

return {
  version,
  isProductionCircuit,
  isInternalCircuit,
  project_yup_name = Watched(project_yup_name),
  yup_version,
  exe_version,
  build_number,
  circuit,
  circuit_environment = circuitEnv
}
 