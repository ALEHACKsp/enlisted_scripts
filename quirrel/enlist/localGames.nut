local { scan_local_games } = require("game_load")
local localGames = persist("localGames", scan_local_games)
return localGames
 