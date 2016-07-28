local MapLayer = require "maplayer"
local TileLayer = require "tilelayer"
local TileSet = require "tileset"
local util = require "util"

local settings = {
  mapSize = {15, 11},
  tileSize = {16, 16},
  tileCount = 3,
  renderScale = 3.0,
  mapPaddingX = {150, 50},
  mapPaddingY = {50, 50},
  mapOffset = vec2(0, 0)
}

function setupWindow()
  settings.mapOffset = vec2(settings.mapPaddingX[1], settings.mapPaddingY[1])

  local xSize = settings.mapSize[1] * settings.tileSize[1] * settings.renderScale + settings.mapPaddingX[1] + settings.mapPaddingX[2]
  local ySize = settings.mapSize[2] * settings.tileSize[2] * settings.renderScale + settings.mapPaddingY[1] + settings.mapPaddingY[2]

  win = am.window{
      title = "Trigrams",
      width = xSize,
      height = ySize,
      resizable = false,
      -- projection = mat4(1)
      -- projection = mat4(1 / mapLayer.size[1], 0, 0, -xSize / 2 + 1 / mapLayer.size[1],
      --                   0, 1 / mapLayer.size[2], 0, -ySize / 2 + 1 / mapLayer.size[2],
      --                   0, 0, 1, 0,
      --                   0, 0, 0, 1)
  }

  win.scene = am.translate(win.left, win.bottom)
end

function scr2px(sx, sy)
  return (sx - win.left) / settings.renderScale, (sy - win.bottom) / settings.renderScale
end

function scr2m(screenPos)
  local adjustedScreenPos = -vec2(win.left, win.bottom) + vec2(screenPos) - settings.mapOffset
  return math.floor(adjustedScreenPos[1] / (settings.renderScale * settings.tileSize[1])) + 1,
         math.floor(adjustedScreenPos[2] / (settings.renderScale * settings.tileSize[2])) + 1
end

Game = {}

function Game:newGame()
  self.gameState = {
    players = {},
    turn = {},
    spells = {}
  }

  self:setupMap()

  self:addPlayer("player1")
end

function Game:setupMap()
  self.mapLayer = MapLayer:new(settings.mapSize)
  self.tileSet = TileSet:new("floor", settings.tileCount, settings.tileSize)
  self.tileLayer = TileLayer:new(self.mapLayer, self.tileSet)

  self.tileSet:rebuildTiles()
  self.tileLayer:rebuildNodes()

  win.scene:remove("mapTileLayer")
  win.scene:append(am.translate(settings.mapOffset[1], settings.mapOffset[2]) ^ am.scale(settings.renderScale) ^ self.tileLayer.node:tag("mapTileLayer"))

  local function tileFor(tx, ty)
    local hEdge = tx == 1 or tx == settings.mapSize[1]
    local vEdge = ty == 1 or ty == settings.mapSize[2]
    if hEdge and vEdge then
      return 3
    elseif hEdge or vEdge then
      return 1
    else
      return 2
    end
  end

  for tx = 1, settings.mapSize[1] do
    for ty = 1, settings.mapSize[2] do
      self.tileLayer:set(tx, ty, tileFor(tx, ty))
    end
  end
end

function Game:cycleTile(screenPos, indexAdjust)
  local tx, ty = scr2m(screenPos)
  -- log("cycling tile at %s, %s", tx, ty)
  local current = self.tileLayer:get(tx, ty)
  if current then
    self.tileLayer:set(tx, ty, ((current + indexAdjust - 1) % settings.tileCount) + 1)
  end
end

function Game:addPlayer(playerName)
  local player = {
    name = playerName
  }
  table.insert(self.gameState.players, player)
end

function Game:placeGram(pos, gramSlot, gram)

end

function Game:endTurn()

end

setupWindow()
Game:newGame()

win.scene:action(function(scene)
    if win:key_pressed("space") then
      Game:newGame()
    end

    if win:key_down("lshift") then
      if win:mouse_pressed("left") then
        Game:cycleTile(win:mouse_position(), 1)
      elseif win:mouse_pressed("right") then
        Game:cycleTile(win:mouse_position(), -1)
      end
    end
  end)
