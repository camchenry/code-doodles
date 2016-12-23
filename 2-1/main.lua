local function sign(x)
    return x > 0 and 1 or (x < 0 and -1 or 0)
end   

local function round(n, places)
    local t = math.pow(10, places)
    return math.floor(n*t)/t
end

paused = false
zoom = 1
zoomVel = 0
translateX = 0
translateY = 0
maxIterations = 256
realConst = 0.5
imagConst = 0.5
circleRadius = 2
supersampling = 1
mode = "julia" -- julia, mandelbrot

-- Color of fractal
hue = love.math.random(0, 360)
saturation = 70
value = 90
-- continuously changing colors
rainbowMode = false
timer = 0

showSplashText = true
splashText = [[
    Fractal Explorer
    created by Cameron McHenry
    Hide this menu: F1

    Controls:
    Pause: Space
    Move viewport: Arrow keys or right mouse button
    Change constant: WASD or Mouse movement
    Change max iterations: , or .
    Change zoom: + or - or Mouse wheel
    Change supersampling: [ or ]
    Change fractals: Tab
    Randomize colors: E
    Rainbow colors mode: R
    Hide this menu: F1
    Hide UI: F2
    Toggle Fullscreen: F11
    Take screenshot: F12 (saved in ]]..love.filesystem.getAppdataDirectory()..[[)
    Close program: Escape
]]
showHud = true
fullscreen = false

local function randomizeColors()
    hue = love.math.random(0, 360)
    saturation = love.math.random(50, 100)
    value = love.math.random(75, 100)
end

function love.load()
    love.graphics.setFont(love.graphics.newFont(18))

    juliaShader = love.graphics.newShader("julia.frag")
end

function love.update(dt)
    dt = math.min(1/30, dt)
    if not paused then
        timer = timer + dt
    end
    zoomVel = zoomVel * 0.95
    if math.abs(zoomVel) < 0.1 then
        zoomVel = 0
    end
    if math.abs(zoomVel) > 3 * zoom then
        zoomVel = 3 * sign(zoomVel) * zoom
    end
    zoom = zoom + zoomVel * dt
    
    if zoom < 0.25 then
        zoom = 0.25
        zoomVel = 0
    end

    if rainbowMode and not paused then
        hue = timer*15 % 360
        saturation = math.sin(timer) * 10 + 80
    end

    if mode == "julia" then
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
        juliaShader:send("mode", 1)
    elseif mode == "mandelbrot" then
        juliaShader:send("translateX", translateX) 
        juliaShader:send("translateY", translateY) 
        juliaShader:send("zoom", zoom) 
        juliaShader:send("maxIterations", maxIterations) 
        juliaShader:send("supersampling", supersampling) 
        juliaShader:send("circleRadius", circleRadius)
        juliaShader:send("hue", hue/360)
        juliaShader:send("saturation", saturation/100)
        juliaShader:send("value", value/100)
        juliaShader:send("mode", 2)
    end
end

function love.wheelmoved(x, y)
    zoomVel = zoomVel + sign(y)/5 * zoom
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        translateX = translateX - dx/love.graphics.getWidth()/zoom * 2
        translateY = translateY - dy/love.graphics.getHeight()/zoom * 2
    elseif not paused then
        realConst = (love.graphics.getWidth()/2 - x)/love.graphics.getWidth() * -2
        imagConst = (love.graphics.getHeight()/2 - y)/love.graphics.getHeight() * -2
    end
end

function love.keypressed(key, code)
    love.keyboard.setKeyRepeat(true)
    
    if key == "tab" then
        if mode == "julia" then
            mode = "mandelbrot"
            circleRadius = 6
        elseif mode == "mandelbrot" then
            mode = "julia"
            circleRadius = 2
        end
        paused = false
        zoom = 1
        zoomVel = 0
        translateX = 0
        translateY = 0
        maxIterations = 256
        realConst = 0.5
        imagConst = 0.5
        supersampling = 1
    end

    if key == "]" then
        supersampling = supersampling + 1
    elseif key == "[" then
        supersampling = supersampling - 1
    end

    supersampling = math.max(1, math.min(8, supersampling))

    if key == "=" then
        zoomVel = zoomVel + 0.5 * zoom
    elseif key == "-" then
        zoomVel = zoomVel - 0.5 * zoom
    end

    if key == "," then
        maxIterations = maxIterations - 16
    elseif key == "." then
        maxIterations = maxIterations + 16
    end

    maxIterations = math.max(0, maxIterations)

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
        imagConst = imagConst - 0.001 / zoom
    elseif key == "s" then
        imagConst = imagConst + 0.001 / zoom
    end

    if key == "a" then
        realConst = realConst - 0.001 / zoom
    elseif key == "d" then
        realConst = realConst + 0.001 / zoom
    end

    if key == "j" then
        circleRadius = circleRadius - 0.05
    end

    if key == "k" then
        circleRadius = circleRadius + 0.05
    end

    if key == "e" then
        randomizeColors()
    end

    if key == "r" then
        rainbowMode = not rainbowMode
    end

    if key == "f1" then
        showSplashText = not showSplashText
    end

    if key == "f2" then
        showHud = not showHud
    end

    if key == "f11" then
        fullscreen = not fullscreen

        love.window.setMode(1600, 900, {
            fullscreen = fullscreen
        })
    end

    if key == "f12" then
        local screenshot = love.graphics.newScreenshot(false)
        screenshot:encode("png", "Screenshot" .. love.timer.getTime() .. ".png")
    end
end

function love.draw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setShader(juliaShader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()

    if showHud then
        love.graphics.print(mode, 5, 0)
        love.graphics.print("c = " .. round(realConst, 4) .. " + " .. round(imagConst, 4) .. "i", 5, 20)
        love.graphics.print("x = " .. round(translateX, 7), 5, 40)
        love.graphics.print("y = " .. round(translateY, 7), 5, 60)
        love.graphics.print("iterations = " .. maxIterations, 5, 80)
        love.graphics.print("zoom: " .. round(zoom, 2), 5, 100)
        love.graphics.print("ssaa: " .. supersampling, 5, 120)

        local statustext = ""

        if paused then
            statustext = statustext .."PAUSED"
        end

        if rainbowMode then
            if statustext ~= "" then statustext = statustext .. ", " end
            statustext = statustext .."RAINBOW"
        end

        love.graphics.printf(statustext, 0, 20, love.graphics.getWidth(), "center")

        if showSplashText then
            love.graphics.setColor(0, 0, 0, 100)
            local w = 600
            local maxWidth, lines = love.graphics.getFont():getWrap(splashText, w)
            local h = love.graphics.getFont():getHeight() * #lines
            local x = love.graphics.getWidth()/2 - w/2
            local y = love.graphics.getHeight()/2 - h/2
            love.graphics.rectangle("fill", x-25, y-25, w+50, h+50)
            love.graphics.setColor(255, 255, 255)
            love.graphics.rectangle("line", x-25, y-25, w+50, h+50)
            love.graphics.printf(splashText, x, y, w, "center")
        end
    end
end
