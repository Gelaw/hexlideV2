

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
grid.dim = {i = 10, j = 10}
grid.busy = {}

function grid.init()
  for j = 1, grid.dim.j do
    grid[j] = {}
    for i = 1, grid.dim.i do
      grid[j][i] = {}
    end
  end
end

function grid.getNeighours(i, j)
  local n = {}
  local steps = {}
  steps = {{i=0, j=-1}, {i=0, j=1}, {i=-1, j=0}, {i=1, j=0}, {i=1, j=(i%2*2)-1}, {i=-1, j=(i%2*2)-1}}
  for s, step in pairs(steps) do
    local ni, nj = i + step.i, j + step.j
    if grid[nj][ni] then
      table.insert(n, grid[nj][ni])
    end
  end
  return n
end

function grid.gridToPixel(i, j)
 return {x = i * 1.5 * cellSize, y = (j + (i %2) * .5) * cellSize * math.sqrt(3)}
end

function grid.pixelToGrid(x, y)
  local x = math.floor(x / (cellSize * 1.5)+.5)
  return {i = x, j = math.floor(y / (cellSize * math.sqrt(3)) - (x%2) * .5 +.5)}
end

function grid:draw()
  for j = 1, self.dim.j do
    for i = 1, self.dim.i do
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

last = "match"

function grid:update(dt)
  if #grid.busy > 0 then return end
  grid.match()
end

function grid.match()
  local change = false
  local combo = 0
  local tobepopped = {}
  for j = 1, grid.dim.j do
    for i = 1, grid.dim.i do
      if grid[j][i].type then
        steps = {{{i=0, j=-1}, {i=0, j=1}}, {{i=-1, j=0}, {i=1, j=(i%2*2)-1}}, {{i=-1, j=(i%2*2)-1}, {i=1, j=0}}}
        for s, step in pairs(steps) do
          if grid[j+step[1].j] and grid[j+step[1].j][i+step[1].i] and grid[j+step[1].j][i+step[1].i].type == grid[j][i].type and
          grid[j+step[2].j] and grid[j+step[2].j][i+step[2].i] and grid[j+step[2].j][i+step[2].i].type == grid[j][i].type then
            combo = combo + 1
            change = true
            table.insert(tobepopped, grid[j+step[1].j][i+step[1].i].ball)
            table.insert(tobepopped, grid[j][i].ball)
            table.insert(tobepopped, grid[j+step[2].j][i+step[2].i].ball)
          end
        end
      end
    end
  end
  for b, ball in pairs(tobepopped) do
    ball:pop()
  end
  return change
end

calls = 0

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
  ball.x, ball.y = 0, 0
  ball.type = 0
  ball.color = {.6, 0, .6}
  ball.speed = {x=0, y=0}
  ball.init = function (self, i, j)
    local pos = grid.gridToPixel(i, j)
    self.x, self.y = pos.x, pos.y
    self.type = math.random(#cellTypes)
    self.color = cellTypes[ball.type].color
    self.speed = {x=0, y=0}
    self.falling = true
    self.popped = false
    grid.occupy(self)
  end
  ball.draw = function (self)
    if self == grab then return end
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, cellSize*.75)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", self.x, self.y, cellSize*.75)
    love.graphics.print(self.pops or 0, self.x, self.y)
  end
  ball.update = function (self, dt)
    if self.terminated then return end
    local gridPos = grid.pixelToGrid(self.x, self.y)
    if self.popped then
      self:init(gridPos.i, -gridPos.j)
      gridPos = grid.pixelToGrid(self.x, self.y)
    end
    local matchingPixelPos = grid.gridToPixel(gridPos.i, math.floor(math.max(gridPos.j, 1)))
    if (grid[gridPos.j+1] and grid[gridPos.j+1][gridPos.i] and grid[gridPos.j+1][gridPos.i].ball == nil) or self.y < matchingPixelPos.y then
      if not self.falling then
        grid[gridPos.j][gridPos.i].type = nil
        grid[gridPos.j][gridPos.i].ball = nil
        self.falling = true
        grid.occupy(self)
      end
      self.speed.y = self.speed.y + 120*dt
      self.y = self.y + self.speed.y * dt
    elseif self.falling then
      grid.liberate(self)
      self.speed.y = 0
      self.falling = false
      self.x = matchingPixelPos.x
      self.y = matchingPixelPos.y
      grid[gridPos.j][gridPos.i].type = self.type
      grid[gridPos.j][gridPos.i].ball = self
    end
  end
  ball.pop = function (self)
    if self.popped then return end
    self.popped = true
    self.pops = self.pops and self.pops + 1 or 1
    grid.liberate(self)
    local gridPos = grid.pixelToGrid(self.x, self.y)
    print(gridPos.i, gridPos.j)
    if grid[gridPos.j] and grid[gridPos.j][gridPos.i] then
      grid[gridPos.j][gridPos.i].type = nil
      grid[gridPos.j][gridPos.i].ball = nil
    end
  end
  ball:init(i, j)
  table.insert(entities, ball)
  return ball
end

function grid.switchBallAt(gridPos1, gridPos2)
  ball1 = grid[gridPos1.j][gridPos1.i].ball
  ball2 = grid[gridPos2.j][gridPos2.i].ball

  pixelpos1 = grid.gridToPixel(gridPos1.i, gridPos1.j)
  ball2.x = pixelpos1.x
  ball2.y = pixelpos1.y

  pixelpos2 = grid.gridToPixel(gridPos2.i, gridPos2.j)
  ball1.x = pixelpos2.x
  ball1.y = pixelpos2.y

  grid[gridPos1.j][gridPos1.i].ball = ball2
  grid[gridPos1.j][gridPos1.i].type = ball2.type

  grid[gridPos2.j][gridPos2.i].ball = ball1
  grid[gridPos2.j][gridPos2.i].type = ball1.type
end

function grid.colorRemoval(type)
  local change = false
  local tobepopped = {}
  for j = 1, grid.dim.j do
    for i = 1, grid.dim.i do
      if grid[j][i].type == type then
        table.insert(tobepopped, grid[j][i].ball)
        change = true
      end
    end
  end
  for b, ball in pairs(tobepopped) do
    ball:pop()
  end
  return change
end

function even(n) return n % 2 == 0 end
function odd(n) return n % 2 == 1 end

function grid.distance(a, b)
  local penalty = 0
  if (even(a.i) and  odd(b.i) and a.j < b.j) or (even(b.i) and  odd(a.i) and b.j < a.j) then
    penalty = 1
  end
  local dx = math.abs(a.i - b.i)
  local dy = math.abs(a.j - b.j)
  local result = math.max(dx, dy + math.floor(dx/2) + penalty)
  return result
end
