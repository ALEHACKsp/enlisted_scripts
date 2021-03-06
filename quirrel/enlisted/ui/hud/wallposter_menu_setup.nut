local { wallposterMenuItems, showWallposterMenu, elemSize } = require("enlisted/ui/hud/state/wallposter_menu.nut")
local { wallPosters } = require("enlisted/ui/hud/state/wallposter.nut")
local { localPlayerEid } = require("ui/hud/state/local_player.nut")
local { CmdWallposterPreview } = require("wallposterevents")
local mkPieItemCtor = require("enlisted/ui/hud/components/wallposter_menu_item_ctor.nut")

local svg = @(img) "!ui/uiskin/{0}.svg:{1}:{1}:K".subst(img, elemSize.value[1])

wallPosters.subscribe(function (posters) {
  wallposterMenuItems(posters.map(function (poster, index) {
    local template = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(poster["template"])
    local text = template?.getCompValNullable?("wallposter_menu.text") ?? ""
    local imageName = template?.getCompValNullable?("wallposter_menu.image")
    local image = imageName ? svg(imageName) : null
    local hintText = ::loc(text)
    return {
      action = @() ::ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdWallposterPreview(true, index))
      text = hintText
      closeOnClick = true
      ctor = mkPieItemCtor(index, image, hintText)
    }
  }))
  if (posters.len() == 0)
    showWallposterMenu(false)
})
 