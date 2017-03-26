local M = {}

local game_ships = {}
local game_player = {} -- also in game_ships
local game_planets = {}
local game_state = {time=0, step = 0.02, prevupdates = 0}

Planet = {} -- Class for planets and suns
function Planet:new()
	local n = {x=0, y=0, size=10, weight=100000, color={255, 255, 255, 255}}
	self.__index = self
	return setmetatable(n, self)
end

function Planet:getFGrav(time, x, y)
	--G * (m1*m2)/(r*r)
	local dx = self.x - x
	local dy = self.y - y
	local dist2 = (dx * dx) + (dy * dy)
	local g = self.weight / dist2
	local fx, fy = 0,0
	local r = math.atan2(self.y - y, self.x - x) - (math.pi / 2)

	if dist2 ~= 0 then
		fx = g * -math.sin(r)
		fy = g * math.cos(r)
	end

	return fx, fy
end

function Planet:draw()
	love.graphics.setLineWidth(2)
	love.graphics.setColor(self.color)
	love.graphics.circle("line", self.x, self.y, self.size)
end

Ship = {} -- Class for ships and rockets
function Ship:new()
	local n = {x=0, y=0, r=0.0, size=6, weight=1, velx=0, vely=0, tpower=60, color={255, 100, 100, 255}}
	self.__index = self
	return setmetatable(n, self)
end

function Ship:draw()
	local frontx = (self.size * -math.sin(self.r)) + self.x
	local fronty = (self.size * math.cos(self.r)) + self.y
	local brx = (self.size * -math.sin(self.r + (math.pi*6/7))) + self.x
	local bry = (self.size * math.cos(self.r + (math.pi*6/7))) + self.y
	local blx = (self.size * -math.sin(self.r + (math.pi*8/7))) + self.x
	local bly = (self.size * math.cos(self.r + (math.pi*8/7))) + self.y
	love.graphics.setLineWidth(1.2)
	love.graphics.setLineStyle("smooth")
	love.graphics.setColor(self.color)
	love.graphics.line(frontx, fronty, brx, bry, blx, bly, frontx, fronty)
end

function Ship:applyForce(fx, fy, dt)
	-- f = ma
	local ax = fx/self.weight
	local ay = fy/self.weight
	-- vf = vi + (a * t)
	self.velx = self.velx + (ax * dt)
	self.vely = self.vely + (ay * dt)
end

function Ship:applyGravity(time, dt)
	local fx, fy = 0,0
	-- for each planet
	for i=1, #game_planets do
		fx, fy = game_planets[i]:getFGrav(time, self.x, self.y)
		self:applyForce(fx, fy, dt)
	end
	
end

function Ship:thrust(amount, dt)
	local ax = 0
	local ay = 0
	-- get the ship direction
	ax = amount * self.tpower * -math.sin(self.r);
	ay = amount * self.tpower * math.cos(self.r);
	self:applyForce(ax, ay, dt)
end

function Ship:move(dt)
	self.x = self.x + (self.velx * dt)
	self.y = self.y + (self.vely * dt)
end


function Ship:predict(time)
	local steps = 900
	local points = {}

	-- save the current state
	local old_x = self.x
	local old_y = self.y
	local old_velx = self.velx
	local old_vely = self.vely

	for i=1, steps*2, 2 do
		-- apply gravity
		self:applyGravity(time + (i*game_state.step), game_state.step)
		-- move
		self:move(game_state.step)
		points[i] = self.x
		points[i+1] = self.y
	end

	-- restore state
	self.x = old_x
	self.y = old_y
	self.velx = old_velx
	self.vely = old_vely

	return points
end

function M.preload()
	math.randomseed(os.time())
	local w, h = love.graphics.getDimensions()
	-- create our main player
	game_player = Ship:new()
	game_player.x = w/3;
	game_player.y = h/2;
	game_ships[#game_ships+1] = game_player

	-- create a planet
	for i=1, 4 do
	local planet = Planet:new()
		planet.x = w * math.random()
		planet.y = h * math.random()
		game_planets[i] = planet
	end

	love.graphics.setBackgroundColor(0,0,0)
end

function M.update(dt)
	-- update time
	game_state.time = game_state.time + dt
	local updates = math.floor(game_state.time / game_state.step) - game_state.prevupdates
	game_state.prevupdates = game_state.prevupdates + updates

	-- controls for the main player
	local mx, my = love.mouse.getPosition()
	game_player.r = math.atan2(my - game_player.y, mx - game_player.x) - (math.pi / 2)
	if love.mouse.isDown(1) then
		-- turn on thrust
		game_player:thrust(0.3, dt)
	end


	for u=0, updates do
		for i=1, #game_ships do
			-- apply gravity forces
			game_ships[i]:applyGravity(game_state.time, dt)
			-- move the ships
			game_ships[i]:move(dt)
		end
	end
end

function M.draw()
	-- predict the player
	local path = game_player:predict(game_state.time)
	print("path" .. #path)
	love.graphics.setLineWidth(.9)
	for i=#path, 4, -2 do
		local val = (#path - i) * (600 / #path)
		love.graphics.setColor(val, val, val)
		love.graphics.line(path[i-1], path[i], path[i-3], path[i-2])
		print(i)
	end

	-- draw all the planets
	for i=1, #game_planets do
		game_planets[i]:draw()
	end

	-- draw all the ships
	for i=1, #game_ships do
		game_ships[i]:draw()
	end
end


return M

--[[ Notes
--  So I need a set of functions. Probably object oriented
--  Game has:
--  	Planets
--  	ships (rockets are ships too)
--  	asteroid fields (can't go there, can't shoot through)
--  Each planet needs :
--  	:getPos(time)
--  		position is a function of time, can be one spot, can be an "orbit"
--  		(planets can't actually orbit dynamically, but they can have static paths)
--	:gravity(time, weight, x, y)
--		gets the pull on a weight positioned at x,y at time
--	:isCollision(time, x, y)
--		gets distance from center to see if it collided
--  Each ship needs :
--  	velocity vector
--  	:move(dt)
--  		actually moves the ship the given amount of time along it's vector
--  	:applyGravity(time, planets)
--  		applies the gravity of each object to the ship
--  	:checkCollide(time, planets, ships)
--  		checks if it hit anything
--  	:isCollision(x,y)
--  		tells if something hit it, if so it also gets hit
--  	:getPath(n, len)
--  		does a bunch of future move,grav calcs, returning points, every nth point up to len
--  		
--  
--  Game Physics:
--  	gravity and movement is called on objects at a set interval. move(), apply_gravity(), ...
--
--  Gameplay
--  	your rockets reload every _ seconds, and you can store _ number of rockets before you max out.
--	mouse to aim
--	click(or space) to shoot
--	other click(or shift) to thrust
--	scroll (w,s) to change thrust power
--	(f) to full power
--
--  Dev Map:
--  	1st step: fly around with gravity
--  		fly around
--  		future path
--  		planets
--  		orbit assist?
--  	2nd step: future paths
--  	3rd step: shoot and die
--  	4th step: generate levels
--  	5th step: make look cool
--  	6th step: add multiplayer
--  	7th step: add bots
--  	8th step: make look cooler
--  	9th step: add possiblies
--
--	possibly ship health?
--	possibly explosions?
--	possibly different weapons? (laser, world destoryer)
--	possibly touch support?
--	possibly levels?
--	possibly capture the flag?
--
--]]
