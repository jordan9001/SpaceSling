local M = {}

local socket = require("socket")

local server = {sock=nil, port, clients={}}

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

	-- run the game's update
	
	-- send an update out

end
