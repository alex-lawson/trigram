local MapLayer = require "maplayer"
local TileLayer = require "tilelayer"
local TileSet = require "tileset"

local Game = ...

function Game:new()
  local newGame = {
    node = am.group()
  }

  setmetatable(newGame, { __index = Game })

  newGame:reset()

  return newGame
end

function Game:reset()
  self.gameState = {
    players = {},
    turn = 0,
    spells = {},
    hoverTile = nil
  }

  self:setupMap()

  if self.node("mapTileLayer") then
    self.node:replace("mapTileLayer", self.tileLayer.node:tag("mapTileLayer"))
  else
    self.node:append(self.tileLayer.node:tag("mapTileLayer"))
  end
end

function Game:setupMap()
  self.mapLayer = MapLayer:new(settings.mapSize)
  self.tileSet = TileSet:new("floor", settings.tileCount, settings.tileSize)
  self.tileLayer = TileLayer:new(self.mapLayer, self.tileSet)

  self.tileSet:rebuildTiles()
  self.tileLayer:rebuildNodes()

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

function Game:cycleTile(tx, ty, indexAdjust)
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

function Game:canPlaceRune(tx, ty, slot, rune)
  local spell = self:spellAt(tx, ty)
  if spell then
    return spell:canAddRune(slot, rune)
  else
    return true
  end
end

function Game:placeRune(tx, ty, slot, rune)
  local spell = self:spellAt(tx, ty)
  if spell then
    spell:addRune(slot, rune)
  else
    local newSpell = Spell:new(tx, ty)
    newSpell:addRune(slot, rune)
    table.insert(self.spells, newSpell)
  end
end

function Game:endTurn()

end
