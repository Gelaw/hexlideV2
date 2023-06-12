require "base"
require "grid"

function projectSetup()
  camera.x = width/2
  camera.y = height/2


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
      table.insert(entities, grid)
      seed = 1
      grid.newGame(seed)
      mainMenu.hidden = true
    end
  }
  newGameButton.x = .5*(width - newGameButton.w)
  newGameButton.y = .5*(height - newGameButton.h)
  table.insert(mainMenu.children, newGameButton)
end

function love.mousepressed(x, y, button, isTouch)
  local press = UIMousePress(x, y , button)
  if not press then
    local pos = grid.pixelToGrid(x, y)
    if grid[pos.j] and grid[pos.j][pos.i] then
      grab = grid[pos.j][pos.i].ball
      grabTime = os.time()
    else
      grab = nil
    end
  end
end

function love.mousereleased(x, y, button, isTouch)
  UIMouseRelease(x, y, button)
  if #grid.busy == 0 and  grab then
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
