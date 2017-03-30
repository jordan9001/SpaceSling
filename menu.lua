local M = {}

local buttons = {}

Button = {}
function Button:new()
	n = {text="", mouseover=false, x=0, y=0, w=0, h=0, color={100,255,100,255}, ret=""}
	self.__index = self
	return setmetatable(n, self)
end

function Button:draw(w, h)
	local mode = "line"
	if self.mouseover then
		mode = "fill"
	end
	love.graphics.setColor(self.color)
	love.graphics.rectangle(mode, self.x*w, self.y*h, self.w*w, self.h*h)
	local color
	if self.mouseover then
		love.graphics.setColor(0,0,0,255)
	end
	
	local rx = ((self.x) * w)
	local ry = ((self.y + (self.h/3)) * h)
	love.graphics.printf(self.text, rx, ry, self.w*w, "center")
end

function Button:mousein(x,y)
	if x < (self.x + self.w) and x > self.x and y < (self.y + self.h) and y > self.y then
		self.mouseover=true
	else
		self.mouseover=false
	end
end

function Button:click()
	return self.ret
end


function M.preload()
	local font = love.graphics.newFont(33)
	love.graphics.setFont(font)
	local game_button = Button:new()
	game_button.text = "Single Player"
	game_button.ret = "game"
	game_button.x = .3
	game_button.w = .4
	game_button.y = .1
	game_button.h = .2
	
	local server_button = Button:new()
	server_button.text = "Host Game"
	server_button.ret = "server"
	server_button.x = .3
	server_button.w = .4
	server_button.y = .4
	server_button.h = .2
	
	local client_button = Button:new()
	client_button.text = "Join Game"
	client_button.ret = "client"
	client_button.x = .3
	client_button.w = .4
	client_button.y = .7
	client_button.h = .2

	buttons = {game_button, server_button, client_button}
end

function M.update(dt)
	local mx, my = love.mouse.getPosition()
	local rw, rh = love.graphics.getDimensions()
	mx = mx/rw
	my = my/rh

	local clicked = love.mouse.isDown(1,2)

	for i=1, #buttons do
		buttons[i]:mousein(mx,my)
		if clicked and buttons[i].mouseover then
			return buttons[i]:click()
		end
	end
end

function M.draw()
	local rw, rh = love.graphics.getDimensions()

	for i=1, #buttons do
		buttons[i]:draw(rw, rh)
	end
end

return M
