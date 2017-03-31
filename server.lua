local M = {}

local socket = require("socket")
local game = require("game")


local server = {sock=nil, port=8910, clients={}, update_period=0.1, timesinceupdate=0.0, client_counter=1}
-- Server's client id is 0, clients are 1 - max
-- serialize updates only send objects with id's with your client number

function M.preload(port)
	if port ~= nil then
		server.port = port
	end

	server.sock = sock.udp()
	server.sock:setsockname('*', server.port)
	server.sock:settimeout(0)

	-- preload the game
	-- TODO
end

function M.update(dt)
	server.timesinceupdate = server.timesinceupdate + dt
	-- receive any client commands 
	data, ip, port = server.sock:receivefrom()

	-- handle any specific requests
	-- TODO

	-- run the game's update
	game.update(dt)
	
	-- send an update out, if it is time
	if server.timesinceupdate >= server.update_period then
		server.timesinceupdate -= server.update_period
		local data = "test" --TODO 
		for i=0, #server.clients do
			local ip = server.clients[i]
			server.sock:sendto(data, ip, server.port)
		end
	end
end

return M
