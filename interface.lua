local util = require "util"

local Interface = ...

function Interface:new(game)
  local newInterface = {
    game = game,
    buttons = {}
  }

  setmetatable(newInterface, { __index = Interface })

  newInterface.underlay = am.group({
      am.rect(settings.mapScreenRect[1] - 9, settings.mapScreenRect[2] - 9, settings.mapScreenRect[3] + 9, settings.mapScreenRect[4] + 9, vec4(0.5, 0.5, 0.3, 1)),
      am.rect(settings.mapScreenRect[1] - 3, settings.mapScreenRect[2] - 3, settings.mapScreenRect[3] + 3, settings.mapScreenRect[4] + 3, vec4(0, 0, 0, 1))

    }):tag("guiUnderlay")

  newInterface.overlay = am.group({
      am.translate(0, 0):tag("hoverPosition") ^ am.scale(settings.renderScale) ^ am.sprite("images/tiles/selected.png", vec4(0), "left", "bottom"):tag("hoverSprite")
    }):tag("guiOverlay")

  for i = 1, 3 do
    newInterface:addButton("images/runes/"..i..".png", vec2(win.left + (96 * i) - 48, win.top - 48), "rune"..i,
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
  local node = am.translate(screenPos[1], screenPos[2]) ^ am.scale(settings.guiScale) ^ sprite:tag(tag)
  self.overlay:append(node)
  local halfW = sprite.width * settings.guiScale * 0.5
  local halfH = sprite.height * settings.guiScale * 0.5

  local newButton = {
    node = node,
    tag = tag,
    screenRect = vec4(screenPos[1] - halfW, screenPos[2] - halfH, screenPos[1] + halfW, screenPos[2] + halfH),
    hoverCallback = hoverCallback,
    clickCallback = clickCallback
  }

  log("created button with screenrect %s", newButton.screenRect)

  table.insert(self.buttons, newButton)
end

function Interface:update()
  if win:key_pressed("space") then
    if win:key_down("lshift") then
      game:reset()
      game:addPlayer("player1")
    else
      game:endTurn()
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
    self.overlay("hoverPosition").position2d = m2scr(tx, ty)
    self.overlay("hoverSprite").hidden = true
  else
    self.overlay("hoverSprite").hidden = false
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
