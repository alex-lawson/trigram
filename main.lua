settings = {
  mapSize = {15, 11},
  tileSize = {16, 16},
  tileCount = 3,
  renderScale = 3.0,
  guiScale = 4.0,
  mapPadding = vec4(300, 50, 50, 100),
  mapScreenSize = vec2(0),
  mapScreenRect = vec4(0)
}

local util = require "util"
local Game = require "game"
local Interface = require "interface"

function setupWindow()
  settings.mapScreenSize = vec2(settings.mapSize[1] * settings.tileSize[1] * settings.renderScale, settings.mapSize[2] * settings.tileSize[2] * settings.renderScale)

  win = am.window{
      title = "Trigrams",
      width = settings.mapPadding[1] + settings.mapScreenSize[1] + settings.mapPadding[3],
      height = settings.mapPadding[2] + settings.mapScreenSize[2] + settings.mapPadding[4],
      resizable = false,
      -- projection = mat4(1)
      -- projection = mat4(1 / mapLayer.size[1], 0, 0, -xSize / 2 + 1 / mapLayer.size[1],
      --                   0, 1 / mapLayer.size[2], 0, -ySize / 2 + 1 / mapLayer.size[2],
      --                   0, 0, 1, 0,
      --                   0, 0, 0, 1)
  }

  settings.mapScreenRect = vec4(win.left + settings.mapPadding[1], win.bottom + settings.mapPadding[2], win.right - settings.mapPadding[3], win.top - settings.mapPadding[4])
end

-- function scr2px(sx, sy)
--   return (sx - win.left) / settings.renderScale, (sy - win.bottom) / settings.renderScale
-- end

function scr2m(screenPos)
  return math.floor((screenPos[1] - settings.mapScreenRect[1]) / (settings.renderScale * settings.tileSize[1])) + 1,
         math.floor((screenPos[2] - settings.mapScreenRect[2]) / (settings.renderScale * settings.tileSize[2])) + 1
end

function m2scr(mapX, mapY)
  return vec2((mapX - 1) * settings.renderScale * settings.tileSize[1] + settings.mapScreenRect[1],
              (mapY - 1) * settings.renderScale * settings.tileSize[2] + settings.mapScreenRect[2])
end

setupWindow()

local game = Game:new()

local gui = Interface:new(game)

win.scene = am.group({
      gui.underlay,
      am.translate(settings.mapScreenRect[1], settings.mapScreenRect[2]):tag("mapTranslate") ^ am.scale(settings.renderScale):tag("mapScale") ^ game.node,
      gui.overlay
    })

win.scene:action(function(scene)
    gui:update()
  end)
