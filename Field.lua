Field = {}

function Field.initialize()
	Field.selector = {}
	for i=1,2 do
		Field.selector[i] = {
			table = {},
			damage = Selector.create(),
			discard = Selector.create(),
		}
		for j=1,6 do
			Field.selector[i].table[j] = Selector.create()
		end
	end
	
	Field.location = {}
	for i=1,2 do
		local sel = Field.selector[i].damage
		Field.location[sel] = {
			location = 'damage',
			position = nil,
			side = i,
		}
		
		sel = Field.selector[i].discard
		Field.location[sel] = {
			location = 'discard',
			position = nil,
			side = i,
		}
		
		for j=1,5 do
			sel = Field.selector[i].table[j]
			Field.location[sel] = {
				location = 'table',
				position = j,
				side = i,
			}
		end
		sel = Field.selector[i].table[6]
		Field.location[sel] = {
			location = 'deck',
			position = nil,
			side = i,
		}
	end
end

local thickness = {
	deck = 1e-2/2,
	component = 1e-1/3,
}
local dmgDist = 4
local semiZero = 1e-10
function Field.getDrawPos(side, location, position, bound, disabled, components)
	local x,y,z,angle,face
	if location=='hand' then
		local handSize = Game.getMatch():getHandSize(side)
		x = position*100/(handSize+1)
		y = 60
		z = 0
		angle = 0
		face = disabled and 'down' or 'up'
	end
	
	if location=='deck' then
		x = 69
		y = 37
		z = (position-1)*thickness.deck
		angle = 0
		face = 'down'
	end
	
	if location=='table' then
		local i=math.floor((position-1)/3)
		local j=(position-1)%3
		x = 31 + j*19
		y = 18 + i*19
		z = components*semiZero
		angle = (bound or disabled) and -math.pi/2 or 0
		face = disabled and 'down' or 'up'
	end
	
	if location=='discard' then
		x = 92
		y = 37
		z = (position-1)*thickness.deck
		angle = 0
		face = disabled and 'down' or 'up'
	end
	
	if location=='damage' then
		x = 8
		y = 37 - (position-1)*dmgDist
		z = (position-1)*semiZero
		angle = side==1 and -math.pi/2 or math.pi/2
		face = disabled and 'down' or 'up'
	end
	
	if class(location)==PlayableCard then --is a component
		local parent = location
		local components = #parent:getComponents()
		if parent:isGrabbed() then
			x, y, z, angle, face = parent:getCoordinates()
		else
			x, y, z, angle, face = parent:getDestination()
		end
		
		--rotate components is parent is rotated
		if angle==0 then
			if components>1 then
				y = y - (position-(components+1)/2)*thickness.component/(components-1)
			end
			angle = math.pi/2
		else
			if components>1 then
				x = x - (position-(components+1)/2)*thickness.component/(components-1)
			end
			angle = 0
		end
		
		z = (components-position)*semiZero
		face = 'up'
		return x, y, z, angle, face
	else
		--correct pos based on side
		if side==1 then
			return   x/100-0.5,   y/100, z, angle, face
		else --2
			return -(x/100-0.5), -y/100, z, angle--[[+math.pi]], face
		end
	end
end

function Field.getSelectedSpace(selector)
	local selTable = Field.location[selector]
	if not selTable then
		return
	end
	return selTable.location, selTable.position, selTable.side
end

local function selectorFilter(c, location, position, side)
	return c:isLocation(location, true) and c:isPosition(position) and c:isSide(side)
end
function Field.getLocation(x, y)
	local match = Game.getMatch()
	if y<0 then
		--x = -x --isso buga a ordenação da mão do player 2
	end
	
	if y<-0.5 or y>0.5 then --hand
		if y>0.5 then --player 1
			local handSize = match:getHandSize(1)
			for i=1,handSize do
				local hx, hy, hz = Field.getDrawPos(1, 'hand', i, handSize)
				if hx>x then
					return 'hand', i, 1
				end
			end
			return 'hand', handSize+1, 1
		else --player 2
			local handSize = match:getHandSize(2)
			for i=1,handSize do
				local hx, hy, hz = Field.getDrawPos(2, 'hand', i, handSize)
				if hx<x then
					return 'hand', i, 2
				end
			end
			return 'hand', handSize+1, 2
		end
	else --everywhere else
		local sel = Selector.getId()
		local location, position, side = Field.getSelectedSpace(sel)
		local card
		if not location then
			card = Selector.getObject()
			if class(card)==PlayableCard then
				location = card:getLocation()
				position = card:getPosition()
				side = card:getSide()
			end
		end
		if location then
			if not card then
				local cards = match:getCards()
				card = table.filter(cards, selectorFilter, location, position, side)[1]
			end
			return location, position, side, card
		end
	end
end

local function drawRectangle(x, y, width, height, selector, fill)
	Selector.sendId(selector)
	if not fill then
		for i=0,2,0.5 do
			love.graphics.rectangle('line', x-i, y-i, width+2*i, height+2*i, (width+2*i)/10)
		end
		love.graphics.setColor(0,0,0,1)
		love.graphics.rectangle('fill', x, y, width, height, width/10)
	else
		love.graphics.rectangle('fill', x, y, width, height, width/10)
	end
	love.graphics.setColor(255,255,255,255)
end

function Field.draw()
	Game.setShader('table')
	for p=1,2 do
		local selector = Field.selector[p]
		
		--rotate for player 2
		if p==2 then
			love.graphics.push()
			love.graphics.translate(Screen.width/2, Screen.height/2)
			love.graphics.rotate(math.pi)
			love.graphics.translate(-Screen.width/2, -Screen.height/2)
		end
		
		--table
		local width = 0.18*Screen.height
		local height = 0.18*Screen.height
		for i=0,1 do
			for j=0,2 do
				if i~=1 or j~=2 then
					local x = -28 + j*19
					local y = 9 + i*19
					x, y = Field.getScreenPosition(x/100, y/100)
					drawRectangle(x, y, width, height, selector.table[i*3+j+1])
				end
			end
		end
		
		--discard pile
		local x = 33
		local y = 28
		local width = 0.18*Screen.height
		local height = 0.18*Screen.height
		x, y = Field.getScreenPosition(x/100, y/100)
		drawRectangle(x, y, width, height, selector.discard)
		
		--damage
		local x = -51
		local y = -23
		local width = 0.18*Screen.height
		local height = (0.46-y/100)*Screen.height
		x, y = Field.getScreenPosition(x/100, y/100)
		drawRectangle(x, y, width, height, selector.damage)
		
		--undo rotation
		if p==2 then
			love.graphics.pop()
		end
	end
end

function Field.getScreenPosition(x, y)
	x = x*Screen.height + Screen.width/2
	y = (y + 0.5)*Screen.height
	return x, y
end

function Field.getGamePosition(x, y)
	x = (x - Screen.width/2)/Screen.height
	y = y/Screen.height - 0.5
	return x, y
end
















