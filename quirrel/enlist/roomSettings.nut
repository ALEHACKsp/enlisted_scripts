local random = require("dagor.random")
local localGames = require("localGames.nut")
local localSettings = require("options/localSettings.nut")("createRoom/")

local settings = {
  minPlayers = 1
  maxPlayers = 32
  roomName = "room_{0}".subst(random.rnd_int(1, 10000))
  startOffline = false
  botsPopulation = 0
  writeReplay = false
  groupSize = 1
}.map(localSettings)

local sceneFilter = @(scene) (scene?.title[0] ?? '_') != '_'

settings.savedGameId <- localSettings("", "game")
settings.savedSceneId <- localSettings("", "scene")
local game = Watched(localGames?[settings.savedGameId.value])
local scenes = Computed(@() (game.value?.scenes ?? []).filter(sceneFilter))
local scene = Watched(scenes.value.findvalue(@(s) s.id == settings.savedSceneId.value))
settings.game <- game
settings.scenes <- scenes
settings.scene <- scene

game.subscribe(@(g) settings.savedGameId(g?.id ?? ""))
scene.subscribe(@(s) settings.savedSceneId(s?.id ?? ""))
scenes.subscribe(@(s) scene(s?[0]))
settings.minPlayers.subscribe(@(p) settings.maxPlayers(::max(p, settings.maxPlayers.value)))
settings.maxPlayers.subscribe(@(p) settings.minPlayers(::min(p, settings.minPlayers.value)))

if (scenes.value.len()  == 0)
  foreach (id, g in localGames)
    if (g.scenes.filter(sceneFilter).len() > 0)
      game(g)

local curGameScenes = settings.game.value?.scenes ?? []
if (curGameScenes.indexof(settings.scene.value) == null)
  settings.scene(curGameScenes?[0])

return settings
 