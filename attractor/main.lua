lick = require "lick"
lick.reloadOnChange = true

local vector = require "vector"
local Class = require "middleclass"

local Attractor = Class("Attractor")

function Attractor:initialize()
    self.points = {}

    self.x = 0
    self.y = 0
    self.z = 0

    self:resetParameters()
end

function Attractor:resetParameters(a, b, c, d, e, f)
    self.a = a or love.math.random() * math.pi
    self.b = b or love.math.random() * math.pi
    self.c = c or love.math.random() * math.pi
    self.d = d or love.math.random() * math.pi
    self.e = e or love.math.random() * math.pi
    self.f = f or love.math.random() * math.pi
end

function Attractor:addNextPoint()
    local function addPoint(x, y)
        table.insert(self.points, x)
        table.insert(self.points, y)
    end

    local cos, sin = math.cos, math.sin
    local width, height = love.graphics.getDimensions()

    self.x = sin(self.a * self.x) + sin(self.b * self.y) - cos(self.c * self.z)
    self.y = sin(self.d * self.x) + sin(self.e * self.y) - cos(self.f * self.z)
    self.z = self.z + 0.1
    addPoint(self.x * width/8 + width/2, self.y * height/8 + height/2)
end

function Attractor:createGraph(n)
    self.points = {}

    self.x = 0
    self.y = 0
    self.z = 0

    self:updateGraph(n)
end

function Attractor:updateGraph(n)
    for i=1, n do
        self:addNextPoint()
    end
end

function Attractor:draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.points(self.points)
end

function love.load()
    love.window.setMode(800, 800, {
        msaa = 2,
    })
    attractor = Attractor:new()
    attractor:createGraph(100000)
end

function love.update(dt)
    -- attractor:updateGraph(math.floor(4000*dt))
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end

    if key == "r" then
        attractor:resetParameters()
        attractor:createGraph(100000)
    end
end

function love.draw()
    love.graphics.setBackgroundColor(220, 220, 220)
    attractor:draw()
end
