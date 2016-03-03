vector = require "lib.vector"

steering = {}

function steering.seek(character, target, maxAcceleration)
	return (target.position - character.position):normalizeInplace() * maxAcceleration, 0
end

function steering.flee(character, target, maxAcceleration)
	return (character.position - target.position):normalizeInplace() * maxAcceleration, 0
end

function steering.arrive(character, target, maxAcceleration, maxSpeed, targetRadius, slowRadius, timeToTarget)
	local direction = target.position - character.position
	local distance = direction:len()
	
	if distance < targetRadius then
		return vector(0, 0), 0
	end
	
	local targetSpeed = maxSpeed
	if distance < slowRadius then
		targetSpeed = targetSpeed * distance / slowRadius
	end
	
	direction:normalizeInplace()
	direction = direction * targetSpeed
	
	local linear = direction - character.velocity
	linear = linear / timeToTarget
	
	if linear:len2() > maxAcceleration * maxAcceleration then
		linear:normalizeInplace()
		linear = linear * maxAcceleration
	end
	
	return linear, 0
end

function steering.align(character, target, maxAngularAcceleration, maxRotation, targetRadius, slowRadius, timeToTarget)
	local rotation = target.orientation - character.orientation
	if rotation > 0 then
		rotation = math.fmod(rotation + math.pi, 2 * math.pi) - math.pi
	else
		rotation = math.fmod(rotation - math.pi, 2 * math.pi) + math.pi
	end
	local rotationSize = math.abs(rotation)
	
	if rotationSize < targetRadius then
		return vector(0, 0), 0
	end
	
	local targetRotation = maxRotation
	if rotationSize < slowRadius then
		targetRotation = targetRotation * rotationSize / slowRadius
	end
	
	targetRotation = targetRotation * rotation / rotationSize
	
	local angular = targetRotation - character.rotation
	angular = angular / timeToTarget
	
	local angularAcceleration = math.abs(angular)
	if angularAcceleration > maxAngularAcceleration then
		angular = angular / angularAcceleration * maxAngularAcceleration
	end
	
	return vector(0, 0), angular
end

function steering.velocityMath(character, target, maxAcceleration, timeToTarget)
	local linear = target.velocity - character.velocity
	linear = linear / timeToTarget
	
	if linear:len2() > maxAcceleration * maxAcceleration then
		linear:normalizeInplace()
		linear = linear * maxAcceleration
	end
	
	return linear, 0
end
	
function steering.pursue(character, target, maxAcceleration, maxPrediction)
	local direction = target.position - character.position
	local distance = direction:len()
	
	local speed = character.velocity:len()
	
	local prediction = maxPrediction
	if speed > distance / maxPrediction then
		prediction = distance / speed
	end
	
	local targetPosition = target.position + target.velocity * prediction
	
	return steering.seek(character, {position = targetPosition}, maxAcceleration)
end

function steering.evade(character, target, maxAcceleration, maxPrediction)
	local direction = target.position - character.position
	local distance = direction:len()
	
	local speed = character.velocity:len()
	
	local prediction = maxPrediction
	if speed > distance / maxPrediction then
		prediction = distance / speed
	end
	
	local targetPosition = target.position + target.velocity * prediction
	
	return steering.flee(character, {position = targetPosition}, maxAcceleration)
end

function steering.face(character, target, maxAngularAcceleration, maxRotation, targetRadius, slowRadius, timeToTarget)
	local direction = target.position - character.position
	
	if direction:len2() == 0 then
		return vector(0, 0), 0
	end
	
	local targetOrientation = math.atan2(direction.x, -direction.y)
	
	return steering.align(character, {orientation = targetOrientation}, maxAngularAcceleration, maxRotation, targetRadius, slowRadius, timeToTarget)
end	

function steering.lookWhereYoureGoing(character, maxAngularAcceleration, maxRotation, targetRadius, slowRadius, timeToTarget)
	if character.velocity:len2() == 0 then
		return vector(0, 0), 0
	end
	
	local targetOrientation = math.atan2(character.velocity.x, -character.velocity.y)
	
	return steering.align(character, {orientation = targetOrientation}, maxAngularAcceleration, maxRotation, targetRadius, slowRadius, timeToTarget)
end

function steering.separation(character, targets, threshold, decayCoefficient, maxAcceleration)
	local linear = vector(0, 0)
	
	for i, v in ipairs(targets) do
		if character ~= v then
			local direction = character.position - v.position
			local distance = direction:len()
			if distance < threshold then
				local strength = math.min(decayCoefficient / (distance * distance), maxAcceleration)
				direction:normalizeInplace()
				linear = linear + direction * strength
			end
		end
	end
	
	return linear, 0
end

return steering