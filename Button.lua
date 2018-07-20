Button = createClass({
	--static things
	size = 0.05,
},
function(self, filename, x, y, type, disabled)
	self.sprite = love.graphics.newImage('res/buttons/' .. filename)
	self.selector = Selector.create(self)
	self.x = x
	self.y = y
	self.width, self.height = self.sprite:getDimensions()
	self.state = nil
	self.selected = false
	self.type = type --normal, instant
	self.enabled = not disabled
end)

function Button:update()
	if self.state==nil or self.state=='released' then
		if Game.hasMouseClicked(1) then
			self:tryPress()
		end
	else
		if not love.mouse.isDown(1) then
			self:tryRelease()
		end
	end
end

function Button:draw(x, y)
	x = x or 0
	y = y or 0
	Selector.sendId(self.selector)
	Game.setShader()
	local x, y = Field.getScreenPosition(self.x+x, self.y+y)
	local scale = Button.size*Screen.height/self.height
	if not self.enabled then
		love.graphics.setColor(127, 127, 127, 127)
	elseif (self.state=='pressed' or self.state=='justPressed') and Selector.isObject(self) then
		love.graphics.setColor(127, 127, 127, 255)
	end
	love.graphics.draw(self.sprite, x, y, 0, scale, nil, self.width/2, self.height/2)
	
	if self.selected then
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.rectangle('line', x-scale*self.width/2, y-scale*self.height/2, scale*self.width, scale*self.height)
		love.graphics.rectangle('line', x-scale*self.width/2-1, y-scale*self.height/2-1, scale*self.width+2, scale*self.height+2)
	end
	love.graphics.setColor(255, 255, 255, 255)
end

function Button:tryPress()
	if Selector.isObject(self) and self.enabled then
		self.state = 'justPressed'
	else
		self.state = nil
	end
end

function Button:tryRelease()
	if Selector.isObject(self) then
		self.state = 'released'
	else
		self.state = nil
	end
end

function Button:wasPressed()
	if self.type=='normal' then
		if self.state=='justPressed' then
			self.state = 'pressed'
		end
		if self.state=='released' then
			self.state = nil
			return true
		end
		
	elseif self.type=='instant' then
		if self.state=='justPressed' then
			self.state = 'pressed'
			return true
		end
	end
	
	return false
end

function Button:setSelected(selected)
	self.selected = selected
end

function Button:enable()
	self.enabled = true
end

function Button:disable()
	self.enabled = false
end









