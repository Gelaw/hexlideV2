

cellSize = 30

hexVertex = {}
for a = 0, 2*math.pi, 2*math.pi/6 do
  table.insert(hexVertex, (cellSize*.9) * math.cos(a))
  table.insert(hexVertex, (cellSize*.9) * math.sin(a))
end

cellTypes = {
  --minimum types
  {name = "red", color = {1, 0, 0}},
  {name = "green", color = {0, 1, 0}},
  {name = "blue", color = {0, 0, 1}},

  --optional types / Commentable lignes
  {name = "yellow", color = {1, 1, 0}}
  ,{name = "purple", color = {1, 0, 1}}
  ,{name = "cyan", color = {0, 1, 1}}
  ,{name = "brown", color = {1, .8,  .8}}
}

grid = {}
grid.dim = {x = 10, y = 10}
grid.busy = {}

function grid.init()
  for j = 1, grid.dim.y do
    grid[j] = {}
    for i = 1, grid.dim.x do
      grid[j][i] = {}
    end
  end
end

function grid.getNeighours(i, j)
  local n = {}
  local steps = {}
  steps = {{x=0, y=-1}, {x=0, y=1}, {x=-1, y=0}, {x=1, y=0}, {x=1, y=(i%2*2)-1}, {x=-1, y=(i%2*2)-1}}
  for s, step in pairs(steps) do
    local nx, ny = i + step.x, j + step.y
    if grid[ny][nx] then
      table.insert(n, grid[ny][nx])
    end
  end
  return n
end

function grid.gridToPixel(i, j)
 return {x = i * 1.5 * cellSize, y = (j + (i %2) * .5) * cellSize * math.sqrt(3)}
end

function grid.pixelToGrid(x, y)
  local x = math.floor(x / (cellSize * 1.5)+.5)
  return {x = x, y = math.floor(y / (cellSize * math.sqrt(3)) - (x%2) * .5 +.5)}
end

function grid:draw()
  for j = 1, self.dim.y do
    for i = 1, self.dim.x do
      local pixelPos = self.gridToPixel(i, j)
      love.graphics.push()
      love.graphics.translate(pixelPos.x, pixelPos.y)
      love.graphics.setColor(0.8, 0.8, 0.8, 0.2)
      love.graphics.polygon("fill", hexVertex)
      love.graphics.setColor(grid[j][i].color or (grid[j][i].type and cellTypes[grid[j][i].type].color or {0, 0, 0}))
      love.graphics.polygon("line", hexVertex)
      love.graphics.pop()
    end
  end
  if grab then
    love.graphics.push()
    love.graphics.translate(love.mouse.getX(), love.mouse.getY())
    love.graphics.setColor(grab.color)
    love.graphics.circle("fill", 0, 0, cellSize*.75)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", 0, 0, cellSize*.75)
    love.graphics.pop()
  end
end

function grid:update(dt)
  if #grid.busy > 0 then return end

    if not grid.match() and not grid.fill() then grid.animate = false end

end

function grid.match()
  if #grid.busy > 0 then return true end
  local change = false
  local combo = 0
  local tobepopped = {}
  for j = 1, grid.dim.y do
    for i = 1, grid.dim.x do
      if grid[j][i].type then
        steps = {{{x=0, y=-1}, {x=0, y=1}}, {{x=-1, y=0}, {x=1, y=(i%2*2)-1}}, {{x=-1, y=(i%2*2)-1}, {x=1, y=0}}}
        for s, step in pairs(steps) do

          if grid[j+step[1].y] and grid[j+step[1].y][i+step[1].x] and grid[j+step[1].y][i+step[1].x].type == grid[j][i].type and
          grid[j+step[2].y] and grid[j+step[2].y][i+step[2].x] and grid[j+step[2].y][i+step[2].x].type == grid[j][i].type then
            combo = combo + 1
            change = true
            table.insert(tobepopped, grid[j+step[1].y][i+step[1].x].ball)
            table.insert(tobepopped, grid[j][i].ball)
            table.insert(tobepopped, grid[j+step[2].y][i+step[2].x].ball)
          end
        end
      end
    end
  end
  if change then grid.fill() end
  for b, ball in pairs(tobepopped) do
    ball:pop()
  end
  return change
