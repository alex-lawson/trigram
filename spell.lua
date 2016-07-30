local util = require "util"

local Spell = ...

function Spell.color(rune)
  if rune == "flame" then
    return vec4(0.9, 0.6, 0.2, 1.0)
  elseif rune == "cross" then
    return vec4(0.2, 0.9, 0.6, 1.0)
  elseif rune == "mask" then
    return vec4(0.8, 0.2, 0.7, 1.0)
  else
    return vec4(1)
  end
end

function Spell:new(x, y)
  local newSpell = {
    x = x,
    y = y,
    bodyRune = nil,
    bodyLevel = 0,
    heartRune = nil,
    heartLevel = 0,
    mindRune = nil,
    mindLevel = 0,
    node = am.translate(x * settings.tileSize[1], y * settings.tileSize[2])
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
  self:updateNode()
end

function Spell:updateNode()
  self.node:remove_all()

  local emptyColor = vec4(0.1, 0.1, 0.1, 1.0)

  local bodyColor = self.bodyLevel > 0 and Spell.color(self.bodyRune) or emptyColor
  self.node:append(am.line(vec2(settings.tileSize[1] * 0.2, settings.tileSize[2] * 0.25), vec2(settings.tileSize[1] * 0.8, settings.tileSize[2] * 0.25), 2, bodyColor))

  local heartColor = self.heartLevel > 0 and Spell.color(self.heartRune) or emptyColor
  self.node:append(am.line(vec2(settings.tileSize[1] * 0.2, settings.tileSize[2] * 0.50), vec2(settings.tileSize[1] * 0.8, settings.tileSize[2] * 0.50), 2, heartColor))

  local mindColor = self.mindLevel > 0 and Spell.color(self.mindRune) or emptyColor
  self.node:append(am.line(vec2(settings.tileSize[1] * 0.2, settings.tileSize[2] * 0.75), vec2(settings.tileSize[1] * 0.8, settings.tileSize[2] * 0.75), 2, mindColor))
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

function Spell:process(overrides)
  local spellConfig = util.merge(self, overrides)

  local res = {
    spaces = {},
    modifyHealth = 0,
    modifySpeed = 0,
    specials = {}
  }

  if spellConfig.bodyLevel > 0 then
    if spellConfig.bodyRune == "flame" then
      local dist = spellConfig.bodyLevel
      for x = -dist, dist do
        for y = -dist, dist do
          table.insert(res.spaces, spellConfig.pos + vec2(x, y))
        end
      end
    elseif spellConfig.bodyRune == "cross" then
      local dist = spellConfig.bodyLevel * 2
      for x = -dist, dist do
        table.insert(res.spaces, spellConfig.pos + vec2(x, 0))
      end
      for y = -dist, dist do
        if y ~= 0 then
          table.insert(res.spaces, spellConfig.pos + vec2(0, y))
        end
      end
    elseif spellConfig.bodyRune == "mask" then
      local dist = spellConfig.bodyLevel * 2
      for x = -dist, dist do
        for y = -dist, dist do
          if abs(x) + abs(y) == dist then
            table.insert(res.spaces, spellConfig.pos + vec2(x, y))
          end
        end
      end
    end
  end

  if spellConfig.heartLevel > 0 then
    if spellConfig.heartRune == "flame" then
      res.modifyHealth = -spellConfig.heartLevel
    elseif spellConfig.heartRune == "cross" then
      res.modifyHealth = spellConfig.heartLevel
    elseif spellConfig.heartRune == "mask" then
      res.modifyHealth = spellConfig.heartLevel * (-1) ^ level
    end
  end

  if spellConfig.mindLevel > 0 then
    if spellConfig.mindRune == "flame" then
      table.insert(res.specials, "trigger")
    elseif spellConfig.mindRune == "cross" then
      table.insert(res.specials, "nullify")
    elseif spellConfig.mindRune == "mask" then
      res.modifyHealth = -res.modifyHealth
      res.modifySpeed = -res.modifySpeed
    end
  end

  return res
end
