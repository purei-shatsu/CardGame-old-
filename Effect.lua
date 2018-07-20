Effect = createClass({
	--static things
},
function(self, property)
	self.condition = property.condition
	self.operation = property.operation
	if property.event then
		--trigger effect
		if type(property.event)=='table' then
			self.event = property.event
		else
			self.event = {property.event}
		end
	else
		--ignition effect
		self.event = nil
	end
	
	self.description = property.description
	self.used = false
	self.virtual = nil
	self.state = {}
end)

function Effect:reset()
	self:setUsed(false)
end

function Effect:checkEvent(event)
	--check ignition effect
	if self.event==nil or event==nil then
		return self.event==event
	end
	
	--turn event into table
	if type(event)~='table' then
		event = {event}
	end
	
	--check if there is at least one match
	local flag = {}
	for i,e in ipairs(self.event) do
		flag[e] = true
	end
	for i,e in ipairs(event) do
		if flag[e] then
			return true
		end
	end
	return false
end

function Effect:canActivate(event, ...)
	return self:checkEvent(event) and not self:isUsed() and (not self.condition or self.condition(...))
end

function Effect:activate(...)
	self:setUsed(true)
	return self.operation(...)
end

function Effect:setUsed(used)
	if Match.isAIMode() then
		self.virtual.used = used
	else
		self.used = used
	end
end

function Effect:isUsed()
	if Match.isAIMode() then
		return self.virtual.used
	else
		return self.used
	end
end

function Effect:createState()
	--create initial state
	self.state[1] = {
		used = self.used,
	}
	
	--set virtual to new state
	self.virtual = self.state[1]
end

function Effect:destroyState()
	--destroy all states
	self.state = {}
	
	--unset virtual
	self.virtual = nil
end

function Effect:saveState()
	--copy virtual to new state
	self.state[#self.state+1] = {}
	for i,v in pairs(self.virtual) do
		self.state[#self.state][i] = v
	end
	
	--set virtual to new state
	self.virtual = self.state[#self.state]
end

function Effect:loadState()
	--destroy current state
	self.state[#self.state] = nil
	
	--set virtual to old state
	self.virtual = self.state[#self.state]
end















