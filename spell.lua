local util = require "util"

local Spell = ...

function Spell.new(x, y)
  local newSpell = {
    x = x,
    y = y,
    bodyRune = nil,
    bodyLevel = 0,
    heartRune = nil,
    heartLevel = 0,
    mindRune = nil,
    mindLevel = 0,
    node = am.translate((x - 0.5) * settings.tileSize[1], (y - 0.5) * settings.tileSize[2])
  }

  setmetatable(newSpell, { __index = Spell })

  return newSpell
end

function Spell:canAddRune(slot, rune)
  return self[slot.."Level"] == 0 or (self[slot.."Level"] < 3 and self[slot.."Rune"] == rune)
end

function Spell:addRune(slot, rune)
  self[slot.."Rune"] = rune
  self[slot.."Level"] = self[slot.."Level"] + 1
  self:updateNode()
end

function Spell:removeRune(slot)
  if not slot then
    if self.bodyLevel > 0 then
      slot = "body"
    elseif self.mindLevel > 0 then
      slot = "mind"
    elseif self.heartLevel > 0 then
      slot = "heart"
    end
  end

  local slotLevel = self[slot.."Level"]
  if slotLevel > 0 then
    slotLevel = slotLevel - 1
    if slotLevel <= 0 then
      self[slot.."Level"] = 0
      self[slot.."Rune"] = nil
    end
  end
end

function Spell:dead()
  return self.bodyLevel <= 0 and self.mindLevel <= 0 and self.heartLevel <= 0
end

function Spell:updateNode()
  self.node:remove_all()

  if self.bodyLevel > 0 then
    self.node:append(am.sprite("images/runes/"..self.bodyRune.."-outer.png"))
  end

  if self.mindLevel > 0 then
    self.node:append(am.sprite("images/runes/"..self.mindRune.."-mid.png"))
  end

  if self.heartLevel > 0 then
    self.node:append(am.sprite("images/runes/"..self.heartRune.."-inner.png"))
  end
end

function Spell:processWithRune(slot, rune)
  if not self:canAddRune(slot, rune) then
    return self:process()
  else
    return util.merge(self, {
        [slot.."Rune"] = rune,
        [slot.."Level"] = self[slot.."Level"] + 1
      }):process()
  end
end

function Spell:process(overrides)
  overrides = overrides or {}
  local spellConfig = util.merge(self, overrides)
  local spellPos = vec2(spellConfig.x, spellConfig.y)

  local res = {
    spaces = {},
    modifyHealth = 0,
    modifySpeed = 0,
    specials = {}
  }

  if spellConfig.bodyLevel > 0 then
    if spellConfig.bodyRune == "circle" then
      local dist = spellConfig.bodyLevel
      for x = -dist, dist do
        for y = -dist, dist do
          table.insert(res.spaces, spellPos + vec2(x, y))
        end
      end
    elseif spellConfig.bodyRune == "cross" then
      local dist = spellConfig.bodyLevel * 2
      for x = -dist, dist do
        table.insert(res.spaces, spellPos + vec2(x, 0))
      end
      for y = -dist, dist do
        if y ~= 0 then
          table.insert(res.spaces, spellPos + vec2(0, y))
        end
      end
    elseif spellConfig.bodyRune == "chaos" then
      local dist = spellConfig.bodyLevel * 2
      for x = -dist, dist do
        for y = -dist, dist do
          if math.abs(x) + math.abs(y) == dist then
            table.insert(res.spaces, spellPos + vec2(x, y))
          end
        end
      end
    end
  end

  local filteredSpaces = {}
  for _, space in pairs(res.spaces) do
    if tilePosValid(space) then
      table.insert(filteredSpaces, space)
    end
  end
  res.spaces = filteredSpaces

  if spellConfig.heartLevel > 0 then
    if spellConfig.heartRune == "circle" then
      res.modifyHealth = -spellConfig.heartLevel
    elseif spellConfig.heartRune == "cross" then
      res.modifyHealth = spellConfig.heartLevel
    elseif spellConfig.heartRune == "chaos" then
      res.modifyHealth = spellConfig.heartLevel * (-1) ^ spellConfig.heartLevel
    end
  end

  if spellConfig.mindLevel > 0 then
    if spellConfig.mindRune == "circle" then
      table.insert(res.specials, "trigger")
    elseif spellConfig.mindRune == "cross" then
      table.insert(res.specials, "nullify")
    elseif spellConfig.mindRune == "chaos" then
      res.modifyHealth = -res.modifyHealth
      res.modifySpeed = -res.modifySpeed
    end
  end

  return res
end
