local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function newPoint(x, y)
    return {x=x, y=y}
end

local function midpoint(a, b)
    local x = (a.x + b.x) / 2
    local y = (a.y + b.y) / 2
    return newPoint(x, y)
end

local function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h, s, v = h/256*6, s/255, v/255
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m)*255,(g+m)*255,(b+m)*255
end

-- https://bitesofcode.wordpress.com/2016/12/23/landscape-generation-using-midpoint-displacement/
local function terrain_generate(start, finish, options)
    local vertical_displacement = options.displacement or ((start.y + finish.y) / 2)
    local num_iterations = options.iterations or 8
    local roughness = options.roughness or 1

    local points = {start, finish}

    for i=1, num_iterations do
        local points_copy = deepcopy(points)
        for j=1, #points_copy - 1 do
            local point = points_copy[j]
            local nextPoint = points_copy[j+1]
            local mid = midpoint(point, nextPoint)

            if love.math.random() > 0.5 then
                mid.y = mid.y + vertical_displacement
            else
                mid.y = mid.y - vertical_displacement
            end

            table.insert(points, mid)
        end

        vertical_displacement = vertical_displacement * math.pow(2, -roughness)

        table.sort(points, function(a, b) return a.x < b.x end)
    end

    return points
end

local function terrain_render(terrain, color)
    local canvas = love.graphics.newCanvas()
    local w, h = love.graphics.getDimensions()

    canvas:renderTo(function()
        love.graphics.push()
        love.graphics.setColor(color or {255, 255, 255})
        for i, point in pairs(terrain) do
            local x, y = point.x, point.y
            love.graphics.setLineStyle('rough')
            love.graphics.setLineWidth(1)
            love.graphics.line(x, y, x, y+(h-y))
        end

        love.graphics.pop()
    end)

    return canvas
end

local function stars_render(stars_max)
    local canvas = love.graphics.newCanvas()
    local w, h = love.graphics.getDimensions()

    canvas:renderTo(function()
        love.graphics.push()
        for i=1, stars_max do
            local alpha = 200 + love.math.random(-50, 50)
            local hue = love.math.random(0, 255)
            local color = {HSV(hue, 10, 255)}
            color[4] = alpha
            love.graphics.setColor(color)
            local x = love.math.random(w)
            local y = love.math.random(h)
            local size = love.math.randomNormal(15, 5)/10
            love.graphics.setPointSize(math.floor(size))
            love.graphics.points(x, y)
        end

        love.graphics.pop()
    end)

    return canvas
end

local function moon_render()
    local canvas = love.graphics.newCanvas()
    local w, h = love.graphics.getDimensions()

    canvas:renderTo(function()
        love.graphics.push()
        love.graphics.setColor(227, 227, 227, 255)

        local x = love.math.random(50, w-50)
        local y = love.math.random(50, 150)
        local r = love.math.random(15, 25)
        love.graphics.circle("fill", x, y, r)

        love.graphics.pop()
    end)

    return canvas
end

local function newGradient(colors)
    local direction = colors.direction or "horizontal"
    if direction == "horizontal" then
        direction = true
    elseif direction == "vertical" then
        direction = false
    else
        error("Invalid direction '" .. tostring(direction) "' for gradient.  Horizontal or vertical expected.")
    end
    local result = love.image.newImageData(direction and 1 or #colors, direction and #colors or 1)
    for i, color in ipairs(colors) do
        local x, y
        if direction then
            x, y = 0, i - 1
        else
            x, y = i - 1, 0
        end
        result:setPixel(x, y, color[1], color[2], color[3], color[4] or 255)
    end
    result = love.graphics.newImage(result)
    result:setFilter('linear', 'linear')
    return result
end

local function sky_render(daylight, color)
    local canvas = love.graphics.newCanvas()
    local w, h = love.graphics.getDimensions()
    local color = color or {255, 255, 255}
    local baseColor = {0, 0, 0}
    if daylight then
        baseColor = {color[1]*1.1, color[2]*1.1, color[3]*1.1}
    end

    local gradient = newGradient{
        direction = "horizontal",
        baseColor,
        color,
        color,
    }

    local function drawinrect(img, x, y, w, h, r, ox, oy, kx, ky)
        love.graphics.draw(img, x, y, r, w / img:getWidth(), h / img:getHeight(), ox, oy, kx, ky)
    end

    canvas:renderTo(function()
        love.graphics.push()
        drawinrect(gradient, -800, -800, w+2000, h+2000, love.math.random()*0.3 - 0.15)
        love.graphics.pop()
    end)

    return canvas
end

local layers = {}

function love.load()
    love.window.setMode(1920, 1080)
    local w, h = love.graphics.getDimensions()
    local hue = love.math.random(0, 255)

    local sky_color = {HSV(hue+128, 50, 200)}
    table.insert(layers, sky_render(true, sky_color))
    -- table.insert(layers, stars_render(500))
    table.insert(layers, moon_render())

    for i=1, 6 do
        local h1 = love.math.random(h/2) + math.pow(3, i) + h/3
        local h2 = love.math.random(h/2) + math.pow(3, i) + h/3
        local terrain = terrain_generate(newPoint(0, h1), newPoint(w, h2), {
            roughness = 1.2 - 0.1*i,
            iterations = 11,
            displacement = 200 - 30*i,
        })
        local sat = 200
        local val = 50 + i*40
        local color = {HSV(hue, sat, val*0.9)}
        terrain = terrain_render(terrain, color)
        
        table.insert(layers, terrain)
    end

end

function love.update(dt)

end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    love.graphics.setColor(255, 255, 255)          
    for k, layer in pairs(layers) do
        love.graphics.draw(layer, 0, 0)
    end
end
