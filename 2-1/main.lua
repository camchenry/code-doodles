Camera = require "camera"

local function sign(x)
    return x > 0 and 1 or (x < 0 and -1 or 0)
end   

paused = false
zoom = 1
zoomVel = 0
translateX = 0
translateY = 0
maxIterations = 512
realConst = 0
imagConst = 0
circleRadius = 2
supersampling = 1

-- Color of fractal
hue = 200 + love.math.random(-100, 100)
saturation = 80
value = 100

function love.load()
    love.graphics.setFont(love.graphics.newFont(18))

    camera = Camera()

    juliaShader = love.graphics.newShader("julia.frag")
end

function love.update(dt)
    zoomVel = zoomVel * 0.95
    zoom = zoom + zoomVel * dt

    juliaShader:send("translateX", translateX) 
    juliaShader:send("translateY", translateY) 
    juliaShader:send("zoom", zoom) 
    juliaShader:send("maxIterations", maxIterations) 
    juliaShader:send("supersampling", supersampling) 
    juliaShader:send("realConst", realConst) 
    juliaShader:send("imagConst", imagConst) 
    juliaShader:send("circleRadius", circleRadius)
    juliaShader:send("hue", hue/360)
    juliaShader:send("saturation", saturation/100)
    juliaShader:send("value", value/100)
end

function love.wheelmoved(x, y)
    zoomVel = zoomVel + sign(y)/10 * zoom
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        translateX = translateX - dx/love.graphics.getWidth()/zoom
        translateY = translateY - dy/love.graphics.getHeight()/zoom
    elseif not paused then
        realConst = (love.graphics.getWidth()/2 - x)/love.graphics.getWidth() * -2
        imagConst = (love.graphics.getHeight()/2 - y)/love.graphics.getHeight() * -2
    end
end

function love.keypressed(key, code)
    love.keyboard.setKeyRepeat(true)

    if key == "=" then
        supersampling = supersampling + 1
    elseif key == "-" then
        supersampling = supersampling - 1
    end

    if key == "escape" then
        love.event.quit()
    end

    if key == "space" then
        paused = not paused
    end
    
    if key == "up" then
        translateY = translateY - 1/love.graphics.getHeight()
    elseif key == "down" then
        translateY = translateY + 1/love.graphics.getHeight()
    end

    if key == "left" then
        translateX = translateX - 1/love.graphics.getWidth()
    elseif key == "right" then
        translateX = translateX + 1/love.graphics.getWidth()
    end

    if key == "w" then
        imagConst = imagConst - 0.001 * zoom
    elseif key == "s" then
        imagConst = imagConst + 0.001 * zoom
    end

    if key == "a" then
        realConst = realConst - 0.001 * zoom
    elseif key == "d" then
        realConst = realConst + 0.001 * zoom
    end

    if key == "j" then
        circleRadius = circleRadius - 0.05
    end

    if key == "k" then
        circleRadius = circleRadius + 0.05
    end
end

function love.draw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.setBackgroundColor(0, 0, 0)
    camera:attach()
    love.graphics.setShader(juliaShader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
    camera:detach()
    love.graphics.print("c = " .. realConst .. " + " .. imagConst .. "i") 
    love.graphics.print(hue .. ", " .. saturation .. ", " .. value, 0, 20)
    love.graphics.print(translateX .. ", " .. translateY, 0, 40)
    love.graphics.print("zoom: " .. math.floor(zoom*100)/100, 0, 60)
    love.graphics.print("ssaa: " .. supersampling, 0, 80)
end
