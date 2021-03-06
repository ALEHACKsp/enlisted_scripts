local { apply_customization } = require("customization")
local function destroyChar(char) {
  if (char != INVALID_ENTITY_ID)
    ::ecs.g_entity_mgr.destroyEntity(char)
}

local function onInit(evt, myEid, comp) {
  destroyChar(comp["menu_char_controller.characterToControl"])

  if (!comp["menu_char_controller.show"])
    return

  local comps = {
    "transform" : [comp.transform, ::ecs.TYPE_MATRIX],
  }
  local templ = comp["menu_char_controller.characterTemplate"]
  local itemslist = comp["menu_char_controller.itemsList"].getAll()
  local modComps = apply_customization(templ, itemslist, comps)
  modComps["human_sec_anim.setup"] <- "gamedata/emotes/menu.anim.blk"
  comp["menu_char_controller.characterToControl"] = ::ecs.g_entity_mgr.createEntity(templ, modComps)
}

::ecs.register_es("menu_char_controller_es", {
  onInit = onInit,
  onChange = onInit,
  onDestroy = @(evt, eid, comp) destroyChar(comp["menu_char_controller.characterToControl"])
}, {
  comps_rw = [
    ["menu_char_controller.characterToControl", ::ecs.TYPE_EID],
  ],
  comps_ro = [
    ["transform", ::ecs.TYPE_MATRIX],
  ]
  comps_track = [
    ["menu_char_controller.characterTemplate", ::ecs.TYPE_STRING],
    ["menu_char_controller.itemsList", ::ecs.TYPE_ARRAY],
    ["menu_char_controller.show", ::ecs.TYPE_BOOL, true],
  ]
},
{tags="gameClient"})

 