M = {}
-- commands
M.getStatic = "g" -- = request for static objects, also registers the client to server
M.updateStatic = "s" -- = updates static objects
M.updateDynamic = "d" -- = updates, adds, or removes ships and explosions
M.hello = "h" -- = client announce presance
M.err = "e" -- = some error happened

-- types
M.explosiontag = "ex"
M.shiptag = "sp"
M.bullettag = "bl"
M.planettag = "pt"

-- other constants
M.s_utime = 0.2
M.c_utime = 0.2
M.s_rtime = 0.05
M.c_rtime = 0.1

return M
