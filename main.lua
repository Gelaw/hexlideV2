require "base"
require "grid"

function projectSetup()
  camera.x = width/2
  camera.y = height/2

  -- gameplayMode = "candycrush"
  gameplayMode = "dokkan"
  selection = {}
  
  mainMenu = {
    id="MenuScreen",
    x=0, y=0, w = width, h = height,
    children = {},
    hidden = false,
    draw = function () end
  } 
  table.insert(uis, mainMenu)

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
      seed = 1
      grid.newGame(seed)
      mainMenu.hidden = true
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
  table.insert(mainMenu.children, audioManagerUI)
end

function love.mousepressed(x, y, button, isTouch)
  local press = UIMousePress(x, y , button)
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
  if gameplayMode == "dokkan" then
    if #selection >= 3 then
      for b, ball in pairs(selection) do
        ball:pop()
      end
      selection = {}
    end
  end
  grab = nil
  grabTime = nil
end

function love.keypressed(key, scancode, isrepeat)
  if #grid.busy > 0 then return end
  local num = tonumber(key)
  if num and num <= #cellTypes then
    grid.colorRemoval(num)
  end
end

function love.mousemoved(x, y, dx, dy)
  if #grid.busy > 0 then return end
  if gameplayMode == "dokkan" and #selection > 0 then
    last = selection[#selection]
    lastGridpos = grid.pixelToGrid(last.x, last.y)
    pos = grid.pixelToGrid(x, y)
    if grid[pos.j] and grid[pos.j][pos.i] then
      ballAtPos = grid[pos.j][pos.i].ball
      if last.type == ballAtPos.type and grid.distance(lastGridpos, pos) == 1 then
        table.insert(selection, ballAtPos)
      end
    end
  end
end