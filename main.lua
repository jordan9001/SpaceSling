local game = require('game')

-- Load some default values for our rectangle.
function love.load()
	game.preload()
end
 
-- Increase the size of the rectangle every frame.
function love.update(dt)
	game.update(dt)
end
 
-- Draw a coloured rectangle.
function love.draw()
	game.draw()
end




