local util = require "util"

local Spell = ...

function Spell:new(x, y)
  local newSpell = {
    x = x,
    y = y,
    bodyRune = nil,
    bodyLevel = 0,
    heartRune = nil,
    heartLevel = 0,
    mindRune = nil,
    mindLevel = 0
  }

  setmetatable(newSpell, { __index = Spell })

  return newSpell
end

function Spell:canAddRune(slot, rune)
  return self[slot.."Level"] == 0 or (self[slot.."Level"] < 3 and self[slot.."Type"] == rune)
end

function Spell:addRune(slot, rune)
  self[slot.."Rune"] = rune
  self[slot.."Level"] = self[slot.."Level"] + 1
end

function Spell:processWithRune(slot, rune)
  if not self:canAddRune(slot, rune) then
    return spell:process()
  else
    return util.merge(self, {
        [slot.."Rune"] = rune,
        [slot.."Level"] = self[slot.."Level"] + 1
      }):process()
  end
end

function spell:process(overrides)
  local spellConfig = util.merge(

  local res = {
    spaces = {},
    modifyHealth = 0,
    modifySpeed = 0,
    specials = {}
  }

  if self.bodyLevel > 0 then
    if self.bodyRune == "flame" then
      local dist = self.bodyLevel
      for x = -dist, dist do
        for y = -dist, dist do
          table.insert(res.spaces, self.pos + vec2(x, y))
        end
      end
    elseif self.bodyRune == "cross" then
      local dist = self.bodyLevel * 2
      for x = -dist, dist do
        table.insert(res.spaces, self.pos + vec2(x, 0))
      end
      for y = -dist, dist do
        if y ~= 0 then
          table.insert(res.spaces, self.pos + vec2(0, y))
        end
      end
    elseif self.bodyRune == "mask" then
      local dist = self.bodyLevel * 2
      for x = -dist, dist do
        for y = -dist, dist do
          if abs(x) + abs(y) == dist then
            table.insert(res.spaces, self.pos + vec2(x, y))
          end
        end
      end
    end
  end

  if self.heartLevel > 0 then
    if self.heartRune == "flame" then
      res.modifyHealth = -self.heartLevel
    elseif self.heartRune == "cross" then
      res.modifyHealth = self.heartLevel
    elseif self.heartRune == "mask" then
      res.modifyHealth = self.heartLevel * (-1) ^ level
    end
  end

  if self.mindLevel > 0 then
    if self.mindRune == "flame" then
      table.insert(res.specials, "trigger")
    elseif self.mindRune == "cross" then
      table.insert(res.specials, "nullify")
    elseif self.mindRune == "mask" then
      res.modifyHealth = -res.modifyHealth
      res.modifySpeed = -res.modifySpeed
    end
  end

  return res
end
