require "base"
require "grid"

function projectSetup()
  grid.init()
  camera.x = width/2
  camera.y = height/2
  addDrawFunction(function ()
    grid:draw()
  end, 4)

  addUpdateFunction(
    function (dt)
      grid:update(dt)
    end
  )
  for j = 1, grid.dim.y do
    for i = 1, grid.dim.x do
      spawnBall(i, j)
    end
  end

  addDrawFunction(function ()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(#grid.busy, 0, 0)
    love.graphics.print(calls, 0, 10)
    for n, b in pairs(grid.busy) do
      love.graphics.setColor(1, 1, 1, .5)
      love.graphics.circle("fill", b.x, b.y, 30)
    end
  end)
end


function love.mousepressed(x, y, button, isTouch)
  local pos = grid.pixelToGrid(x, y)
  if grid[pos.y] and grid[pos.y][pos.x] then
    grab = grid[pos.y][pos.x].ball
    grabTime = os.time()
  else
    grab = nil
  end
end

lastSwitch = nil

function love.mousereleased(x, y, button, isTouch)
  if #grid.busy == 0 and  grab then
    local dropPos = grid.pixelToGrid(x, y)
    local grabPos = grid.pixelToGrid(grab.x, grab.y)
    if grid[dropPos.y] and grid[dropPos.y][dropPos.x] then
      if grid.distance(dropPos, grabPos) == 1 then
        grid.switchBallAt(dropPos, grabPos)
        if not grid.match() then
          grid.switchBallAt(dropPos, grabPos)
        else
          grid.animate = true
        end
      end
    end
  end
  grab = nil
  grabTime = nil
end

function love.keypressed(key, scancode, isrepeat)
  if key == "m" then
    grid.match()
    print("match")
  end

  if key == "f" then
    grid.fill()
    print("fill")
  end
end
