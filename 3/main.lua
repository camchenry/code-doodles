-- http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
function rgbToHsl(r, g, b, a)
  r, g, b = r / 255, g / 255, b / 255

  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, l

  l = (max + min) / 2

  if max == min then
    h, s = 0, 0 -- achromatic
  else
    local d = max - min
    local s
    if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
    if max == r then
      h = (g - b) / d
      if g < b then h = h + 6 end
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h, s, l, a or 255
end

function hslToRgb(h, s, l, a)
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    function hue2rgb(p, q, t)
      if t < 0   then t = t + 1 end
      if t > 1   then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
    end

    local q
    if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
    local p = 2 * l - q

    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end

  return r * 255, g * 255, b * 255, (a or 1) * 255
end
function newDot()
    local dot = {
        x = love.graphics.getWidth()/2,
        y = love.graphics.getHeight()/2,
        velX = 0,
        velY = 0,
        radius = math.random(1, 4),
        color = {255, 255, 255}
    }
    
    dot.update = function(self)
        self.velX = self.velX * 0.9
        self.velY = self.velY * 0.9
        self.velX = self.velX + math.random(-1, 1)
        self.velY = self.velY + math.random(-1, 1)
        self.x = self.x + self.velX
        self.y = self.y + self.velY
        
        self.radius = math.max(1, math.log(self.velX*self.velX + self.velY*self.velY))
    end

    dot.draw = function(self)
        love.graphics.setColor(self.color)
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end

    return dot
end

function love.load()
    dots = {}

    for i=1, 100 do
        table.insert(dots, newDot())
    end
end

function love.update(dt)
    for i, dot in pairs(dots) do
        dot:update(dt)
    end
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    for i, dot in pairs(dots) do
        dot:draw()
    end
end
