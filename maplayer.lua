local util = require "util"

local MapLayer = ...

function MapLayer:new(size)
  local newLayer = {
    size = size
  }
  setmetatable(newLayer, util.extend(self))
  newLayer.tiles = {}
  newLayer:fill(1)

  return newLayer
end

function MapLayer:fill(v)
  for i = 1, self.size[1] * self.size[2] do
    self.tiles[i] = v
  end
end

function MapLayer:get(x, y)
  return self.tiles[self:xy2i(x, y)]
end

function MapLayer:set(x, y, v)
  self.tiles[self:xy2i(x, y)] = v
end

function MapLayer:xy2i(x, y)
  return self.size[1] * (y - 1) + x
end

function MapLayer:i2xy(i)
  return ((i - 1) % self.size[1]) + 1, math.floor((i - 1) / self.size[1]) + 1
end

function MapLayer:iter()
  local i = 0
  return function()
      i = i + 1
      if i <= self.size[1] * self.size[2] then
        local x, y = self:i2xy(i)
        return x, y, self.tiles[i]
      end
    end
end
