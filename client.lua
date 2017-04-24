local M = {}

local socket = require("socket")
local net = require("netserial")
local game = require("game")

-- states
local unconnected, running = 0, 1

local client = {sock=nil, port=8910, addr="127.0.0.1", update_period=net.c_utime, timesinceupdate=0.0, recv_period=net.c_rtime, timesincerecv=0.0, state=unconnected}
-- Server's client id is 0, clients are 1 - max
-- serialize updates only send objects with id's with your client number

function M.preload(host, port)
	if port then
		client.port = port
	end
	if host then
		local resolved = socket.dns.toip(host)
		client.addr = resolved[1]
	end

	client.sock = socket.udp()
	client.sock:setpeername(client.addr, client.port)
	client.sock:settimeout(0)
	
	client.sock:send(net.hello)
end

function M.update(dt)
	-- receive any server commands 
	client.timesincerecv = client.timesincerecv + dt
	if client.timesincerecv >= client.recv_period then
		client.timesincerecv = client.timesincerecv - client.recv_period
		local data = client.sock:receive()
		print(data)
		if data then
			print(data)
		end
	end

	-- send out update 
	client.timesinceupdate = client.timesinceupdate + dt
	if client.timesinceupdate >= client.update_period then
		client.timesinceupdate = client.timesinceupdate - client.update_period
	end
	
	local retval = nil
	return retval
end

return M
