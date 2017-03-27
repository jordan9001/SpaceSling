local M = {}

local game_ships = {}
local game_player = {} -- also in game_ships
local game_planets = {}
local game_explosions = {}
local game_state = {time=0, step = 0.02, prevupdates = 0, w=0, h=0}


local function explode(group, index)
	-- add a new explosion at that spot
	local e = Explosion:new()
	e.x = group[index].x
	e.y = group[index].y
	e.color = group[index].color
	e.size = group[index].size
	e.endsize = e.size * 9
	e:setK()
	game_explosions[#game_explosions+1] = e
	-- removes object
	local item = group[index]
	if item == game_player then
		game_player = nil
	end
	for i=index, #group do
		group[i] = group[i+1]
	end
end

local function collideEdge(x, y)
	if (x > game_state.w or x < 0) or (y > game_state.h or y < 0) then
		return true
	end
	return false
end

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

function Planet:collide(x, y)
	local dx = self.x - x
	local dy = self.y - y
	local dist2 = (dx * dx) + (dy * dy)
	
	if dist2 < (self.size * self.size) then
		return true
	end
	return false
end

function Planet:draw()
	love.graphics.setLineWidth(2)
	love.graphics.setColor(self.color)
	love.graphics.circle("fill", self.x, self.y, self.size)
end

Ship = {} -- Class for ships and rockets
function Ship:new()
	local n = {x=0, y=0, r=0.0, size=6, weight=1, velx=0, vely=0, health=100, tpower=60, color={100, 255, 100, 255}}
	self.__index = self
	return setmetatable(n, self)
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

function Ship:collide(x, y)
	local dx = self.x - x
	local dy = self.y - y
	local dist2 = (dx * dx) + (dy * dy)
	
	if dist2 < (self.size * self.size) then
		return true
	end
	return false
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
		-- get collisions
		local hit = false
		if collideEdge(self.x, self.y) then
			hit = true
			break
		end
		for j=1, #game_planets do
			if game_planets[j]:collide(self.x, self.y) then
				hit = true
				break
			end
		end
		if hit then break end
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

function Ship:draw()
	local frontx = (self.size * -math.sin(self.r)) + self.x
	local fronty = (self.size * math.cos(self.r)) + self.y
	local brx = (self.size * -math.sin(self.r + (math.pi*6/7))) + self.x
	local bry = (self.size * math.cos(self.r + (math.pi*6/7))) + self.y
	local blx = (self.size * -math.sin(self.r + (math.pi*8/7))) + self.x
	local bly = (self.size * math.cos(self.r + (math.pi*8/7))) + self.y
	love.graphics.setLineWidth(1.2)
	love.graphics.setColor(self.color)
	love.graphics.line(frontx, fronty, brx, bry, blx, bly, frontx, fronty)
end

Explosion = {}
function Explosion:new()
	local n = {x=0, y=0, size=10, time=0, k=0, growtime=1.0, endsize=30, totaltime=3.0, fade=1.0, color={255,0,0,255}}
	self.__index = self
	return setmetatable(n, self)
end

function Explosion:setK()
	self.k = (self.size - self.endsize) / (self.growtime * self.growtime)
end

function Explosion:collide(x, y)
	local dx = self.x - x
	local dy = self.y - y
	local dist2 = (dx * dx) + (dy * dy)
	
	if dist2 < (self.size * self.size) then
		return true
	end
	return false
end

function Explosion:update(dt)
	self.time = self.time + dt
	if self.time < self.growtime then
		self.size = (self.k * ((self.time - self.growtime)*(self.time - self.growtime))) + self.endsize
	end
	if self.time < self.totaltime then
		self.fade = ((self.totaltime - self.time) / self.totaltime)
	else
		-- remove this item
		local found = false
		for i=0, #game_explosions do
			if self == game_explosions[i] then
				found = true
			end
			if found == true then
				game_explosions[i] = game_explosions[i+1]
			end
		end
		self = nil
	end

end

function Explosion:draw(x, y)
	love.graphics.setLineWidth(4)
	local centercolor = {self.color[1], self.color[2], self.color[3], self.color[4]}
	centercolor[4] = centercolor[4] * self.fade

	love.graphics.setColor(255, 0, 0, 255*self.fade)
	love.graphics.circle("line", self.x, self.y, self.size)
	love.graphics.setColor(centercolor)
	love.graphics.circle("fill", self.x, self.y, self.size* 5/6)
end

function M.preload()
	math.randomseed(os.time())

	local w, h = love.graphics.getDimensions()
	-- our game works on it's own coord system, apart from pixels
	if w > h then
		h = 1000 * (h/w)
		w = 1000
	else
		w = 1000 * (w/h)
		h = 1000
	end

	game_state.w = w
	game_state.h = h
	-- create our main player
	game_player = Ship:new()
	game_player.x = w/2;
	game_player.y = h/2;
	game_ships[#game_ships+1] = game_player

	-- create a planet
	local pnum = 4 + math.floor(math.random() * 9)
	for i=1, pnum do
		local planet = Planet:new()
		planet.x = w * math.random()
		planet.y = h * math.random()
		planet.size = (4 + (math.random() * 24))
		planet.weight = planet.size * planet.size * 900
		game_planets[i] = planet
	end

	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.setLineStyle("smooth")
end

function M.update(dt)
	-- update time
	game_state.time = game_state.time + dt
	local updates = math.floor(game_state.time / game_state.step) - game_state.prevupdates
	game_state.prevupdates = game_state.prevupdates + updates

	-- controls for the main player
	if game_player ~= nil then
		local mx, my = love.mouse.getPosition()
		local rw, rh = love.graphics.getDimensions()
		mx = game_state.w * mx/rw
		my = game_state.h * my/rh
		
		game_player.r = math.atan2(my - game_player.y, mx - game_player.x) - (math.pi / 2)
		if love.mouse.isDown(1) then
			-- turn on thrust
			game_player:thrust(0.3, dt)
		end
	end

	for u=0, updates do
		-- update explosions
		for i=1, #game_explosions do
			game_explosions[i]:update(dt)
		end

		-- update ships
		for i=1, #game_ships do
			local dead = false
			-- apply gravity forces
			game_ships[i]:applyGravity(game_state.time, dt)
			-- move the ships
			game_ships[i]:move(dt)

			-- get out of bounds
			if collideEdge(game_ships[i].x, game_ships[i].y) then
				explode(game_ships, i)
				dead = true
				break
			end
			-- get collision with explosions
			for j=1, #game_explosions do
				if game_explosions[j]:collide(game_ships[i].x, game_ships[i].y) then
					explode(game_ships, i)
					dead = true
					break
				end
			end
			if dead then break end
			-- get collisions with ships
			for j=i+1, #game_ships do
				if game_ships[j]:collide(game_ships[i].x, game_ships[i].y) then
					explode(game_ships, j)
					explode(game_ships, i)
					dead = true
					break
				end
			end
			if dead then break end
			-- get collisions with planets
			for j=1, #game_planets do
				if game_planets[j]:collide(game_ships[i].x, game_ships[i].y) then
					explode(game_ships, i)
					dead = true
					break
				end
			end
		end
	end
end

function M.draw()
	-- scale and translate
	local rw, rh = love.graphics.getDimensions()
	local scale = rw/game_state.w
	local xpad, ypad = 0, 0
	if scale > rh/game_state.h then
		scale = rh/game_state.h
		xpad = (rw - (game_state.w * scale))/2
	else
		ypad = (rh - (game_state.h * scale))/2
	end
	love.graphics.translate(xpad, ypad)
	love.graphics.scale(scale, scale)

	-- draw borders
	love.graphics.setLineWidth(1)
	love.graphics.setColor(255,255,255,255)
	love.graphics.rectangle("line", 0, 0, game_state.w, game_state.h)

	-- predict the player
	if game_player ~= nil then
		local path = game_player:predict(game_state.time)
		love.graphics.setLineWidth(1)
		for i=#path, 4, -2 do
			local val = (#path - i) * (3.0 / #path)
			local color = {game_player.color[1], game_player.color[2], game_player.color[3], game_player.color[4] * val}
			love.graphics.setColor(color)
			love.graphics.line(path[i-1], path[i], path[i-3], path[i-2])
		end
	end

	-- draw all the planets
	for i=1, #game_planets do
		game_planets[i]:draw()
	end

	-- draw all the ships
	for i=1, #game_ships do
		game_ships[i]:draw()
	end

	-- draw all the explosions
	for i=1, #game_explosions do
		game_explosions[i]:draw()
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
