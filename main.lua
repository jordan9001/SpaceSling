local game = require('game')
local server = require('server')
local client = require('client')
local menu = require('menu')

local current_state = "menu"
local update_function = nil

-- Load the draw function and state we want
function love.load()
	menu.preload()
	update_function = menu.update
	love.draw = menu.draw
end
 
-- Run the correct update function
function love.update(dt)
	n = update_function(dt)
	if n ~= nil then
		-- go to the next
		if n == "game" then
			game.preload()
			update_function = game.update
			love.draw = game.draw
		elseif n == "menu" then
			menu.preload()
			update_function = menu.update
			love.draw = menu.draw
		elseif n == "server" then
			server.preload()
			update_function = server.update
			love.draw = game.draw
		elseif n == "client" then
			client.preload()
			update_function = client.update
			--love.draw = game.draw
		end
	end
end
 
