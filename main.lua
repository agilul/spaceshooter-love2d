vector = require "lib.vector"
Entity = require "entity"
steering = require "steering"


function love.load()
	math.randomseed(os.time())

	player = Entity(love.window.getWidth()/2, love.window.getHeight()/2, "assets/playership.png")
	lasers = {}
	bombs = {}
	enemies = {}
	
	-- repeating background tile
	background = love.graphics.newImage("assets/black.png")
	background:setWrap("repeat", "repeat")
	bgQuad = love.graphics.newQuad(0, 0, love.window.getWidth(), love.window.getHeight(), background:getWidth(), background:getHeight())
	
	weaponInterval = 0
	weaponRoF = 8
	
	enemySpawnChance = 0.01
	
	instructions = true
	instructionsTimeout = 10
end

function love.update(dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
	
	local mouse = {position = vector(love.mouse.getPosition())}
	
	-- make enemies "pursue" the player and keep some distance between themselves
	for i, v in ipairs(enemies) do
		v.acceleration = 0.6 * steering.pursue(v, player, 100, 3) + 0.4 * steering.separation(v, enemies, 20, 10000, 100)
		_, v.angularAcceleration = steering.lookWhereYoureGoing(v, 10, 2, 0.01, 1, 0.1)
	end
	
	-- player movement controls
	local inputVelocity = vector(0, 0)
	
	if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
		inputVelocity.y = -1
	elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then
		inputVelocity.y = 1
	end
	
	if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
		inputVelocity.x = -1
	elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
		inputVelocity.x = 1
	end
	
	inputVelocity = inputVelocity:rotated(player.orientation) * 100
	player.acceleration = steering.velocityMath(player, {velocity = inputVelocity}, 100, 0.1)
	_, player.angularAcceleration = steering.face(player, mouse, 10, 2, 0.01, 1, 0.1)
	
	-- player weapon controls
	if weaponInterval > 0 then
		weaponInterval = weaponInterval - dt
	end
	if love.mouse.isDown("l") then
		if weaponInterval <= 0 then
			local laser = Entity(player.position.x, player.position.y, "assets/laser1.png")
			laser.orientation = player.orientation
			laser.speed = 400
			laser.velocity = vector(math.sin(laser.orientation), -math.cos(laser.orientation)) * laser.speed
			lasers[#lasers+1] = laser
			weaponInterval = 1/weaponRoF
		end
	end
	
	-- enemy spawner
	if math.random() < enemySpawnChance then
		if math.random() < 0.1 then
			local smallX, smallY = math.random(0, 800), math.random(0, 600)
			for i=1,10 do
				enemies[#enemies+1] = Entity(smallX + math.random(-50, 50), smallY + math.random(-50, 50), "assets/smallenemy.png")
			end
		else
			enemies[#enemies+1] = Entity(math.random(0, 800), math.random(0, 600), "assets/enemy" .. math.random(5) .. ".png")
		end
	end
	
	player:update(dt)
	
	for i = #lasers, 1, -1 do
		lasers[i]:update(dt)
		if lasers[i]:isOutOfBounds() then 
			table.remove(lasers, i)
		end
	end
	
	for i = #enemies, 1, -1 do
		enemies[i]:update(dt)
		if enemies[i]:isOutOfBounds() then
			table.remove(enemies, i)
			enemySpawnChance = enemySpawnChance + 0.001
		end
	end
	
	for i = #bombs, 1, -1 do
		bombs[i]:update(dt)
		bombs[i].timer = bombs[i].timer - dt
		if bombs[i].timer < 0 then
			for j = #enemies, 1, -1 do
				if bombs[i].position:dist(enemies[j].position) < bombs[i].radius then
					enemies[j].speed = 1000
					-- blast enemies off screen
					enemies[j].velocity = (-bombs[i].position + enemies[j].position):normalizeInplace() * enemies[j].speed
				end
			end
			table.remove(bombs, i)
		elseif bombs[i]:isOutOfBounds() then 
			table.remove(bombs, i) -- destroy out-of-bounds bombs
		end
	end
	
	-- simple collision check between lasers and enemies
	for i = #lasers, 1, -1 do
		for j = #enemies, 1, -1 do
			if lasers[i].position:dist(enemies[j].position) < enemies[j].width/2 then
				table.remove(lasers, i)
				table.remove(enemies, j)
				enemySpawnChance = enemySpawnChance + 0.001
				break
			end
		end
	end
	
	if instructions then
		if instructionsTimeout < 0 then
			instructions = false
		end
		instructionsTimeout = instructionsTimeout - dt
	end
end

function love.mousepressed(x, y, button)
	if button == "r" then
		local bomb = Entity(player.position.x, player.position.y, "assets/bomb1.png")
		local direction = vector(x, y) - player.position
		bomb.orientation = math.atan2(direction.x, -direction.y)
		bomb.speed = 200
		bomb.velocity = vector(math.sin(bomb.orientation), -math.cos(bomb.orientation)) * bomb.speed
		bomb.timer = direction:len() / bomb.speed
		bomb.radius = 100
		bombs[#bombs+1] = bomb
	end
end

function love.draw()
	love.graphics.draw(background, bgQuad, 0, 0)

	player:draw()
	
	for _, v in ipairs(lasers) do
		v:draw()
	end
	
	for _, v in ipairs(bombs) do
		v:draw()
	end
	
	for _, v in ipairs(enemies) do
		v:draw()
	end

	love.graphics.print("FPS: " .. love.timer.getFPS())

	if instructions then
		love.graphics.printf("WASD to move\nMouse to turn\nLeft Click to shoot lasers\nRight Click to throw a bomb\nESC to exit", 0, 15, love.window.getWidth(), "left", 0, 2)
	end
end