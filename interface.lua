local Spell = require "spell"
local util = require "util"

local Interface = ...

function Interface.new(game)
  local newInterface = {
    game = game,
    buttons = {},
    hoverTile = vec2(0),
    selectedRune = "circle",
    selectedSlotIndex = 1,
    selectedSlot = "outer",
    selectedSlotName = "body" -- TODO: get rid of this ridiculous disparity in terms
  }

  setmetatable(newInterface, { __index = Interface })

  newInterface.underlay = am.group({
      am.rect(settings.mapScreenRect[1] - 9, settings.mapScreenRect[2] - 9, settings.mapScreenRect[3] + 9, settings.mapScreenRect[4] + 9, vec4(0.5, 0.5, 0.3, 1)),
      am.rect(settings.mapScreenRect[1] - 3, settings.mapScreenRect[2] - 3, settings.mapScreenRect[3] + 3, settings.mapScreenRect[4] + 3, vec4(0, 0, 0, 1)),
      -- am.rect((win.left / settings.renderScale) + 9, settings.mapScreenRect[2] - 9, settings.mapScreenRect[1] - 18, settings.mapScreenRect[4] + 9, vec4(0.5, 0.5, 0.3, 1)),
      -- am.rect((win.left / settings.renderScale) + 15, settings.mapScreenRect[2] - 3, settings.mapScreenRect[1] - 24, settings.mapScreenRect[4] + 3, vec4(0, 0, 0, 1))

    }):tag("guiUnderlay")

  newInterface.overlay = am.group({
      am.translate(0, 0):tag("hoverPosition") ^ am.sprite("images/interface/tileoverlay/selected.png", vec4(1), "left", "bottom"):tag("hoverSprite"),
      am.group():tag("previewSpaces")
    }):tag("guiOverlay")

  for i, rune in pairs({"circle", "cross", "chaos"}) do
    local screenPos = vec2(-settings.windowSize[1] / 2 + 21 + 24 * (i - 1), settings.windowSize[2] / 2 - 17)

    local node = am.translate(screenPos)
    newInterface.overlay:append(node)

    local baseSprite = am.sprite("images/interface/runebuttonbg.png"):tag("runeBaseSprite"):tag(rune.."baseSprite")
    node:append(baseSprite)

    local halfW = baseSprite.width * 0.5
    local halfH = baseSprite.height * 0.5

    local newButton = {
      node = node,
      tag = rune.."Button",
      screenRect = vec4(screenPos[1] - halfW, screenPos[2] - halfH, screenPos[1] + halfW, screenPos[2] + halfH),
      hovered = false
    }

    node:append(am.sprite("images/runes/"..rune.."-outer.png"):tag("runeButtonSprite"):tag(rune.."outer"))
    node:append(am.sprite("images/runes/"..rune.."-mid.png"):tag("runeButtonSprite"):tag(rune.."mid"))
    node:append(am.sprite("images/runes/"..rune.."-inner.png"):tag("runeButtonSprite"):tag(rune.."inner"))

    function newButton:hoverCallback(hovered)
      -- log("hover is %s, self is %s", hovered and "true" or "false", table.tostring(self))
      -- if hovered then
      --   self.node("runeBaseSprite").source = "images/interface/runebuttonbgselected.png"
      -- else
      --   self.node("runeBaseSprite").source = "images/interface/runebuttonbg.png"
      -- end
    end

    function newButton:clickCallback(mouseButton)
      if mouseButton == "left" then
        newInterface:selectRune(rune)
      end
      -- log("clicked %s with mouseButton %s", self.tag, mouseButton)
    end

    -- log("created button with screenrect %s", newButton.screenRect)

    table.insert(newInterface.buttons, newButton)
  end

  newInterface:updateRuneButtons()

  return newInterface
end

local runeSlotNames = {
  outer = "body",
  mid = "mind",
  inner = "heart"
}

function Interface:selectRune(rune)
  if self.selectedRune ~= rune then
    self.selectedRune = rune
    -- log("rune shifted to %s", self.selectedRune)
  else
    local slots = {"outer", "mid", "inner"}
    self.selectedSlotIndex = self.selectedSlotIndex % 3 + 1
    self.selectedSlot = slots[self.selectedSlotIndex]
    self.selectedSlotName = runeSlotNames[self.selectedSlot]
    -- log("rune slot advanced to %s : %s '%s'", self.selectedSlotIndex, self.selectedSlot, self.selectedSlotName)
  end
  self:updateRuneButtons()
  self:updateHoverlays()
end

function Interface:updateRuneButtons()
  local selectedColor = vec4(1, 1, 1, 1)
  local deselectedColor = vec4(0.5, 0.5, 0.5, 1)
  for _, sprite in pairs(self.overlay:all("runeButtonSprite")) do
    sprite.color = deselectedColor
  end
  self.overlay(self.selectedRune..self.selectedSlot).color = selectedColor

  for _, sprite in pairs(self.overlay:all("runeBaseSprite")) do
    sprite.source = "images/interface/runebuttonbg.png"
  end
  self.overlay(self.selectedRune.."baseSprite").source = "images/interface/runebuttonbgselected.png"
end

