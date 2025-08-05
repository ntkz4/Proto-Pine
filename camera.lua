local camera = {}

function camera.load()
	camera.x = 0
	camera.y = 0
end

function camera.update(targetX, targetY)
	local screenWidth = love.graphics.getWidth()
	local screenHeight = love.graphics.getHeight()

	-- get mouse position (screen space)
	local mouseX, mouseY = love.mouse.getPosition()

	-- calculate offset from screen center
	local offsetX = (mouseX - screenWidth / 2) * 0.25 -- tweak 0.25 for less/more drift
	local offsetY = (mouseY - screenHeight / 2) * 0.25

	-- set camera position with offset
	camera.x = targetX - screenWidth / 2 + offsetX
	camera.y = targetY - screenHeight / 2 + offsetY
end

function camera.attach()
	love.graphics.push()
	love.graphics.translate(-camera.x, -camera.y)
end

function camera.detach()
	love.graphics.pop()
end

return camera
