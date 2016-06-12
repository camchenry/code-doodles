local Shader;
local firstCanvas;
local secondCanvas;
local currentCanvas
local otherCanvas
local lastPoint = {x=0,y=0}

function love.load()
	Shader = love.graphics.newShader[[

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
		{

		number pW = 1/love_ScreenSize.x;//pixel width 
		number pH = 1/love_ScreenSize.y;//pixel height

		vec4 pixel = Texel(texture, texture_coords );//This is the current pixel 

		vec2 coords = vec2(texture_coords.x-pW,texture_coords.y);
		vec4 Lpixel = Texel(texture, coords );//Pixel on the left

		coords = vec2(texture_coords.x+pW,texture_coords.y);
		vec4 Rpixel = Texel(texture, coords );//Pixel on the right

		coords = vec2(texture_coords.x,texture_coords.y-pH);
		vec4 Upixel = Texel(texture, coords );//Pixel on the up

		coords = vec2(texture_coords.x,texture_coords.y+pH);
		vec4 Dpixel = Texel(texture, coords );//Pixel on the down

		pixel.a += 10 * 0.0166667 * (Lpixel.a + Rpixel.a + Dpixel.a * 3 + Upixel.a - 6 * pixel.a);

		pixel.rgb = vec3(1.0,1.0,1.0);


		return pixel;

		}
		]]

	firstCanvas = love.graphics.newCanvas()
	secondCanvas = love.graphics.newCanvas()

	currentCanvas = firstCanvas
	otherCanvas = secondCanvas

	lastPoint.x = love.mouse.getX()
	lastPoint.y = love.mouse.getY()
end

local fps = 0;
local mouseParticles = {};


function love.draw()
	love.graphics.setColor(0,0,0,255)
    
	love.graphics.rectangle("fill",0,0,100,50)
	love.graphics.setColor(255,255,255,255)
	love.graphics.print("FPS: " .. fps,10,10)
    love.graphics.print('test')

	if(#mouseParticles > 0)then 
		love.graphics.setCanvas(firstCanvas)
		love.graphics.setColor(255,255,255,255)
		for i=1,#mouseParticles do 
			local p = mouseParticles[i];
			love.graphics.circle("fill",p.x,p.y,10);
		end
		love.graphics.setCanvas()
		mouseParticles = {}
		love.graphics.setColor(255,255,255,255)
	end


	love.graphics.setCanvas(otherCanvas)
	love.graphics.setShader(Shader);
	love.graphics.draw(currentCanvas)
	love.graphics.setShader();
	love.graphics.setCanvas()

	
	currentCanvas:clear()

	love.graphics.setCanvas(currentCanvas)
	love.graphics.setShader(Shader);
	love.graphics.draw(otherCanvas)
	love.graphics.setShader();
	love.graphics.setCanvas()

	love.graphics.draw(currentCanvas)
	otherCanvas:clear()


	
end

local c2 = 0;
local sum = 0;

local lastModified = love.filesystem.getLastModified("main.lua")


function love.update(dt)
	------------To make the code update in real time
	if(love.filesystem.getLastModified("main.lua") ~= lastModified)then 
		local testFunc = function()
			love.filesystem.load('main.lua')
		end
		local test,e = pcall(testFunc)
		if(test)then 
		 	love.filesystem.load('main.lua')()
		 	love.run()
		else 
			print(e)
		end
		lastModified = love.filesystem.getLastModified("main.lua")
	end

	-----------Get average FPS
	c2 = c2 + 1;
	sum = sum + dt;
	if(sum > 1)then 
		sum = sum / c2;
		fps = math.floor(1/sum);
		c2 = 0;
		sum = 0;
	end

	-----Add smoke
	if(love.mouse.isDown(1))then 
		local x,y = love.mouse.getPosition()
		local p = {};
		p.x = x; p.y = y;
		mouseParticles[#mouseParticles+1] = p;

		local dx = p.x - lastPoint.x;
		local dy = p.y - lastPoint.y;
		local dist = math.sqrt(dx * dx + dy * dy);

		---if there is a gap, fill it
		if(dist > 5)then 
			local angle = math.atan2(dy,dx);
			local cosine = math.cos(angle);
			local sine = math.sin(angle)
			for i=1,dist,1 do 
				local p2 = {};
				p2.x = lastPoint.x + i * cosine;
				p2.y = lastPoint.y + i * sine;
				mouseParticles[#mouseParticles+1] = p2;
			end
		end

		lastPoint.x = x; lastPoint.y = y;
	else
		--if mouse is up
		local x,y = love.mouse.getPosition()
		lastPoint.x = x; lastPoint.y = y;
	end
end



