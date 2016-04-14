-- Converts HSL to RGB (input and output range: 0 - 255)
function HSL(h, s, l)
   if s == 0 then return l,l,l end
   h, s, l = h/256*6, s/255, l/255
   local c = (1-math.abs(2*l-1))*s
   local x = (1-math.abs(h%2-1))*c
   local m,r,g,b = (l-.5*c), 0,0,0
   if h < 1     then r,g,b = c,x,0
   elseif h < 2 then r,g,b = x,c,0
   elseif h < 3 then r,g,b = 0,c,x
   elseif h < 4 then r,g,b = 0,x,c
   elseif h < 5 then r,g,b = x,0,c
   else              r,g,b = c,0,x
   end
   return math.ceil((r+m)*256),math.ceil((g+m)*256),math.ceil((b+m)*256)
end

function lerp(t, a, b)
	return (1-t)*a + t*b;
end

function newRing()
    local delay = math.random()*10
    return {
        time = delay + time,
        speed = math.random(15, 60),
        width = math.random(1, 5),
        radius = 0,
        delay = delay,
        hue = 0,
        saturation = 50,
        lightness = 90,
        color = {0, 0, 0, 0}
    }
end

function love.load()
    love.window.setMode(800, 600, {msaa=4})
	centerX = love.graphics.getWidth()/2
    centerY = love.graphics.getHeight()/2
   
    math.randomseed(os.time())

    time = 0
    ringStart = 5
    ringLimit = 100
	rings = {}
    for i=1, ringStart do
		table.insert(rings, newRing()) 
	end
end

function love.update(dt)
    time = time + dt

	for	i, ring in pairs(rings) do
        ring.time = ring.time + dt
        ring.saturation = math.cos(ring.time) * 90 + 10
        ring.lightness = math.sin(ring.time*0.65) * 90 + 5
        ring.hue = ring.hue + math.sin(ring.time) * ring.speed * dt
        ring.hue = ring.hue % 360

        if ring.delay > 0 then
            ring.delay = ring.delay - dt
        else
            ring.radius = ring.radius + ring.speed * dt		
        end

        ring.color = {HSL(ring.hue, ring.saturation, ring.lightness)}
	end

    -- remove rings off screen
    local distToCenter = math.max(math.sqrt(centerX*centerX + centerY*centerY))
    for i=#rings, 1, -1 do
        if rings[i].radius > distToCenter then
            table.remove(rings, i)
        end
    end
    
    if #rings < ringLimit then
        table.insert(rings, newRing())
    end
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    -- love.graphics.setColor(HSL(hue, saturation, lightness))
	-- love.graphics.circle("fill", centerX, centerY, 25)

    for i, ring in pairs(rings) do
        love.graphics.setLineWidth(ring.width)
        love.graphics.setColor(ring.color)
        love.graphics.circle("line", centerX, centerY, ring.radius)
    end
end
