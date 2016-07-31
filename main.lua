settings = {
  mapSize = vec2(15, 11),
  tileSize = vec2(16, 16),
  tileCount = 3,
  renderScale = 3.0,
  mapPadding = vec4(100, 16, 16, 16),
  -- computed fields --
  windowSize = vec2(0),
  mapScreenSize = vec2(0),
  mapScreenRect = vec4(0)
}

local util = require "util"
local Game = require "game"
local Interface = require "interface"

function setupWindow()
  settings.mapScreenSize = vec2(settings.mapSize[1] * settings.tileSize[1], settings.mapSize[2] * settings.tileSize[2])

  settings.windowSize = vec2(settings.mapPadding[1] + settings.mapScreenSize[1] + settings.mapPadding[3],
                          settings.mapPadding[2] + settings.mapScreenSize[2] + settings.mapPadding[4])

  local windowAspect = settings.windowSize[1] / settings.windowSize[2]

  win = am.window{
      title = "Trigrams",
      width = settings.windowSize[1] * settings.renderScale,
      height = settings.windowSize[2] * settings.renderScale,
      resizable = false,
      projection = mat4(2 / settings.windowSize[1], 0, 0, 0,
                        0, 2 / settings.windowSize[2], 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1)
  }

  settings.mapScreenRect = vec4(-settings.windowSize[1] / 2 + settings.mapPadding[1],
                                -settings.windowSize[2] / 2 + settings.mapPadding[2],
                                settings.windowSize[1] / 2 - settings.mapPadding[3],
                                settings.windowSize[2] / 2 - settings.mapPadding[4])

  -- log("mapScreenSize is %s, mapScreenRect is %s", settings.mapScreenSize, settings.mapScreenRect)
end

-- function scr2px(sx, sy)
--   return (sx - win.left) / settings.renderScale, (sy - win.bottom) / settings.renderScale
-- end

function scr2m(screenPos)
  return math.floor((screenPos[1] - settings.mapScreenRect[1]) / settings.tileSize[1]) + 1,
         math.floor((screenPos[2] - settings.mapScreenRect[2]) / settings.tileSize[2]) + 1
end

function m2scr(mapX, mapY)
  return vec2((mapX - 1) * settings.tileSize[1] + settings.mapScreenRect[1],
              (mapY - 1) * settings.tileSize[2] + settings.mapScreenRect[2])
end

setupWindow()

local game = Game.new()

local gui = Interface.new(game)

win.scene = am.group({
      gui.underlay,
      am.translate(settings.mapScreenRect[1], settings.mapScreenRect[2]):tag("mapTranslate") ^ game.node,
      gui.overlay,
      am.translate(settings.windowSize[1] / 2 - 1, settings.windowSize[2] / 2 - 1) ^ am.scale(1 / settings.renderScale) ^ am.text("mouse position", vec4(1), "right", "top"):tag("mouseText")
    })

win.scene:action(function(scene)
    gui:update()
    win.scene("mouseText").text = string.format("%.1f, %.1f", win:mouse_position()[1], win:mouse_position()[2])
  end)
