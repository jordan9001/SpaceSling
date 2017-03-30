local M = {}

local game_ships = {}
local game_player = {} -- also in game_ships
local game_planets = {}
local game_explosions = {}
local game_state = {time=0, step = 0.02, prevupdates = 0, w=0, h=0, iditer=0}


local function explode(group, index)
	-- add a new explosion at that spot
	local e = Explosion:new()
	e.x = group[index].x
	e.y = group[index].y
	e.color = group[index].color
	e.size = group[index].size
	e.endsize = group[index].explosionsize
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

local function drawPath(path, color_orig, fade_start, fade_end)
	local color = {color_orig[1], color_orig[2], color_orig[3], color_orig[4]}
	local orig_fade = color[4]
	local m = (fade_end - fade_start) / (#path)
	for i=#path, 4, -2 do
		local fade = (m*i) + fade_start
		color[4] = orig_fade * fade
		love.graphics.setColor(color)
		love.graphics.line(path[i-1], path[i], path[i-3], path[i-2])
	end
end

Weapon = {} -- Class for weapons
function Weapon:new()
	local n = {weight=0.03, size=5, vel=450, explosionsize=66, rockets=0.0, maxrockets=3, reloadtime=3.0, cooldown=0.0, maxcooldown=0.3, color={100,100,255,255}}
	self.__index = self
	return setmetatable(n, self)
end

called = 0
function Weapon:update(dt)
	called = called + 1
	if self.cooldown > 0 then
		self.cooldown = self.cooldown - dt
	end
	if self.rockets < self.maxrockets then
		self.rockets = self.rockets + (dt/self.reloadtime)
	end
end

function Weapon:fire(x, y, velx, vely, dist, rot)
	if self.rockets > 1.0 and self.cooldown <= 0 then
		self.cooldown = self.maxcooldown
		self.rockets = self.rockets - 1

		local r = Bullet:new()
		r.wep = nil
		r.weight = self.weight
		r.size = self.size
		r.explosionsize = self.explosionsize
		r.color = self.color
		r.r = rot

		local vix = self.vel * -math.sin(rot)
		local viy = self.vel * math.cos(rot)
		r.velx = velx + vix
		r.vely = vely + viy

		-- move it away from us by dist
		local z = math.sqrt((dist*dist) / ((vix*vix) + (viy*viy))) + 0.01
		r.x = x + (vix * z)
		r.y = y + (viy * z)

		-- add it to the global group of ships
		game_ships[#game_ships+1] = r
	end
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
	local n = {x=0, y=0, r=0.0, size=9, weight=1, velx=0, vely=0, tpower=120, color={100, 255, 100, 255}, explosionsize=30, wep=nil, id={client=0, num=0}}
	n.id.num = game_state.iditer
	game_state.iditer = game_state.iditer + 1
	self.__index = self
	return setmetatable(n, self)
end

function Ship:update(dt)
	-- apply gravity forces
	self:applyGravity(game_state.time, dt)
	-- move the ships
	self:move(dt)
	-- reload
	if self.wep ~= nil then
		self.wep:update(dt)
	end
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

function Ship:fire()
	if self.wep ~= nil then
		self.wep:fire(self.x, self.y, self.velx, self.vely, self.size, self.r)
	end
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

Bullet = Ship:new() -- Bullet inherits from ship
function Bullet:new()
	n = {trail={}, traillen=150}
	self.__index = self
	return setmetatable(n, self)
end

function Bullet:move(dt)
	self.x = self.x + (self.velx * dt)
	self.y = self.y + (self.vely * dt)
	self.trail[#self.trail+1] = self.x
	self.trail[#self.trail+1] = self.y
end

function Bullet:draw()
	-- draw path
	love.graphics.setLineWidth(0.5)
	drawPath(self.trail, self.color, 0.0, 1.2)
	-- draw rocket
	local fx = (self.size * -math.sin(self.r)) + self.x
	local fy = (self.size * math.cos(self.r)) + self.y
	local bx = (self.size * math.sin(self.r)) + self.x
	local by = (self.size * -math.cos(self.r)) + self.y
	love.graphics.setLineWidth(3)
	love.graphics.setColor(self.color)
	love.graphics.line(fx, fy, bx, by)
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
	--math.randomseed(42)
	math.randomseed(os.time())

	game_ships = {}
	game_planets = {}
	game_explosions = {}

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
	game_player.wep = Weapon:new()
	game_ships[#game_ships+1] = game_player

	-- create a planet
	local pnum = 6 + math.floor(math.random() * 9)
	for i=1, pnum do
		local planet = Planet:new()
		planet.x = w * math.random()
		planet.y = h * math.random()
		planet.size = (2 + (math.random() * 27))
		planet.weight = planet.size * planet.size * planet.size * 45
		game_planets[i] = planet
	end

	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.setLineStyle("smooth")
end

function M.update(dt)
	if game_player == nil then
		return "menu"
	end

	-- update time
	game_state.time = game_state.time + dt
	local updates = math.floor(game_state.time / game_state.step) - game_state.prevupdates
	game_state.prevupdates = game_state.prevupdates + updates

	-- controls for the main player
	if game_player ~= nil then
		-- rotation
		local mx, my = love.mouse.getPosition()
		local rw, rh = love.graphics.getDimensions()
		mx = game_state.w * mx/rw
		my = game_state.h * my/rh
		game_player.r = math.atan2(my - game_player.y, mx - game_player.x) - (math.pi / 2)
		-- thrust
		if love.mouse.isDown(1) then
			-- turn on thrust
			game_player:thrust(0.3, dt)
		end
		-- fire
		if love.keyboard.isDown("space") then
			game_player:fire()
		end
	end

	for u=1, updates do
		-- update explosions
		for i=#game_explosions, 1, -1 do
			game_explosions[i]:update(dt) -- bad stuff happens
		end

		-- update ships
		local i=1
		while i <= #game_ships do

			local dead = false
			-- update internal works
			game_ships[i]:update(dt)

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
				if game_ships[j]:collide(game_ships[i].x, game_ships[i].y) or game_ships[i]:collide(game_ships[j].x, game_ships[j].y) then
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

			i = i+1
		end
	end
	return nil
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
		drawPath(path, game_player.color, 3.0, 0.1)
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
--
--  TODO:
--  	multiplayer
--  	shaders
--  	asteroid fields
--  	level creator
--  	different planets/ black holes
--  	bots
--  	levels
--  	ctf/race/capture/other modes
--  	weapons (laser, shotgun, mine)
--	powerups
--  	story
--  	touch support
--]]
