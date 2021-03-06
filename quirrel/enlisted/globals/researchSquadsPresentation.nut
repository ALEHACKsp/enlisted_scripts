local SQUAD_UPGRADES = {
  name = "research/squad_upgrades"
  description = "research/squad_upgrades_desc"
  bg_color = 0xff324b5f
}

local SQUAD_UPGRADES_USSR = SQUAD_UPGRADES.__merge({ icon_id = "star_soviet" })
local SQUAD_UPGRADES_GER  = SQUAD_UPGRADES.__merge({ icon_id = "german_cross" })
local SQUAD_UPGRADES_USA  = SQUAD_UPGRADES.__merge({ icon_id = "ammo" }) // TODO replace with more usa specific default icon

local PERSONELL_UPGRADES = {
  name = "research/personell_upgrades"
  description = "research/personell_upgrades_desc"
  bg_color = 0xff883d3d
}

local PERSONELL_UPGRADES_USSR = PERSONELL_UPGRADES.__merge({ icon_id = "star_soviet" })
local PERSONELL_UPGRADES_GER  = PERSONELL_UPGRADES.__merge({ icon_id = "german_cross" })
local PERSONELL_UPGRADES_USA  = PERSONELL_UPGRADES.__merge({ icon_id = "ammo" })

local WORKSHOP_UPGRADES = {
  name = "research/army_workshop_upgrades"
  description = "research/army_workshop_upgrades_desc"
  bg_color = 0xff808054
}

local WORKSHOP_UPGRADES_USSR = WORKSHOP_UPGRADES.__merge({ icon_id = "star_soviet" })
local WORKSHOP_UPGRADES_GER  = WORKSHOP_UPGRADES.__merge({ icon_id = "german_cross" })
local WORKSHOP_UPGRADES_USA  = WORKSHOP_UPGRADES.__merge({ icon_id = "ammo" })

return {
  berlin_allies = [
    SQUAD_UPGRADES_USSR
    PERSONELL_UPGRADES_USSR
    WORKSHOP_UPGRADES_USSR
  ]
  berlin_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
  moscow_allies = [
    SQUAD_UPGRADES_USSR
    PERSONELL_UPGRADES_USSR
    WORKSHOP_UPGRADES_USSR
  ]
  moscow_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
  normandy_allies = [
    SQUAD_UPGRADES_USA
    PERSONELL_UPGRADES_USA
    WORKSHOP_UPGRADES_USA
  ]
  normandy_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
  tunisia_allies = [
    SQUAD_UPGRADES_USA
    PERSONELL_UPGRADES_USA
    WORKSHOP_UPGRADES_USA
  ]
  tunisia_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
} 