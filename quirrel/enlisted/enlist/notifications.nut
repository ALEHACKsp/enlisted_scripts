require("enlist/notifications.nut") //require common notifications
require("soldiers/newItemsWnd.nut")
require("soldiers/model/console_cmd.nut")

local gameLauncher = require("enlist/gameLauncher.nut")
local canSave = require("enlisted/enlist/meta/saveProfile.nut").canSave

gameLauncher.gameClientActive.subscribe(@(isActive) canSave(!isActive)) 