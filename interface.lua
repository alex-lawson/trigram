local util = require "util"

local Interface = ...

function Interface:new(game)
  local newInterface = {
    game = game,
    buttons = {},
    hoverTile = vec2(0)
  }

  setmetatable(newInterface, { __index = Interface })

  newInterface.underlay = am.group({
      am.rect(settings.mapScreenRect[1] - 9, settings.mapScreenRect[2] - 9, settings.mapScreenRect[3] + 9, settings.mapScreenRect[4] + 9, vec4(0.5, 0.5, 0.3, 1)),
      am.rect(settings.mapScreenRect[1] - 3, settings.mapScreenRect[2] - 3, settings.mapScreenRect[3] + 3, settings.mapScreenRect[4] + 3, vec4(0, 0, 0, 1))

    }):tag("guiUnderlay")

  newInterface.overlay = am.group({
      am.translate(0, 0):tag("hoverPosition") ^ am.sprite("images/tiles/selected.png", vec4(1), "left", "bottom"):tag("hoverSprite"),
      am.group():tag("previewSpaces")
    }):tag("guiOverlay")

  for i = 1, 3 do
    newInterface:addButton("images/runes/"..i..".png", vec2(-settings.windowSize[1] / 2 + 20 * i, settings.windowSize[2] / 2 - 10), "rune"..i,
      function(self, hovered)
        -- log("hover is %s, self is %s", hovered and "true" or "false", table.tostring(self))
        if hovered then
          self.node(self.tag).color = vec4(1, 1, 1, 1)
        else
          self.node(self.tag).color = vec4(0.75, 0.75, 0.75, 1)
        end
      end,
      function(self, button)
        log("clicked %s with button %s", self.tag, button)
      end)
  end

  return newInterface
end

function Interface:addButton(image, screenPos, tag, hoverCallback, clickCallback)
  local sprite = am.sprite(image)
  local node = am.translate(screenPos[1], screenPos[2]) ^ sprite:tag(tag)
  self.overlay:append(node)
  local halfW = sprite.width * 0.5
  local halfH = sprite.height * 0.5

  local newButton = {
    node = node,
    tag = tag,
    screenRect = vec4(screenPos[1] - halfW, screenPos[2] - halfH, screenPos[1] + halfW, screenPos[2] + halfH),
    hoverCallback = hoverCallback,
    clickCallback = clickCallback
  }

  -- log("created button with screenrect %s", newButton.screenRect)

  table.insert(self.buttons, newButton)
end

function Interface:update()
  if win:key_pressed("space") then
    if win:key_down("lshift") then
      self.game:reset()
      self.game:addPlayer("player1")
    else
      self.game:endTurn()
    end
  end

  local mPos = win:mouse_position()
  if util.rectContains(settings.mapScreenRect, mPos) then
    local tx, ty = scr2m(mPos)
    if win:key_down("lshift") then
      if win:mouse_pressed("left") then
        self.game:cycleTile(tx, ty, 1)
      elseif win:mouse_pressed("right") then
        self.game:cycleTile(tx, ty, -1)
      end
    else
      if win:mouse_pressed("left") then

      elseif win:mouse_pressed("right") then

      end
    end

    local newHover = vec2(tx, ty)
    if self.hoverTile[1] ~= newHover[1] or self.hoverTile[2] ~= newHover[2] then
      self.hoverTile = newHover
      self.overlay("hoverPosition").position2d = m2scr(tx, ty)
      self.overlay("hoverSprite").hidden = false
      self.overlay("previewSpaces"):remove_all()

      local spell = self.game:spellAt(tx, ty)
      if spell then
        local spellResult = spell:process()
        for _, space in pairs(spellResult.spaces) do
          self.overlay("previewSpaces"):append(am.translate(m2scr(space[1], space[2])):tag("previewSpace") ^ am.sprite("images/tiles/selected.png", vec4(1), "left", "bottom"))
        end
      end
    end
  elseif self.hoverTile[1] ~= 0 or self.hoverTile[2] ~= 0 then
    self.hoverTile = vec2(0)
    self.overlay("hoverSprite").hidden = true
    self.overlay("previewSpaces"):remove_all()
  end

  for _, button in pairs(self.buttons) do
    if util.rectContains(button.screenRect, mPos) then
      if button.hoverCallback then
        button:hoverCallback(true)
      end

      if button.clickCallback then
        if win:mouse_pressed("left") then
          button:clickCallback("left")
        elseif win:mouse_pressed("right") then
          button:clickCallback("right")
        end
      end
    elseif button.hoverCallback then
      button:hoverCallback(false)
    end
  end
end
