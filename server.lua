local M = {}

local socket = require("socket")
local game = require("game")
local net = require("netserial")


local server = {sock=nil, port=8910, clients={}, update_period=net.s_utime, timesinceupdate=0.0, recv_period=net.s_rtime, timesincerecv=0.0, client_counter=1}
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
	-- receive any client commands 
	server.timesincerecv = server.timesincerecv + dt
	if server.timesincerecv >= server.recv_period then
		server.timesincerecv = server.timesincerecv - server.recv_period
		-- receive until there are no waiting packets
		repeat
		local data, ip, port = server.sock:receivefrom()
			if data then

				print(ip ..":".. port .." => ".. data)
				local cmd, msg = data:match("^(%S)(.*)")
				-- process commands
				if cmd == net.hello then
					-- save this client
					server.clients[#server.clients+1] = {ip=ip, port=port}
				end
			end
		until data == nil
	end

	-- run the game's update
	local retval = game.update(dt)
	
	-- send an update out, if it is time
	server.timesinceupdate = server.timesinceupdate + dt
	if server.timesinceupdate >= server.update_period then
		server.timesinceupdate = server.timesinceupdate - server.update_period
		local data = game.serializeDynamic(true)
		for i=1, #server.clients do
			local c = server.clients[i]
			server.sock:sendto(data, c.ip, c.port)
		end
	end
	return retval
end

return M
