require "base"
require "grid"

function projectSetup()
  camera.x = width/2
  camera.y = height/2

  gameplayModes = {"candycrush", "dokkan"}
  gameplayMode = "candycrush"


  mainMenu = {
    id="MenuScreen",
    x=0, y=0, w = width, h = height,
    children = {},
    hidden = false,
    draw = function () end
  } 
  table.insert(uis, mainMenu)
  gameMenu = {
    id="gameMenu",
    x=0, y=0, w = width, h = height,
    children = {},
    hidden = true,
    draw = function () end
  } 
  table.insert(uis, gameMenu)

  gameModeButton = {
    id="gameModeButton",
    x = 0, y = 0,
    w = 300, h = 100, color = {math.random(), math.random(), math.random()},
    textColor = {math.random(), math.random(), math.random()}, text = "game mode:", value = 1,
    draw = function (self)
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
      love.graphics.setColor(self.textColor)
      local x, y = .5*(self.w - font:getWidth(self.text)), .25* (self.h - font:getHeight())
      love.graphics.print(self.text, math.floor(x), math.floor(y))
      x, y = .5*(self.w - font:getWidth(gameplayModes[self.value])), .75* (self.h - font:getHeight())
      love.graphics.print(gameplayModes[self.value], math.floor(x), math.floor(y))
    end,
    onClick = function (self)
      self.value = self.value%#gameplayModes+1
      gameplayMode = gameplayModes[self.value]
    end
  }
  gameModeButton.x = .5*(width - gameModeButton.w)
  gameModeButton.y = .25*(height - gameModeButton.h)
  table.insert(mainMenu.children, gameModeButton)

  newGameButton = {
    id="ExitButton",
    x = 0, y = 0,
    w = 300, h = 100, color = {math.random(), math.random(), math.random()},
    textColor = {math.random(), math.random(), math.random()}, text = "New Game",
    draw = function (self)
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
      love.graphics.setColor(self.textColor)
      love.graphics.print(self.text, .5*(self.w - font:getWidth(self.text)), .5* (self.h - font:getHeight()))
    end,
    onClick = function (self)
      grid.init()
      grid.x = 50
      entities = {}
      table.insert(entities, grid)
      seed = os.time()
      grid.newGame(seed)
      mainMenu.hidden = true
      gameMenu.hidden = false
 
    end
  }
  newGameButton.x = .5*(width - newGameButton.w)
  newGameButton.y = .5*(height - newGameButton.h)
  table.insert(mainMenu.children, newGameButton)

  audioManagerUI = {
    x = 0, y = 0, w = 100, h= 350,
    backgroundColor = {.2, .2, .2},
    children = {
      {
        x = 10, y = 10, w = 80, h = 20,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.print("Music:")
        end
      },
      --muteMusicButton
      {
        x = 10, y = 40, 
        w = 50, h = 50,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("line", 0, 0, self.w, self.h)
          if audioManager.mute then
            love.graphics.print("mute", 5, 5)
          else
            love.graphics.print("unmute", 5, 5)
          end
        end,
        onClick = function (self)

          audioManager:toggleMute()
          print(self.px, self.py)
        end
      },
      --slider
      {
        x = 10, y = 110,
        w = 80, h = 50,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("line", 0, .5*self.h, self.w, 2)
          love.graphics.rectangle("line", audioManager.musicVolume*self.w - self.x, 0, .1*self.w, self.h)
        end,
        onClick = function (self)
          if self.px and self.py then
            audioManager:changeMusicVolume(self.px/self.w)
          end
        end
      },
      {
        x = 10, y = 180, w = 80, h = 20,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.print("Sound effects:")
        end
      },
      --muteMusicButton
      {
        x = 10, y = 220, 
        w = 50, h = 50,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("line", 0, 0, self.w, self.h)
          if audioManager.muteSE then
            love.graphics.print("mute", 5, 5)
          else
            love.graphics.print("unmute", 5, 5)
          end
        end,
        onClick = function (self)
          audioManager:toggleMuteSE()
          print(self.px, self.py)
        end
      },
      --slider Effects
      {
        x = 10, y = 290,
        w = 80, h = 50,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("line", 0, .5*self.h, self.w, 2)
          love.graphics.rectangle("line", audioManager.SEVolume*self.w - self.x, 0, .1*self.w, self.h)
        end,
        onClick = function (self)
          if self.px and self.py then
            audioManager:changeSEVolume(self.px/self.w)
          end
        end
      }
    },
    draw = function (self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    end
  }
  audioManagerUI.x = width - audioManagerUI.w
  table.insert(mainMenu.children, audioManagerUI)
  table.insert(gameMenu.children, audioManagerUI)
  
end

function love.mousepressed(x, y, button, isTouch)
  local press = UIMousePress(x, y , button)
  if gameMenu.hidden then return end
  if #grid.busy > 0 then return end
  if not press then
    if gameplayMode == "candycrush" then
      local pos = grid.pixelToGrid(x, y)
      if grid[pos.j] and grid[pos.j][pos.i] then
        grab = grid[pos.j][pos.i].ball
        grabTime = os.time()
      end
    end
    if gameplayMode == "dokkan" then
      local pos = grid.pixelToGrid(x, y)
      if grid[pos.j] and grid[pos.j][pos.i] then
        selection = {grid[pos.j][pos.i].ball}
      end
    end
  end
end

function love.mousereleased(x, y, button, isTouch)
  UIMouseRelease(x, y, button)
  if gameMenu.hidden then return end
  if #grid.busy > 0 then return end
  if gameplayMode == "candycrush" and grab then
    local dropPos = grid.pixelToGrid(x, y)
    local grabPos = grid.pixelToGrid(grab.x, grab.y)
    if grid[dropPos.j] and grid[dropPos.j][dropPos.i] then
      if grid.distance(dropPos, grabPos) == 1 then
        grid.switchBallAt(dropPos, grabPos)
        if not grid.match() then
          grid.switchBallAt(dropPos, grabPos)
        end
      end
    end
  end
  if gameplayMode == "dokkan" and selection then
    if #selection >= 3 then
      for b, ball in pairs(selection) do
        ball:pop()
      end
    end
    checked = false 
    selection = nil
  end
  grab = nil
  grabTime = nil
end

function love.keypressed(key, scancode, isrepeat)
  if gameMenu.hidden then return end
  if #grid.busy > 0 then return end
  local num = tonumber(key)
  if num and num <= #cellTypes then
    grid.colorRemoval(num)
  end
  if key == "escape" then
    gameMenu.hidden = true
    mainMenu.hidden = false
    entities = {}
  end
end

function love.mousemoved(x, y, dx, dy)
  if gameMenu.hidden then return end
  if #grid.busy > 0 then return end
  if gameplayMode == "dokkan" and selection and #selection > 0 then
    last = selection[#selection]
    lastGridpos = grid.pixelToGrid(last.x, last.y)
    pos = grid.pixelToGrid(x, y)
    if grid[pos.j] and grid[pos.j][pos.i] then
      ballAtPos = grid[pos.j][pos.i].ball
      for b, ball in pairs(selection) do
        if ball == ballAtPos then
          if b == #selection - 1 then
            table.remove(selection)
          end
          return
        end
      end
      if last.type == ballAtPos.type and grid.distance(lastGridpos, pos) == 1 then
        table.insert(selection, ballAtPos)
      end
    end
  end
end