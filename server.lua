local M = {}

local socket = require("socket")
local nc = require("netcommands")
local game = require("game")

local server = {sock=nil, port, clients={}, update_period=0.2, timesinceupdate}

function M.preload(port)
	if port == nil then
		port = 8910
	end

	server.sock = sock.udp()
	server.sock:setsockname('*', port)
	server.sock:settimeout(0)

	-- preload the game
end

function M.update(dt)
	-- receive any client commands 
	data, ip, port = server.sock:receivefrom()

	-- handle any specific requests

	-- run the game's update
	game.update(dt)
	
	-- send an update out, if it is time

end

return M
