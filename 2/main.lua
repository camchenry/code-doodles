function rgbToHsv(r, g, b, a)
  a = a or 255
  r, g, b, a = r / 255, g / 255, b / 255, a / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, v
  v = max

  local d = max - min
  if max == 0 then s = 0 else s = d / max end

  if max == min then
    h = 0 -- achromatic
  else
    if max == r then
    h = (g - b) / d
    if g < b then h = h + 6 end
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h, s, v, a
end

function hsvToRgb(h, s, v, a)
  local r, g, b
  a = a or 255

  local i = math.floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);

  i = i % 6

  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end

  return r * 255, g * 255, b * 255, a * 255
end

function generateJuliaSet(realConst, imagConst)
    local pixels = {}
    for x=0, screenWidth do
        for y=0, screenHeight do
            local newRe = 1.5 * (x - screenWidth/2) / (0.5 * zoom * screenWidth) + moveX 
            local newIm = (y - screenHeight/2) / (0.5 * zoom * screenHeight) + moveY
            local iters = 0
            for i=0, maxIterations do
                iters = iters + 1
                oldRe = newRe
                oldIm = newIm

                newRe = oldRe * oldRe - oldIm * oldIm + realConst
                newIm = 2 * oldRe * oldIm + imagConst
                
                -- point is outside radius of 2
                if (newRe * newRe + newIm * newIm) > 4 then break end
            end
            local r, g, b, a = hsvToRgb((iters%360)/360+0.66, 0.75, iters < maxIterations and 1 or 0, 200)
            table.insert(pixels, {x, y, r, g, b, 255}) 
        end
    end
    return pixels
end

function love.load()
    pixels = {}
   
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()

    moveX = 0
    moveY = 0
    zoom = 1

    maxIterations = 500

    realConst = 0
    imagConst = 0

    pixels = generateJuliaSet(realConst, imagConst)
end

function love.update(dt)

end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        moveX = moveX + dx/screenWidth
        moveY = moveY + dy/screenHeight
    else
        realConst = realConst + (dx/screenWidth)
        imagConst = imagConst + (dy/screenHeight)
    end
    pixels = generateJuliaSet(realConst, imagConst)
end

function love.wheelmoved(x, y)
    if y > 0 then
        zoom = zoom + 0.05
    elseif y < 0 then
        zoom = zoom - 0.05
    end
    pixels = generateJuliaSet(realConst, imagConst)
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    love.graphics.setBackgroundColor(66, 66, 66)
    love.graphics.setColor(255, 255, 255)
    love.graphics.points(pixels) 
end
