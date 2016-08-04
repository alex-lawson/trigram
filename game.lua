local MapLayer = require "maplayer"
local TileLayer = require "tilelayer"
local TileSet = require "tileset"
local Spell = require "spell"

local Game = ...

function Game.new()
  local newGame = {
    node = am.group()
  }

  setmetatable(newGame, { __index = Game })

  newGame:startNewGame()

  return newGame
end

function Game:startNewGame()
  self:reset()
  self:addPlayer("player1")
  self:addPlayer("player2")
  self:endGameTurn()
end

function Game:reset()
  self.gameState = {
    lastEntityId = 0,
    entities = {},
    turn = 0,
    spells = {},
    initiative = {}
  }

  self:setupMap()

  self:updateNode()
end

function Game:setupMap()
  self.mapLayer = MapLayer:new(settings.mapSize)
  self.tileSet = TileSet:new("floor", settings.tileCount, settings.tileSize)
  self.tileLayer = TileLayer:new(self.mapLayer, self.tileSet)

  self.tileSet:rebuildTiles()
  self.tileLayer:rebuildNodes()

  local function tileFor(tx, ty)
    local hEdge = tx == 1 or tx == settings.mapSize[1] or tx == math.ceil(settings.mapSize[1] / 2)
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

function Game:nextEntityId()
  self.gameState.lastEntityId = self.gameState.lastEntityId + 1
  return self.gameState.lastEntityId
end

function Game:cycleTile(tx, ty, indexAdjust)
  -- log("cycling tile at %s, %s", tx, ty)
  local current = self.tileLayer:get(tx, ty)
  if current then
    self.tileLayer:set(tx, ty, ((current + indexAdjust - 1) % settings.tileCount) + 1)
  end
end

function Game:addPlayer(playerName)
  local eId = self:nextEntityId()
  local newPlayer = {
    eType = "player",
    eId = eId,
    name = playerName
  }
  self.gameState.entities[eId] = newPlayer
  self:updateNode()
end

function Game:activeEntity()
  if #self.gameState.initiative > 0 then
    return self:entity(self.gameState.initiative[1])
  end
end

function Game:entity(eId)
  return self.gameState.entities[eId]
end

function Game:removeEntity(eId)
  self.gameState.entities[eId] = nil
  self:updateNode()
end

function Game:spellAt(tx, ty)
  for _, spell in pairs(self.gameState.spells) do
    if spell.x == tx and spell.y == ty then
      return spell
    end
  end
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
    local newSpell = Spell.new(tx, ty)
    newSpell:addRune(slot, rune)
    table.insert(self.gameState.spells, newSpell)
  end
  self:updateNode()
end

function Game:removeRuneAt(tx, ty, slot)
  local spell = self:spellAt(tx, ty)
  if spell then
    spell:removeRune(slot)
    if spell:dead() then
      self:removeSpell()
    end
  end
end

function Game:removeSpellAt(tx, ty)
  local spell = self:spellAt(tx, ty)
  if spell then
    self:removeSpell(spell)
  end
end

function Game:removeSpell(spell)
  table.remove(self.gameState.spells, spell)
  self:updateNode()
end

function Game:endGameTurn()
  -- log("Ending game turn %s", self.gameState.turn)
  self.gameState.turn = self.gameState.turn + 1
  self.gameState.initiative = {}
  for eId, entity in pairs(self.gameState.entities) do
    table.insert(self.gameState.initiative, eId)
  end
end

function Game:endEntityTurn()
  if #self.gameState.initiative > 0 then
    -- log("Entity %s ended turn %s", self.gameState.initiative[1].name, self.gameState.turn)

    table.remove(self.gameState.initiative, 1)
  end

  if #self.gameState.initiative > 0 then

  else
    self:endGameTurn()
  end
end

function Game:save(saveName)
  local toSave = table.shallow_copy(self.gameState)
  local spellsToSave = {}
  for _, spell in pairs(self.gameState.spells) do
    table.insert(spellsToSave, SaveSpell(spell))
  end
  toSave.spells = spellsToSave
  am.save_state(saveName, toSave)
  log("Saved game as '%s'", saveName)
end

function Game:load(saveName)
  local savedState = am.load_state(saveName)
  if savedState then
    local spells = {}
    for _, spellData in pairs(savedState.spells) do
      table.insert(spells, LoadSpell(spellData))
    end
    savedState.spells = spells
    self.gameState = savedState
    self:updateNode()
    log("Loaded save '%s'", saveName)
  else
    log("Failed to load save '%s'", saveName)
  end
end

function Game:updateNode()
  self.node:remove_all()
  self.node:append(self.tileLayer.node:tag("mapTileLayer"))
  for _, spell in pairs(self.gameState.spells) do
    self.node:append(spell:buildNode())
  end
end
