function love.load()
    math.randomseed(os.time())
    paused = false
    zoom = 1
    moveX = 0
    moveY = 0
    maxIterations = 250
    realConst = -0.7
    imagConst = 0.2
    circleRadius = 2
    hue = 200 + math.random(-100, 100)
    saturation = 100
    value = 100

    automode = false
    autoangle = 0

    love.graphics.setFont(love.graphics.newFont(18))

    juliaShader = love.graphics.newShader("julia.shader")
    juliaShader:send("moveX", moveX) 
    juliaShader:send("moveY", moveY) 
    juliaShader:send("zoom", zoom) 
    juliaShader:send("maxIterations", maxIterations) 
    juliaShader:send("realConst", realConst) 
    juliaShader:send("imagConst", imagConst) 
    juliaShader:send("circleRadius", circleRadius)
    juliaShader:send("hue", hue/360)
    juliaShader:send("saturation", saturation/100)
    juliaShader:send("value", value/100)
end

function love.update(dt)
    if automode then
        autoangle = autoangle + 0.005 * love.timer.getDelta() 
        local length = math.cos(autoangle*1.5)*math.sin(autoangle*2)
        realConst = math.cos(autoangle)*length
        imagConst = math.sin(autoangle)*length
        juliaShader:send("realConst", realConst) 
        juliaShader:send("imagConst", imagConst) 
   end
end

function sign(x)
    return x>0 and 1 or x<0 and -1 or 0
end   

function love.wheelmoved(x, y)
    if love.keyboard.isDown(1) then
        hue = hue + 1 * sign(y)
        juliaShader:send("hue", hue/360)
    elseif love.keyboard.isDown(2) then
        saturation = saturation + 1 * sign(y)
        juliaShader:send("saturation", saturation/100)
    elseif love.keyboard.isDown(3) then
        value = value + 1 * sign(y)
        juliaShader:send("value", value/100)
    else
        zoom = zoom + 0.02 * sign(y)
        juliaShader:send("zoom", zoom) 
    end
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        moveX, moveY = moveX - dx, moveY - dy

        juliaShader:send("moveX", moveX/700/zoom)
        juliaShader:send("moveY", moveY/700/zoom)
    elseif not paused and not automode then
        realConst = (love.graphics.getWidth()/2 - x)/love.graphics.getWidth() * -2
        imagConst = (love.graphics.getHeight()/2 - y)/love.graphics.getHeight() * -2
        juliaShader:send("realConst", realConst) 
        juliaShader:send("imagConst", imagConst) 
    end
end

function love.keypressed(key, code)
    love.keyboard.setKeyRepeat(true)

    if key == "escape" then
        love.event.quit()
    end

    if key == "space" then
        paused = not paused
    end
    
    if key == "-" and love.keyboard.isDown(1) then
        hue = hue - 1
        juliaShader:send("hue", hue/360)
    elseif key == "=" and love.keyboard.isDown(1) then
        hue = hue + 1
        juliaShader:send("hue", hue/360)
    elseif key == "-" and love.keyboard.isDown(2) then
        saturation = saturation - 1
        juliaShader:send("saturation", saturation/100)
    elseif key == "=" and love.keyboard.isDown(2) then
        saturation = saturation + 1
        juliaShader:send("saturation", saturation/100)
    elseif key == "-" and love.keyboard.isDown(3) then
        value = value - 1
        juliaShader:send("value", value/100)
    elseif key == "=" and love.keyboard.isDown(3) then
        value = value + 1
        juliaShader:send("value", value/100)
    elseif key == "-" then
        zoom = zoom * 0.99
        juliaShader:send("zoom", zoom)
    elseif key == "=" then
        zoom = zoom / 0.99 
        juliaShader:send("zoom", zoom)
    end

    if key == "up" then
        moveY = moveY - 1/love.graphics.getHeight()
    elseif key == "down" then
        moveY = moveY + 1/love.graphics.getHeight()
    end

    if key == "left" then
        moveX = moveX - 1/love.graphics.getWidth()
    elseif key == "right" then
        moveX = moveX + 1/love.graphics.getWidth()
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

    if key == "w" or key == "a" or key == "s" or key == "d" then
        juliaShader:send("realConst", realConst)
        juliaShader:send("imagConst", imagConst)
    end

    if key == "left" or key == "up" or key == "down" or key == "right" then
        juliaShader:send("moveX", moveX*2)
        juliaShader:send("moveY", moveY*2)
    end

    if key == "j" then
        circleRadius = circleRadius - 0.05
    end

    if key == "k" then
        circleRadius = circleRadius + 0.05
    end

    if key == "j" or key == "k" then
        juliaShader:send("circleRadius", circleRadius)
    end

    if key == "b" then
        automode = not automode
    end
end

function love.draw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setShader(juliaShader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
    love.graphics.print("c = " .. realConst .. " + " .. imagConst .. "i") 
    love.graphics.print(hue .. ", " .. saturation .. ", " .. value, 0, 20)
    love.graphics.print(moveX .. ", " .. moveY, 0, 40)
    love.graphics.print(circleRadius, 0, 60)
end