end

calls= 0

function grid.occupy(ball)
  calls = calls +1
  table.insert(grid.busy, ball)
end

function grid.liberate(ball)
  for n = #grid.busy, 1, -1 do
    if grid.busy[n]== ball then
      calls = calls -1
      table.remove(grid.busy, n)
    end
  end
end

function spawnBall(i, j)
  local ball = {}
  local pos = grid.gridToPixel(i, j)
  ball.x, ball.y = pos.x, pos.y
  ball.type = math.random(#cellTypes)
  ball.color = cellTypes[ball.type].color
  ball.draw = function (self)
    if self == grab then return end
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, cellSize*.75)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", self.x, self.y, cellSize*.75)
  end
  ball.speed = {x=0, y=0}
  ball.update = function (self, dt)
    if self.terminated then return end
    local gridPos = grid.pixelToGrid(self.x, self.y)
    local matchingPixelPos = grid.gridToPixel(gridPos.x, math.floor(math.max(gridPos.y, 1)))
    if (grid[gridPos.y+1] and grid[gridPos.y+1][gridPos.x] and grid[gridPos.y+1][gridPos.x].ball == nil) or self.y < matchingPixelPos.y then
      if not self.falling then
        grid[gridPos.y][gridPos.x].type = nil
        grid[gridPos.y][gridPos.x].ball = nil
        self.falling = true
        grid.occupy(self)
      end
      self.speed.y = self.speed.y + 30*dt
      self.y = self.y + self.speed.y * dt
    elseif self.falling then
      grid.liberate(self)
      self.speed.y = 0
      self.falling = false
      self.x = matchingPixelPos.x
      self.y = matchingPixelPos.y
      grid[gridPos.y][gridPos.x].type = self.type
      grid[gridPos.y][gridPos.x].ball = self
    end
  end
  ball.pop = function (self)
    grid.liberate(self)
    local gridPos = grid.pixelToGrid(self.x, self.y)
    grid[gridPos.y][gridPos.x].type = nil
    grid[gridPos.y][gridPos.x].ball = nil
    self.terminated = true
  end
  ball.falling = true
  grid.occupy(ball)
  table.insert(entities, ball)
  return ball
end

function grid.fill()
  if #grid.busy > 0 then return end
  local change = false
  for j = 1, grid.dim.y do
    for i = 1, grid.dim.x do
      if grid[j][i].ball == nil then
        local ball = spawnBall(i, -j)
        grid.occupy(ball)
        ball.speed.y = 30
        change = true
      end
    end
  end
  return change
end

function grid.switchBallAt(gridPos1, gridPos2)
  -- if #grid.busy > 0 then return end
  ball1 = grid[gridPos1.y][gridPos1.x].ball
  ball2 = grid[gridPos2.y][gridPos2.x].ball

  pixelpos1 = grid.gridToPixel(gridPos1.x, gridPos1.y)
  ball2.x = pixelpos1.x
  ball2.y = pixelpos1.y

  pixelpos2 = grid.gridToPixel(gridPos2.x, gridPos2.y)
  ball1.x = pixelpos2.x
  ball1.y = pixelpos2.y

  grid[gridPos1.y][gridPos1.x].ball = ball2
  grid[gridPos1.y][gridPos1.x].type = ball2.type

  grid[gridPos2.y][gridPos2.x].ball = ball1
  grid[gridPos2.y][gridPos2.x].type = ball1.type
end


function even(n) return n % 2 == 0 end
function odd(n) return n % 2 == 1 end

function grid.distance(a, b)
  local penalty = 0
  if (even(a.x) and  odd(b.x) and a.y < b.y) or (even(b.x) and  odd(a.x) and b.y < a.y) then
    penalty = 1
  end
  local dx = math.abs(a.x - b.x)
  local dy = math.abs(a.y - b.y)
  local result = math.max(dx, dy + math.floor(dx/2) + penalty)
  return result
end
