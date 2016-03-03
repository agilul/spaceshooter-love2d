Class = require "lib.class"
vector = require "lib.vector"

Entity = Class{
	init = function(self, x, y, img)
		self.position = vector(x, y)
		self.image = love.graphics.newImage(img)
		self.width = self.image:getWidth()
		self.height = self.image:getHeight()
		self.velocity = vector(0, 0)
		self.acceleration = vector(0, 0)
		self.speed = 100 -- default speed cap
		self.orientation = 0
		self.rotation = 0
		self.angularAcceleration = 0
	end
}

function Entity:update(dt)
	-- Newton-Euler integration method
	self.position = self.position + self.velocity * dt
	self.orientation = self.orientation + self.rotation * dt
	
	self.velocity = self.velocity + self.acceleration * dt
	self.rotation = self.rotation + self.angularAcceleration * dt
	
	-- cap max speed
	if self.velocity:len2() > self.speed * self.speed then
		self.velocity:normalizeInplace()
		self.velocity = self.velocity * self.speed
	end
	
	-- orientation should be in [0, 2*PI] range
	while self.orientation > 2 * math.pi do
		self.orientation = self.orientation - 2 * math.pi
	end
end

function Entity:draw()
	love.graphics.draw(self.image, self.position.x, self.position.y, self.orientation, 1, 1, self.width/2, self.height/2)
end

function Entity:isOutOfBounds()
	return self.position.x < 0 or self.position.x > love.window.getWidth() or self.position.y < 0 or self.position.y > love.window.getHeight()
end

return Entity