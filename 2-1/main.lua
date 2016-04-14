juliaShaderCode = [[
    extern number hue;
    extern number saturation;
    extern number value;
    extern number zoom;
    extern number moveX;
    extern number moveY; 
    extern number maxIterations;
    extern number realConst;
    extern number imagConst;

    vec3 rgb2hsv(vec3 c)
    {
        vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
        vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }
    
    vec3 hsv2rgb(vec3 c)
    {
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 texcolor = Texel(texture, texture_coords);
        float newRe = 1.5 * (screen_coords.x - love_ScreenSize.x/2) / (0.5 * zoom * love_ScreenSize.x) + moveX;
        float newIm = (screen_coords.y - love_ScreenSize.y/2) / (0.5 * zoom * love_ScreenSize.y) + moveY;
        float oldRe;
        float oldIm;
        float z;
        float i;
        float smooth = 0;
        for(i=0; i<maxIterations; i++) {
            oldRe = newRe;
            oldIm = newIm;

            newRe = oldRe * oldRe - oldIm * oldIm + realConst;
            newIm = 2 * oldRe * oldIm + imagConst;
            
            z = newRe * newRe + newIm * newIm;
            smooth = smooth + exp(-abs(z));
            if (z > 4) {
                break;
            }
        }
        smooth = smooth / maxIterations;
        vec3 hsv = vec3(hue + smooth/5, saturation - smooth/10, i < maxIterations ? value : 0);
        vec3 rgb = hsv2rgb(hsv);
        return vec4(rgb.r, rgb.g, rgb.b, smooth*50);
    }
]]

function love.load()
    paused = false
    zoom = 1
    moveX = 0
    moveY = 0
    maxIterations = 1000
    realConst = -0.7
    imagConst = 0.2
    hue = 200
    saturation = 100
    value = 100

    juliaShader = love.graphics.newShader(juliaShaderCode)
    juliaShader:send("moveX", moveX) 
    juliaShader:send("moveY", moveY) 
    juliaShader:send("zoom", zoom) 
    juliaShader:send("maxIterations", maxIterations) 
    juliaShader:send("realConst", realConst) 
    juliaShader:send("imagConst", imagConst) 
    juliaShader:send("hue", hue/360)
    juliaShader:send("saturation", saturation/100)
    juliaShader:send("value", value/100)
end

function love.update(dt)
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
    elseif not paused then
        realConst = x / love.graphics.getWidth()
        imagConst = y / love.graphics.getHeight()

        juliaShader:send("realConst", realConst) 
        juliaShader:send("imagConst", imagConst) 
    end
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end

    if key == "space" then
        paused = not paused
    end
end

function love.draw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setShader(juliaShader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
    love.graphics.print(hue .. ", " .. saturation .. ", " .. value)
    love.graphics.print(moveX .. ", " .. moveY, 0, 10)
end
