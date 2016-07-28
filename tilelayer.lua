local util = require "util"

local TileLayer = ...

function TileLayer:new(mapLayer, tileSet)
  local newLayer = {
    map = mapLayer,
    tileSet = tileSet,
    node = am.group()
  }
  setmetatable(newLayer, util.extend(self))

  return newLayer
end

function TileLayer:rebuildNodes()
  self.node:remove_all()
  for x, y, v in self.map:iter() do
    local tag = x.."."..y
    local px, py = self:m2px(x, y)
    local tile = am.translate(px, py):tag(tag)
    tile:append(self.tileSet.tiles[v])
    self.node:append(tile)
  end
end

function TileLayer:get(x, y)
  local res = self.map:get(x, y)
  if res then
    return res
  else
    log("No TileLayer node found for position %s, %s!", x, y)
  end
end

function TileLayer:set(x, y, v)
  local tag = x.."."..y
  local tileNode = self.node(tag)
  if tileNode then
    tileNode:remove_all()
    tileNode:append(self.tileSet.tiles[v])
    self.map:set(x, y, v)
  else
    log("No TileLayer node found for position %s, %s!", x, y)
  end
end

function TileLayer:pixelSize()
  return {self.map.size[1] * self.tileSet.tileSize[1], self.map.size[2] * self.tileSet.tileSize[2]}
end

function TileLayer:m2px(x, y)
  return (x - 1) * self.tileSet.tileSize[1], (y - 1) * self.tileSet.tileSize[2]
end

function TileLayer:px2m(x, y)
  return math.floor(x / self.tileSet.tileSize[1]) + 1, math.floor(y / self.tileSet.tileSize[2]) + 1
end
