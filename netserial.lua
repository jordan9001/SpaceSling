M = {}
-- commands
M.getStatic = "gs" -- = request for static objects, also registers the client to server
M.updateStatic = "us" -- = updates static objects
M.updateDynamic = "ud" -- = updates, adds, or removes ships and explosions

M.explosiontag = "ex"
M.shiptag = "sp"
M.bullettag = "bl"
M.Planettag = "pt"

return M

-- Ok, so a bit of network reasoning
-- Only create an explosion for a ship if you own the ship
--
--server calls game update
--just get all dynamic objects 10 times a second or so, and send them out
