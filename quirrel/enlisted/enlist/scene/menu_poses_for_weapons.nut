local standartRifle = ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_13_weapon","enlisted_idle_14_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
local specificRifle = ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_14_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
local specificGun = ["enlisted_idle_09_weapon","enlisted_idle_11_weapon","enlisted_idle_12_weapon","enlisted_idle_13_weapon","enlisted_idle_14_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
local standardPistol = ["enlisted_idle_03","enlisted_idle_02","enlisted_idle_19_weapon"]
local weaponToAnimState = {
  defaultPoses = ["enlisted_idle_11_weapon"]
  standartRifle = standartRifle
  specificRifle = specificRifle
  specificGun = specificGun
  standardPistol = standardPistol

  tt_33_gun =                  standardPistol
  nagant_m1895_gun =           standardPistol
  tk_26_gun =                  standardPistol
  mauser_c96_gun =             standardPistol
  p38_walther_gun =            standardPistol
  p08_luger_gun =              standardPistol
  mauser_c96_m712_gun =        standardPistol
  m1911_colt_gun =             standardPistol
  colt_walker_gun =            standardPistol
  leuchtpistole_42_gun =       standardPistol

  mosin_m38_gun =              standartRifle
  mosin_m91_gun =              standartRifle
  mosin_m91_30_gun =           standartRifle
  mosin_m1907_gun =            standartRifle
  mosin_dragoon_gun =          standartRifle
  mosin_infantry_gun =         standartRifle

  gewehr_41_gun =              specificRifle
  gewehr_43_gun =              specificRifle
  gewehr_41_mauser_gun =       ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  avs_36_gun =                 specificRifle
  svt_38_gun =                 specificRifle
  svt_40_gun =                 specificRifle
  avt_40_gun =                 specificRifle
  akt_40_gun =                 ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_14_weapon","enlisted_idle_18_weapon"]

  browning_auto_5_gun =        specificGun
  m30_luftwaffe_drilling_gun = specificGun
  winchester_model_1912_gun =  ["enlisted_idle_09_weapon","enlisted_idle_11_weapon","enlisted_idle_12_weapon","enlisted_idle_14_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]

  mauser_98k_gun =             specificGun
  kar98k_with_scope_mount_gun = specificGun
  kar98k_kriegsmodell_gun =    specificGun
  gewehr_33_40_gun =           specificGun
  m1903_springfield_gun =      specificGun
  m1903a4_springfield_gun =    specificGun
  m1_garand_gun =              specificGun
  m1_carbine_gun =             ["enlisted_idle_09_weapon","enlisted_idle_11_weapon","enlisted_idle_12_weapon","enlisted_idle_14_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  m1a2_carbine_gun =           ["enlisted_idle_09_weapon","enlisted_idle_14_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  vz_24_gun =                  specificGun
  winchester_1895_gun =        specificGun

  akm_47_gun =                 ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  fedorov_avtomat_gun =        ["enlisted_idle_16_weapon","enlisted_idle_12_weapon"]
  stg_44_gun =                 ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  mp43_1_gun =                 ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  vstg_1_5_gun =               ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]

  beretta_m38_gun =            ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_14_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  m3_submachine_gun_gun =      ["enlisted_idle_18_weapon"]
  mp_18_gun =                  ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_13_weapon","enlisted_idle_14_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]
  mp_35_gun =                  ["enlisted_idle_09_weapon","enlisted_idle_11_weapon","enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_18_weapon"]
  mp_38_gun =                  ["enlisted_idle_11_weapon","enlisted_idle_15_weapon"]
  mp40_gun =                   ["enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  mp41_gun =                   ["enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  m50_reising_gun =            ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  sten_mk2_gun =               ["enlisted_idle_13_weapon","enlisted_idle_14_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]
  ppsh_41_gun =                ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]
  ppd_3438_gun =               ["enlisted_idle_09_weapon","enlisted_idle_11_weapon","enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]
  ppd_3438_box_gun =           ["enlisted_idle_09_weapon","enlisted_idle_11_weapon","enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]
  ppd_40_gun =                 ["enlisted_idle_09_weapon","enlisted_idle_11_weapon","enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]
  ppk_41_gun =                 ["enlisted_idle_11_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]
  pps_43_gun =                 ["enlisted_idle_09_weapon","enlisted_idle_12_weapon","enlisted_idle_15_weapon"]
  pps_42_gun =                 ["enlisted_idle_11_weapon","enlisted_idle_12_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon"]
  m1a1_thompson_gun =          ["enlisted_idle_12_weapon","enlisted_idle_16_weapon"]
  m1921ac_thompson_gun =       ["enlisted_idle_10_weapon"]
  thompson_m1928a1_box_mag_gun = ["enlisted_idle_12_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]

  browning_m1918_gun =         ["enlisted_idle_12_weapon","enlisted_idle_13_weapon","enlisted_idle_15_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  mg_42_handheld_gun =         ["enlisted_idle_12_weapon","enlisted_idle_14_weapon","enlisted_idle_16_weapon"]
  mg_34_gun =                  ["enlisted_idle_14_weapon"]
  dp_27_gun =                  ["enlisted_idle_08_weapon","enlisted_idle_15_weapon"]
  fg_42_gun =                  ["enlisted_idle_12_weapon","enlisted_idle_13_weapon","enlisted_idle_16_weapon"]
  rd_44_gun =                  ["enlisted_idle_15_weapon"]
  madsen_gun =                 ["enlisted_idle_08_weapon","enlisted_idle_15_weapon"]
  zb_26_gun =                  ["enlisted_idle_08_weapon","enlisted_idle_15_weapon"]

  ptrs_41_gun =                ["enlisted_idle_07_weapon", "enlisted_idle_06_weapon", "enlisted_idle_18_weapon", "enlisted_idle_16_weapon", "enlisted_idle_17_weapon"]
  ptrd_41_gun =                ["enlisted_idle_07_weapon", "enlisted_idle_06_weapon", "enlisted_idle_18_weapon", "enlisted_idle_16_weapon", "enlisted_idle_17_weapon"]
  pzb_38_gun =                 ["enlisted_idle_13_weapon", "enlisted_idle_08_weapon" , "enlisted_idle_13_weapon", "enlisted_idle_17_weapon"]
  pzb_39_gun =                 ["enlisted_idle_13_weapon", "enlisted_idle_08_weapon" , "enlisted_idle_13_weapon", "enlisted_idle_17_weapon"]

  panzerschreck_gun =          ["enlisted_idle_05_weapon"]
  captured_panzerschreck_gun = ["enlisted_idle_05_weapon"]
  rpzb_43_ofenrohr_gun =       ["enlisted_idle_05_weapon"]
  rpzb_54_1_panzerschreck_gun = ["enlisted_idle_05_weapon"]
  m1_bazooka_gun =             ["enlisted_idle_08_weapon","enlisted_idle_11_weapon","enlisted_idle_14_weapon","enlisted_idle_15_weapon","enlisted_idle_18_weapon"]

  roks_3_gun =                 ["enlisted_idle_12_weapon","enlisted_idle_14_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
  roks_2_gun =                 ["enlisted_idle_12_weapon","enlisted_idle_14_weapon","enlisted_idle_16_weapon","enlisted_idle_18_weapon"]
//flammenwerfer_35_gun         //wip asset
//m2_flamethrower_gun =        //wip asset

//  m1941_johnson_gun =          specificRifle  //wip asset
//  ithaca_37_gun =              specificRifle  //wip asset
//  winchester_model_1912_gun =  specificRifle  //wip asset
//  lee_enfield_no4_mk1_gun =    specificRifle  //wip asset
//  m1917_enfield_gun =          specificRifle  //wip asset
}

return weaponToAnimState 