local M = {}

local socket = require("socket")
local game = require("game")


local server = {sock=nil, port=8910, clients={}, update_period=3.0, timesinceupdate=0.0, client_counter=1}
-- Server's client id is 0, clients are 1 - max
-- serialize updates only send objects with id's with your client number

function M.preload(port)
	if port ~= nil then
		server.port = port
	end

	server.sock = socket.udp()
	server.sock:setsockname('*', server.port)
	server.sock:settimeout(0)

	-- preload the game
	game.preload()
end

function M.update(dt)
	server.timesinceupdate = server.timesinceupdate + dt
	-- receive any client commands 
	local data, ip, port = server.sock:receivefrom()

	-- handle any specific requests
	-- TODO

	-- run the game's update
	local retval = game.update(dt)
	
	-- send an update out, if it is time
	if server.timesinceupdate >= server.update_period then
		server.timesinceupdate = server.timesinceupdate - server.update_period
		local data = game.serializeDynamic(true)
		print(data)
		for i=1, #server.clients do
			local ip = server.clients[i]
			server.sock:sendto(data, ip, server.port)
		end
	end
	return retval
end

return M