function Interface:updateHoverlays(tx, ty)
  if tx then
    self.hoverTile = vec2(tx, ty)
    self.overlay("hoverPosition").position2d = m2scr(tx, ty)
    self.overlay("hoverSprite").hidden = false
    self.overlay("previewSpaces"):remove_all()
    win.scene("mapTranslate"):remove("previewSpell")

    local spell = self.game:spellAt(tx, ty)
    local previewSpell
    if not spell or spell:canAddRune(self.selectedSlotName, self.selectedRune) then
      previewSpell = Spell.new(tx, ty)
      previewSpell:addRune(self.selectedSlotName, self.selectedRune)
    else
      -- no change to preview
    end

    if previewSpell then
      win.scene("mapTranslate"):append(previewSpell:buildNode():tag("previewSpell"))
    end

    local spellSpaces = ary2d()

    local spellResult
    if spell then
      spellResult = spell:process()
      for _, space in pairs(spellResult.spaces) do
        spellSpaces[space[1]][space[2]] = "old"
      end
    end

    local previewSpellResult
    if previewSpell then
      if not spell then
        previewSpellResult = previewSpell:process()
      else
        previewSpellResult = spell:processWithRune(self.selectedSlotName, self.selectedRune)
      end
    end

    if previewSpellResult then
      for _, space in pairs(previewSpellResult.spaces) do
        local tex = spellSpaces[space[1]][space[2]] == "old" and "images/interface/tileoverlay/aoe.png" or "images/interface/tileoverlay/aoepreview.png"
        self.overlay("previewSpaces"):append(am.translate(m2scr(space[1], space[2])):tag("previewSpace") ^ am.sprite(tex, vec4(1), "left", "bottom"))
        self.overlay("hoverSprite").hidden = true
      end
    elseif spellResult then
      for _, space in pairs(spellResult.spaces) do
        self.overlay("previewSpaces"):append(am.translate(m2scr(space[1], space[2])):tag("previewSpace") ^ am.sprite("images/interface/tileoverlay/aoe.png", vec4(1), "left", "bottom"))
        self.overlay("hoverSprite").hidden = true
      end
    end
  else
    self.hoverTile = vec2(0)
    self.overlay("hoverSprite").hidden = true
    self.overlay("previewSpaces"):remove_all()
    win.scene("mapTranslate"):remove("previewSpell")
  end
end

function Interface:update()
  if win:key_pressed("escape") then
    win:close()
    return
  end

  local saveName
  if win:key_pressed("f1") then
    saveName = "quick1"
  elseif win:key_pressed("f2") then
    saveName = "quick2"
  elseif win:key_pressed("f3") then
    saveName = "quick3"
  elseif win:key_pressed("f4") then
    saveName = "quick4"
  end

  if saveName then
    if win:key_down("lshift") then
      self.game:save(saveName)
    else
      self.game:load(saveName)
    end
  end

  if win:key_pressed("space") then
    if win:key_down("lshift") then
      self.game:startNewGame()
    else
      self.game:endEntityTurn()
    end
  end

  if win:key_pressed("1") then
    self:selectRune("circle")
  elseif win:key_pressed("2") then
    self:selectRune("cross")
  elseif win:key_pressed("3") then
    self:selectRune("chaos")
  end

  local mPos = win:mouse_position()
  if util.rectContains(settings.mapScreenRect, mPos) then
    local tx, ty = scr2m(mPos)
    local canPlace = self.game:canPlaceRune(tx, ty, self.selectedSlotName, self.selectedRune)
    if win:key_down("lshift") then
      if win:mouse_pressed("left") then
        self.game:cycleTile(tx, ty, 1)
      elseif win:mouse_pressed("right") then
        self.game:cycleTile(tx, ty, -1)
      end
    else
      if win:mouse_pressed("left") then
        if self.game:canPlaceRune(tx, ty, self.selectedSlotName, self.selectedRune) then
          self.game:placeRune(tx, ty, self.selectedSlotName, self.selectedRune)
          self:updateHoverlays()
        end
      elseif win:mouse_pressed("right") then
        self:selectRune(self.selectedRune)
      end
    end

    local hoverAlpha = 0.7 + 0.2 * math.sin(os.clock() * 6)
    self.overlay("hoverSprite").color = canPlace and vec4(0.2, 1, 0.7, hoverAlpha) or vec4(1, 0.6, 0.4, hoverAlpha)

    if self.hoverTile[1] ~= tx or self.hoverTile[2] ~= ty then
      self:updateHoverlays(tx, ty)
    end

  elseif self.hoverTile[1] ~= 0 or self.hoverTile[2] ~= 0 then
    self:updateHoverlays(false)
  end

  for _, button in pairs(self.buttons) do
    if util.rectContains(button.screenRect, mPos) then
      if not button.hovered then
        button.hovered = true
        if button.hoverCallback then
          button:hoverCallback(true)
        end
      end

      if button.clickCallback then
        if win:mouse_pressed("left") then
          button:clickCallback("left")
        elseif win:mouse_pressed("right") then
          button:clickCallback("right")
        end
      end
    elseif button.hovered then
      button.hovered = false
      if button.hoverCallback then
        button:hoverCallback(false)
      end
    end
  end
end
