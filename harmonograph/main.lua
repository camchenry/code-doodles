lick = require "lick"
lick.reloadOnChange = true

local vector = require "vector"
local Class = require "middleclass"

local Pendulum = Class("Pendulum")

function Pendulum:initialize(amplitude, frequency, phase, damping, time)
    self.amplitude = amplitude or 1
    self.frequency = frequency or 1
    self.phase = phase or 1
    self.damping = damping or 0.01
    self.time = time or 0
    self.position = 0
end

function Pendulum:update(dt)
    self.time = self.time + dt

    local e = math.exp(1)
    self.position = self.amplitude * math.sin(self.time * self.frequency + self.phase) * e^(-1 * self.damping * self.time)
end

local Harmonograph = Class("Harmonograph")

function Harmonograph:initialize(dt, time)
    self.pendulums = {}
    self.pendulums.x = Pendulum:new(250, math.pi/6, 0, 0.02)
    self.pendulums.y = Pendulum:new(250, math.pi/1.5, 0, 0.02)

    self.dt = dt
    self.time = time

    self.points = {}
end

function Harmonograph:createGraph()
    self.points = {}

    for i=0, self.time, self.dt do
        for j, pend in pairs(self.pendulums) do
            pend:update(self.dt)
        end
        table.insert(self.points, self.pendulums.x.position)
        table.insert(self.points, self.pendulums.y.position)
    end
end

function Harmonograph:draw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.line(self.points)
end

function love.load()
    harmonograph = Harmonograph:new(1/100, 200)
    harmonograph:createGraph()
end

function love.update(dt)
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    harmonograph:draw()
end
