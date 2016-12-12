Class = require "class"
Vector = require "vector"

local lg = love.graphics
WIDTH, HEIGHT = love.graphics.getDimensions()
local imageData = love.image.newImageData(50, 10)
for x=0, 49 do
    for y=0, 9 do
        imageData:setPixel(x, y, 255, 255, 255, 255)
    end
end
RECT_IMG = love.graphics.newImage(imageData)

-- seconds until reset
lifespan = 2.5
forcesPerSecond = 50
timer = 0
count = 1
maxCount = lifespan * forcesPerSecond
maxForce = 600
mutationRate = 0.01

target = Vector(WIDTH/2, 50)


local function randomVector()
    local x = love.math.random()*2-1
    local y = love.math.random()*2-1
    local v = Vector(x, y)
    v:normalizeInplace()
    return v * maxForce
end

DNA = Class "DNA"

function DNA:initialize(genes)
    if genes then
        self.genes = genes
    else
        self.genes = {}
        for i=1, maxCount do
            table.insert(self.genes, randomVector())
        end
    end
end

function DNA:crossover(partner)
    local newgenes = {}
    local mid = math.floor(love.math.random(#self.genes))

    for i=1, #self.genes do
        if i > mid then
            newgenes[i] = self.genes[i]
        else
            newgenes[i] = partner.genes[i]
        end
    end

    return DNA:new(newgenes)
end

function DNA:mutation()
    for i=1, #self.genes do
        if love.math.random() < mutationRate then
            self.genes[i] = randomVector()
        end
    end
end

Rocket = Class "Rocket"

function Rocket:initialize(dna)
    self.pos = Vector(WIDTH/2, HEIGHT)
    self.vel = Vector()
    self.acc = Vector()
    self.completed = false
    self.crashed = false
    if dna then
        self.dna = dna
    else
        self.dna = DNA:new()
    end
    self.fitness = 0
end

function Rocket:applyForce(force)
    self.acc = self.acc + force
end

function Rocket:calculateFitness()
    local d = self.pos:dist(target)
    self.fitness = 1 / d * 10000

    if self.completed then
        self.fitness = self.fitness * 10
    end
end

function Rocket:update(dt)
    local d = self.pos:dist(target)

    if d < 10 then
        self.pos = target:clone()
        self.completed = true
    end

    self:applyForce(self.dna.genes[count])
    if not self.completed then
        self.vel = self.vel + self.acc * dt
        self.pos = self.pos + self.vel * dt
        self.acc = self.acc * 0
    end
end

function Rocket:draw()
    lg.push()
    lg.setColor(255, 255, 255, 200)
    local w = 50
    local h = 10
    lg.draw(RECT_IMG, self.pos.x, self.pos.y, self.vel:angleTo(), 1, 1, w/2, h/2)
    lg.pop()
end

Population = Class "Population"

function Population:initialize(size)
    self.rockets = {}
    self.size = size or 25
    self.matingPool = {}

    for i=1, self.size do
        table.insert(self.rockets, Rocket:new())
    end
end

function Population:evaluate()
    local maxfit = -1

    for _, rocket in ipairs(self.rockets) do
        rocket:calculateFitness()
        maxfit = math.max(maxfit, rocket.fitness)
    end

    for _, rocket in ipairs(self.rockets) do
        rocket.fitness = rocket.fitness / maxfit
    end

    print(maxfit)

    self.matingPool = {}

    -- make rockets with high fitness more likely to be picked
    for _, rocket in ipairs(self.rockets) do
        local n = rocket.fitness * 100
        for j=0, n do
            table.insert(self.matingPool, rocket)
        end
    end
end

function Population:selection()
    local newRockets = {}
    for i, rocket in ipairs(self.rockets) do
        local parentA = self.matingPool[love.math.random(#self.matingPool)].dna
        local parentB = self.matingPool[love.math.random(#self.matingPool)].dna
        local child = parentA:crossover(parentB)
        child:mutation()
        newRockets[i] = Rocket:new(child)
    end
    self.rockets = newRockets
end

function Population:update(dt)
    for _, rocket in ipairs(self.rockets) do
        rocket:update(dt)
    end
end

function Population:draw()
    for _, rocket in ipairs(self.rockets) do
        rocket:draw()
    end
end

function love.load()
    population = Population:new()
end

function love.update(dt)
    population:update(dt)

    timer = timer + dt
    if timer > 1/forcesPerSecond then
        count = count + 1
        timer = 0
    end

    -- Reset and reevaluate
    if count == maxCount then
        population:evaluate()
        population:selection()
        count = 1
        timer = 0
    end
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    population:draw()

    love.graphics.circle("fill", target.x, target.y, 10)

    love.graphics.print(count, 5, 5)
end
