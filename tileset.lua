local util = require "util"

local TileSet = ...

function TileSet:new(baseName, tileCount, tileSize)
  local newSet = {
    baseName = baseName,
    tileSize = tileSize,
    tileCount = tileCount,
    tiles = {}
  }
  setmetatable(newSet, util.extend(self))

  return newSet
end

function TileSet:rebuildTiles()
  self.tiles = {}
  for i = 1, self.tileCount do
    table.insert(self.tiles, am.sprite("images/tiles/"..self.baseName..i..".png", nil, "left", "bottom"))
  end
end
