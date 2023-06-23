

cellSize = 30

hexVertex = {}
for a = 0, 2*math.pi, 2*math.pi/6 do
  table.insert(hexVertex, (cellSize*.9) * math.cos(a))
  table.insert(hexVertex, (cellSize*.9) * math.sin(a))
end

cellTypes = {
  --minimum types
  {name = "red", color = {.8, 0, 0}},
  {name = "green", color = {0, .8, 0}},
  {name = "blue", color = {0, 0, .8}},

  --optional types / Commentable lignes
  {name = "yellow", color = {.8, .8, 0}}
  ,{name = "purple", color = {.8, 0, .8}}
  ,{name = "cyan", color = {0, .8, .8}}
  ,{name = "brown", color = {.8, .6,  .6}}
  -- ,{name = "random", color = {math.random(), math.random(),  math.random(), math.random()+.3}}
  -- ,{name = "random", color = {math.random(), math.random(),  math.random(), math.random()+.3}}
  -- ,{name = "random", color = {math.random(), math.random(),  math.random(), math.random()+.3}}
}

grid = {x = 0, y = 0, w=0, h=0, busy = {}}

function grid.init()
  grid.dim = {i = 10, j = 10}
  grid.busy = {}
  grid.fallHeight = {}
  for i = 1, grid.dim.i do
    grid.fallHeight[i] = 1
  end
  for j = 1, grid.dim.j do
    grid[j] = {}
    for i = 1, grid.dim.i do
      grid[j][i] = {}
    end
  end
end

function grid.newGame(seed)
  math.randomseed(seed or os.time())
  for j = 1, grid.dim.j do
    for i = 1, grid.dim.i do
      spawnBall(i, j)
    end
  end
  if gameplayMode == "candycrush" then
    while grid.match() do
      for e, entity in pairs(entities) do
        if entity.popped then
          local gridPos = grid.pixelToGrid(entity.x, entity.y)
          entity:init(gridPos.i, gridPos.j)
        end
      end
    end
  end
end
 
function grid.getBallAt(i, j)
  if grid[j] and grid[j][i] then return grid[j][i].ball end
end

function grid.checkPossibleMoves()
  possibleMoveIdentified = {}
  if gameplayMode == "dokkan" then
    for j = 1, grid.dim.j do
      for i = 1, grid.dim.i do
        local ball = grid.getBallAt(i, j)
        if ball then
          steps = {{i=0, j=-1}, {i=0, j=1}, {i=-1, j=0}, {i=1, j=0}, {i=1, j=(i%2*2)-1}, {i=-1, j=(i%2*2)-1}}
          local n = 0
          for s, step in pairs(steps) do
            local ni, nj = i + step.i, j + step.j
            local nball = grid.getBallAt(ni, nj)
            if nball and nball.type == ball.type then
              n = n + 1
            end
          end
          if n >= 2 then
            return true
          end
        end
      end
    end
  end
  if gameplayMode == "candycrush" then
    --for each cell
    for j = 1, grid.dim.j do
      for i = 1, grid.dim.i do
        local ball = grid.getBallAt(i, j)
        if ball then
          local steps = {{{i=0, j=-1}, {i=0, j=1}}, {{i=-1, j=0}, {i=1, j=(i%2*2)-1}}, {{i=-1, j=(i%2*2)-1}, {i=1, j=0}}}
          local types = {}
          -- type of balls around cell
          for d, direction in pairs(steps) do
            types[d] = {}
            for s, step in pairs(direction) do
              local ni, nj = i + step.i, j + step.j
              local nball = grid.getBallAt(ni, nj)
              if nball then
                types[d][s] = nball.type
              end
            end
          end
          for d, direction in pairs(types) do
            -- true if cell is in the middle of match of 3 after a swap
            if types[d][1] and  types[d][1] == types[d][2] then
              for d2, direction2 in pairs(types) do
                if d ~= d2 then
                  if types[d2][1] == types[d][1]  then
                    table.insert(possibleMoveIdentified, {ball, grid.getBallAt(i+steps[d2][1].i, j+steps[d2][1].j)})
                  end
                  if types[d2][2] == types[d][1] then
                    table.insert(possibleMoveIdentified, {ball, grid.getBallAt(i+steps[d2][2].i, j+steps[d2][2].j)})
                  end
                end
              end
            end
            -- true if cell is in the side of match of 3 after a swap
            for s, step in pairs(steps[d]) do
              local ni, nj = i + step.i, j + step.j
              local nextSteps = {{{i=0, j=-1}, {i=0, j=1}}, {{i=-1, j=(ni%2*2)-1}, {i=1, j=0}},{{i=-1, j=0}, {i=1, j=(ni%2*2)-1}}}
              local ni, nj = ni + nextSteps[d][s].i, nj + nextSteps[d][s].j
              local nball = grid.getBallAt(ni, nj)
              if nball and types[d][s] == nball.type then
                for d2, direction2 in pairs(types) do
                  for s2, step2 in pairs(direction2) do
                    if (d ~= d2 or s2 ~= s) and (types[d2][s2] == types[d][s]) then
                      table.insert(possibleMoveIdentified, {ball, grid.getBallAt(i+steps[d2][s2].i, j+steps[d2][s2].j)})
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  if #possibleMoveIdentified > 0 then return true end
  return false
