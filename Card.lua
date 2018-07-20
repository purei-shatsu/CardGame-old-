Card = createClass({
	--static things
	digits = {
		sprite = love.graphics.newImage('res/digits.png'),
		quad = {},
	},
	spriteDown = love.graphics.newImage('res/pics/down.png'),
	element = {'earth', 'sky', 'water', 'fire'},
},
function(self, query)
	query = '|' .. query .. '|'
	_,_,self.id,self.level,self.element1,self.element2,self.name,self.archetype,self.effect,self.code = query:find("|(.-)|(.-)|(.-)|(.-)|(.-)|(.-)|(.-)|(.-)|")
	self.id = tonumber(self.id)
	self.level = tonumber(self.level)
	self.element1 = tonumber(self.element1)
	self.element2 = tonumber(self.element2)
	if self.id then
		self.sprite = {
			up = love.graphics.newImage('res/pics/' .. self.id .. '.png'),
			down = Card.spriteDown,
		}
	end
	
	if self.code and not Match.noEffects then
		--load script file
		local scriptFile = io.open('scripts/' .. self.code .. '.lua')
		if scriptFile then
			scriptFile:close()
			self.script = require('scripts/' .. self.code)
		else
			--print('Error: script "' .. self.code .. '" not found.')
		end
	end
end)
local amount = 5
Card.digits.width = Card.digits.sprite:getWidth()/amount
Card.digits.height = Card.digits.sprite:getHeight()
for i=0,amount-1 do
	Card.digits.quad[i+1] = love.graphics.newQuad(Card.digits.width*i, 0, Card.digits.width, Card.digits.height, Card.digits.sprite:getWidth(), Card.digits.sprite:getHeight())
end
Card.width, Card.height = Card.spriteDown:getDimensions()
Card.proportion = Card.height/Card.width
Card.unknown = Card:new('')

function Card:getId()
	return self.id
end

function Card:getCode()
	return self.code
end

function Card:getWidth()
	return Card.width
end

function Card:getHeight()
	return Card.height
end

function Card:getLevel()
	return self.level
end

function Card:getElement1()
	return self.element1
end

function Card:getElement2()
	return self.element2
end

function Card:executeScript(c)
	if self.script then
		self.script(c)
	end
end

function Card:isFusion(component)
	if #component<2 then
		--less than two components
		return false
	end
	
	local level = 0
	local element = component[1]:getElement1()
	for i,c in ipairs(component) do
		if element~=c:getElement1() then
			--component elements don't match
			return false
		end
		element = c:getElement2()
		level = level + c:getLevel()
	end
	
	if level~=self.level then
		--total component level is not equal to result level
		return false
	end
	
	return true
end

function Card:tostring()
	return self.id .. '\t' .. self.level .. '\t' .. self.element1 .. '\t' .. self.element2 .. '\t' .. self.name .. '\t' .. self.archetype .. '\t' .. self.effect
end

function Card:draw(x, y, z, angle, face)
	Game.setShader(y)
	x, y = Field.getScreenPosition(x,y)
	Game.shaderSend('cz', z)
	local scale = 0.18*Screen.height/Card.height
	love.graphics.draw(self.sprite[face], x, y, angle, scale, nil, Card.width/2, Card.height/2)
	Game.shaderSend('cz', 0)
end

function Card:drawFusing(x, y, z, order)
	Game.setShader(y)
	x, y = Field.getScreenPosition(x,y)
	Game.shaderSend('cz', z)
	local scale = 0.07*Screen.height/Card.digits.height
	love.graphics.draw(Card.digits.sprite, Card.digits.quad[order], x, y, 0, scale, nil, Card.digits.width/2, Card.digits.height/2)
	love.graphics.circle('line', x, y, scale*Card.digits.height/2)
	Game.shaderSend('cz', 0)
end

function Card:drawFloat(x, y, size)
	Game.setShader()
	local scale = size*Screen.height/Card.height
	love.graphics.draw(self and self.sprite.up or Card.spriteDown, x, y, 0, scale, nil, Card.width/2, Card.height/2)
end















