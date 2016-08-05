settings = {
  mapSize = vec2(25, 15),
  tileSize = vec2(16, 16),
  tileCount = 3,
  renderScale = 3.0,
  mapPadding = vec4(100, 16, 16, 45),
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

function tilePosValid(tx, ty)
  if ty then
    return tx >= 1 and ty >= 1 and tx <= settings.mapSize[1] and ty <= settings.mapSize[2]
  else
    return tx[1] >= 1 and tx[2] >= 1 and tx[1] <= settings.mapSize[1] and tx[2] <= settings.mapSize[2]
  end
end

setupWindow()

local game = Game.new()

-- game:load("autosave")

local gui = Interface.new(game)

win.scene = am.group({
      gui.underlay,
      am.translate(settings.mapScreenRect[1], settings.mapScreenRect[2]):tag("mapTranslate") ^ game.node,
      gui.overlay,
      am.translate(settings.windowSize[1] / 2 - 1, settings.windowSize[2] / 2 - 1) ^ am.scale(1 / settings.renderScale) ^ am.text("mouse position", vec4(1), "right", "top"):tag("debugText")
    })

function updateDebugText()
  local mousePos = win:mouse_position()
  local text = string.format("mousePos %.1f, %.1f\n", mousePos[1], mousePos[2])
  if util.rectContains(settings.mapScreenRect, mousePos) then
    text = string.format("tilePos %d, %d ", scr2m(mousePos)) .. text
  end
  if #game.gameState.initiative > 0 then
    local entity = game:activeEntity()
    if entity then
      text = text .. string.format("%s %d '%s'  hp: %d / %d  mp: %d / %d", entity.eType, entity.eId, entity.name, entity.hp, entity.hpMax, entity.mp, entity.mpMax)
    else
      text = text .. "<no entity turn active>"
    end
  end
  text = text .. string.format("\nturn %d", game.gameState.turn)
  win.scene("debugText").text = text
end

win.scene:action(function(scene)
    gui:update()
    updateDebugText()
  end)