end

addDrawFunction(
  function ()
    if possibleMoveIdentified then
      love.graphics.setColor(1, 1, 1, .8)
      for m, move in pairs(possibleMoveIdentified) do
        love.graphics.circle("fill", move[1].x, move[1].y, 5)
        love.graphics.circle("fill", move[2].x, move[2].y, 17)
        love.graphics.line(move[1].x, move[1].y, move[2].x, move[2].y)
      end
    end
  end, 9
)

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
  if gameMenu.hidden then return end
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
end

addDrawFunction( function ()
  if gameMenu.hidden then return end
  if grab then
    love.graphics.push()
    love.graphics.translate(love.mouse.getX(), love.mouse.getY())
    love.graphics.setColor(grab.color)
    love.graphics.circle("fill", 0, 0, cellSize*.75)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", 0, 0, cellSize*.75)
    love.graphics.pop()
  end
  if selection then
    for b, ball in pairs(selection) do
      love.graphics.push()
      love.graphics.translate(math.random(2)-1,math.random(2)-1)
      love.graphics.setColor(ball.color)
      love.graphics.circle("fill", ball.x, ball.y, cellSize*.8)
      love.graphics.setColor(0, 0, 0)
      love.graphics.circle("line", ball.x, ball.y, cellSize*.8)
      love.graphics.pop()
    end
  end
  for n, b in pairs(grid.busy) do
    love.graphics.setColor(0, 0, 0, .1)
    love.graphics.circle("fill", b.x, b.y+3, .8*cellSize)
  end
end, 6)

function grid:update(dt)
  if #grid.busy > 0  then return end
  if gameplayMode == "candycrush" then
    grid.match()
  end
  if not checked then
    checked = true
    if not grid.checkPossibleMoves() then
      print("GAME OVER")
    else
      print("keep going...")
    end
  end
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
  if change then checked = false end
  return change
end

--  Functions for (un-)locking the grid while balls are still falling (or animating)
function grid.occupy(ball)
  table.insert(grid.busy, ball)
end

function grid.liberate(ball)
  for n = #grid.busy, 1, -1 do
    if grid.busy[n]== ball then
      table.remove(grid.busy, n)
    end
  end
  if #grid.busy == 0 then
    for i = 1, grid.dim.i do
      grid.fallHeight[i] = 1
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
    self.popped = false
    if grid[j] and grid[j][i] then
      grid[j][i].type = self.type
      grid[j][i].ball = self
    else
      self.falling = true
      grid.occupy(self)
    end
  end
  ball.draw = function (self)
    if self == grab then return end
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, cellSize*.75)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", self.x, self.y, cellSize*.75)
  end
  ball.update = function (self, dt)
    if self.terminated then return end
    local gridPos = grid.pixelToGrid(self.x, self.y)
    if self.popped then
      self:init(gridPos.i, -grid.fallHeight[gridPos.i])
      grid.fallHeight[gridPos.i] = grid.fallHeight[gridPos.i] + 1
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
    grid.liberate(self)
    local gridPos = grid.pixelToGrid(self.x, self.y)
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
  if change then checked = false end
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
