local M = {}

-- gs = get static objects, also registers the client (client sent)
-- ad = add a dynamic object (client sent)
-- us = update static, gives the full game static object state
-- ud = update dynamic, gives the dynamic game state
M.cmds = {"gs", "ad", "us", "ud"}

return M

-- [[
-- So clients will have a set of dynamic objects that they don't update
-- but send their own updates to the server for
-- ]]
