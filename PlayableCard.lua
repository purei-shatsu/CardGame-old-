PlayableCard = createClass({
	speed = 2.0,
	angularSpeed = 0.25,
	listingSize = 0.2,
},
function(self, id, side, pos, deck)
	self.card = Game.getCard(id)
	self.side = side
	self.location = 'deck'  --hand, deck, discard, damage, table, PlayableCard
	self.position = pos --position on its location
	self.grabbed = false
	self.mouseDx = nil
	self.mouseDy = nil
	self.activating = false
	self.bound = false
	self.disabled = false
	self.revealed = false
	self.deck = deck --other cards
	self.x, self.y, self.z, self.angle, self.face = self:getDestination()
	self.selector = Selector.create(self)
	self.effect = {}
	self.state = {}
	self.unknown = false
	self.virtual = nil
	self.interface = CardInterface:new(self)
	self.card:executeScript(self.interface)
end)

function PlayableCard:update(dt)
	local destX, destY, destZ, destA, destF = self:getDestination()
	self.face = destF --TODO make flip gradual
	
	if self.fixed then
		--fix card at position
		destX, destY, destZ = self.fixed[1], self.fixed[2], self.fixed[3]
		if self.side==2 then
			destX = -destX
			destY = -destY
		end
	end
	
	--gradual rotation
	local da = destA-self.angle
	while da>math.pi do
		da = da - 2*math.pi
	end
	while da<-math.pi do
		da = da + 2*math.pi
	end
	if math.abs(da)>PlayableCard.angularSpeed then
		da = PlayableCard.angularSpeed*math.abs(da)/da
	end
	self.angle = self.angle + da
	
	if self.grabbed then
		--card is being grabbed
		self.x, self.y = Game.getMousePosition()
		self.x = self.x + self.mouseDx
		self.y = self.y + self.mouseDy
		self.x = self.x*Screen.proportion
		self.z = destZ
		return
	end
	
	if self:isComponent() and self:getLocation():isGrabbed() then
		--is component and parent is being grabbed
		self.x, self.y, self.z, self.angle = destX, destY, destZ, destA
		return
	end
	
	--gradual movement
	local dx = destX-self.x
	local dy = destY-self.y
	local dz = destZ-self.z
	local dist = (dx^2 + dy^2 + dz^2)^0.5
	if dist>0 then
		local speed = math.min(dist, PlayableCard.speed*dt)
		dx = dx*speed/dist
		dy = dy*speed/dist
		dz = dz*speed/dist
		self.x = self.x + dx
		self.y = self.y + dy
		self.z = self.z + dz
	end
end

function PlayableCard:draw()
	--draw card image
	if self:isGrabbed() then
		--if is grabbed, or parent is grabbed, become unclickable
		Selector.sendId(0)
	else
		Selector.sendId(self.selector)
	end
	self.card:draw(self.x, self.y, self.z, self.angle, self.face)
	
	--[[
	--draw attacking arrow
	if self.attacking then
		Selector.sendId(0)
		local x, y = Field.getScreenPosition(self.x, self.y)
		local mx, my = Game.getMousePosition()
		local mx = (mx + 0.5)*Screen.width
		local my = (my + 0.5)*Screen.height
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.line(x, y, mx, my)
		love.graphics.setColor(255, 255, 255, 255)
	end
	--]]
end

function PlayableCard:drawFusing(order)
	Selector.sendId(0)
	love.graphics.setColor(255, 255, 255, 200)
	self.card:drawFusing(self.x, self.y, self.z, order)
	love.graphics.setColor(255, 255, 255, 255)
end

function PlayableCard:drawListing(x, y)
	local size = PlayableCard.listingSize
	x, y = Field.getScreenPosition(x, y)
	self.card:drawFloat(x, y, size)
end

function PlayableCard:getDestination()
	local x, y, z, angle, face = Field.getDrawPos(self.side, self.location, self.position, self.bound, self.disabled, #self:getComponents())
	if self.revealed then
		face = 'up'
	end
	return x, y, z, angle, face
end

function PlayableCard:getCoordinates()
	return self.x, self.y, self.z, self.angle, self.face
end

local function samePosition(c, self)
	return c~=self and c:getPosition()==self:getPosition()
end

function PlayableCard:removeFromLocation()
	if self:getLocation()~='table' then
		--update other cards positions
		local other = table.filter(self.deck, PlayableCard.isLocation, self:getLocation(), true)
		if not table.exists(other, samePosition, self) then
			other = table.filter(other, PlayableCard.maxPosition, self)
			table.update(other, PlayableCard.decreasePosition)
		end
	end
end

function PlayableCard:getEmptyPosition(location)
	local other = table.filter(self.deck, PlayableCard.isLocation, location, true)
	local occupied = {}
	for i,c in ipairs(other) do
		occupied[c:getPosition()] = true
	end
	local position = 1
	while occupied[position] do
		position = position + 1
	end
	return (location~='table' or position<=5) and position
end

function PlayableCard:addToLocation(location, position)
	local previousLocation = self:getLocation()
	self:setLocation(nil)
	local other = table.filter(self.deck, PlayableCard.isLocation, location, true)
	if position then
		self:setPosition(position)
		if location~='table' then
			other = table.filter(other, PlayableCard.maxPosition, self)
			table.update(other, PlayableCard.increasePosition)
		end
	else
		self:setPosition(self:getEmptyPosition(location))
	end
	self:setLocation(location)
	
	--if location changed, reset effects
	if previousLocation~=location then
		self:resetEffects()
	end
	
	--become known if moved out of deck or to an specific deck position
	if self:getLocation()~='deck' or position then
		self:setUnknown(false)
	end
end

function PlayableCard:sendTo(location, position)
	self:removeFromLocation()
	self:addToLocation(location, position)
	return self:isLocation(location) and (not position or self:isPosition(position))
end

function PlayableCard.minPosition(a, b)
	return a:getPosition()<=b:getPosition()
end

function PlayableCard.maxPosition(a, b)
	return a:getPosition()>=b:getPosition()
end

function PlayableCard.drawOrder(a, b)
	local x1, y1, z1 = a.x, a.y, a.z
	local x2, y2, z2 = b.x, b.y, b.z
	return z1<z2 or (z1==z2 and (y1<y2 or (y1==y2 and x1<x2)))
end

function PlayableCard:isLocation(location, ungrabbed)
	if class(location)~='table' then
		location = {location}
	end
	
	for i,l in ipairs(location) do
		if self:getLocation()==l and (not ungrabbed or not self:isGrabbed()) then
			return true
		end
	end
	return false
end

function PlayableCard:isPosition(position)
	if class(position)~='table' then
		position = {position}
	end
	for i,p in ipairs(position) do
		if self:getPosition()==p then
			return true
		end
	end
	return false 
end

function PlayableCard:isSide(side)
	return self.side==side
end

function PlayableCard:decreasePosition()
	self:setPosition(self:getPosition()-1)
end

function PlayableCard:increasePosition()
	self:setPosition(self:getPosition()+1)
end

function PlayableCard:reachedDestination()
	local x,y,z,a,f = self:getDestination()
	return self.x==x and self.y==y and self.z==z and self.angle==a and self.face==f
end

function PlayableCard:reachDestination()
	if Match.isAIMode() then
		--don't wait on AIMode
		return
	end
	coroutine.yield(function()
		return self:reachedDestination()
	end)
end

function PlayableCard:setPosition(position)
	if Match.isAIMode() then
		self.virtual.position = position
	else
		self.position = position
	end
end

function PlayableCard:setLocation(location)
	if Match.isAIMode() then
		self.virtual.location = location
	else
		self.location = location
	end
end

function PlayableCard:tryGrab()
	if not self:isBound() and not self:isDisabled() then
		self:grab()
		return self
	end
	return false
end

function PlayableCard:grab(center)
	self.grabbed = true
	if center then
		self.mouseDx = 0
		self.mouseDy = 0
	else
		self.mouseDx, self.mouseDy = Game.getMousePosition()
		self.mouseDx = self.x/Screen.proportion - self.mouseDx
		self.mouseDy = self.y - self.mouseDy
	end
	self:removeFromLocation()
end

function mfilter(c, tp, level)
	return c:isSide(tp) and c:isLocation('table') and c:getCard():getLevel()<level and not c:isDisabled()
end

function ffilter(c, mg, used, level, elem)
	if used[c] then
		return false
	end
	local card = c:getCard()
	local cl = card:getLevel()
	local ce1 = card:getElement1()
	local ce2 = card:getElement2()
	
	used[c] = true
	local ret
	if cl<level then
		ret = (elem==nil or ce1==elem) and table.exists(mg, ffilter, mg, used, level-cl, ce2)
	else
		ret = cl==level and (elem==nil or ce1==elem)
	end
	used[c] = nil
	
	return ret
end

function PlayableCard:canFusionPlay()
	--level 1
	if self.card:getLevel()==1 then
		return false
	end
	
	--test components
	local mg = table.filter(Game.getMatch():getCards(), mfilter, self:getSide(), self.card:getLevel())
	return table.exists(mg, ffilter, mg, {}, self.card:getLevel())
end

function PlayableCard:chooseComponents()
	local match = Game.getMatch()
	local level = self:getCard():getLevel()
	local elem = nil
	local mg = table.filter(Game.getMatch():getCards(), mfilter, self:getSide(), level)
	local used = {}
	local fusing = {}
	
	while level>0 do
		--choose next component
		local sg = match:chooseFromList(self.side, 'Choose component:', table.filter(mg, ffilter, mg, used, level, elem), 1, 1)
		sc = sg[1]
		used[sc] = true
		fusing[#fusing+1] = sc
		
		--update requirements
		level = level - sc:getCard():getLevel()
		elem = sc:getCard():getElement2()
	end
	
	return fusing
end

function PlayableCard:fix(x, y, z)
	x = x or self.x
	y = y or self.y
	z = z or self.z
	self.fixed = {x, y, z}
end

function PlayableCard:unfix()
	self.fixed = false
end

function PlayableCard:ungrab()
	local location, position, side, card = Field.getLocation(self.x, self.y)
	--change position to empty zone if playing level 1 over occupied
	if card and self.card:getLevel()==1 and location=='table' and self.location~='table' then
		local p = self:getEmptyPosition('table')
		if p then
			card = nil
			position = p
		end
	end
	
	self.grabbed = false
	
	---------------------------RESTRICTIONS-----------------------------
	local notMove = 
		--invalid place (outside game)
		(not location) or
		
		--opponent's side
		(side~=self.side) or
		
		--not table or hand
		(location~='table' and location~='hand') or
		
		--not hand to hand
		(self.location~='hand' and location=='hand') or
		
		--level 1 from outside table to occupied table zone
		(location=='table' and self.location~='table' and card and self.card:getLevel()==1) or
		
		--level>1 from outside table to table without valid fusion
		(location=='table' and self.location~='table' and self.card:getLevel()>1 and not self:canFusionPlay()) or
		
		--move swap with bound/disabled card
		(self.location=='table' and location=='table' and card and (card:isBound() or card:isDisabled())) or
		
		--level 0 [TODO arrumar isso com nova interface]
		((self.card:getLevel()==0 and location=='table') and (
			--unoccupied zone
			(not card) or
			--invalid fusion
			(self.card:getElement2()~=card:getCard():getElement1() and self.card:getElement1()~=card:getCard():getElement2())
		))
	--------------------------------------------------------------------
	
	local ret
	local finish = true
	if notMove then
		--move to previous location if unable to move
		location = self.location
		position = self.position
	else
		if location=='table' and self.location~='table' and self.card:getLevel()>1 then
			--choose fusion components
			self:fix(-0.32, 0.25, 0)
			local comp = self:chooseComponents()
			self:unfix()
			self:fusion(comp)
			
			--check if playing over non-component card
			if card then
				local notComp = true
				for i,cp in ipairs(comp) do
					if card==cp then
						notComp = false
						break
					end
				end
				if notComp then
					position = self:getEmptyPosition('table')
				end
			end
			
			ret = 'fusion'
		elseif location=='table' and self.card:getLevel()==0 then
			local left = self.card:getElement2()==card:getCard():getElement1()
			local right = self.card:getElement1()==card:getCard():getElement2()
			if left and right then
				--TODO let user choose
				card:fusion({self}, 'left')
			elseif left then
				card:fusion({self}, 'left')
			else --right
				card:fusion({self}, 'right')
			end
			finish = false
		elseif location=='table' and card then
			--swap if zone is occupied
			card:addToLocation(self.location, self.position)
		end
	end
	
	if finish then
		--finish movement
		self:addToLocation(location, position)
	end
	return ret
end

function PlayableCard:finishMove(...)
	local location, position, side, card = Field.getLocation(self.x, self.y)
	
	---------------------------RESTRICTIONS-----------------------------
	local notMove = 
		--invalid place (outside game)
		(not location) or
		
		--opponent's side
		(side~=self.side) or
		
		--not table
		(location~='table') or
		
		--occupied table zone
		(card)
	--------------------------------------------------------------------
	
	if not notMove then
		self.grabbed = false
		self:addToLocation(location, position)
		if ... then
			self:scheduleEvent('move', ...)
		end
		return true
	end
	return false
end

function PlayableCard:scheduleEvent(event, ...)
	if Match.isAIMode() then
		return --TODO program this later (skipping all events in the AI for now)
	end
	local match = Game.getMatch()
	match:scheduleEvent(self, event, ...)
end

function PlayableCard:triggerEvent(event, ...)
	--can't activate effects if disabled (except "On disable" effects)
	if self:isDisabled() and event=='disable' then
		return
	end
	
	--check if at least one effect can be activated
	local effect = table.filter(self.effect, Effect.canActivate, event, self.interface, ...)
	if #effect==0 then
		return
	end
	
	--activate trigger effects
	for i,e in ipairs(effect) do
		--TODO let user decide (yes/no) for each effect
		coroutine.yield(function()
			--TODO draw animation
			return true
		end)
		e:activate(self.interface, ...)
	end
end

function PlayableCard:tryActivate()
	if not self:isDisabled() then
		self.activating = true
		return self
	end
	return false
end

function PlayableCard:finishActivation()
	self.activating = false
	
	--check if mouse still over card
	if Selector.getObject()~=self then
		return
	end
	
	--check if at least one effect can be activated
	local effect = table.filter(self.effect, Effect.canActivate, nil, self.interface)
	if #effect==0 then
		return
	end
	
	--choose and activate one effect
	local e = effect[1] --TODO let user choose (and possibly cancel)
	self:activateAI(e)
end

function PlayableCard:tryAttack()
	if self:canBeAttacked() then
		return self
	end
	return false
end

function PlayableCard:finishAttack()
	self:attackAI()
end

function PlayableCard:fusion(component, zero)
	coroutine.yield(function()
		--TODO draw animation
		return true
	end)
	
	local pc
	for i,c in ipairs(component) do
		--add component
		self:charge(c)
		
		--reset component status
		c:resetStatus()
		
		--schedule fusion events
		if pc then
			pc:scheduleEvent('fusion_' .. Card.element[pc:getCard():getElement2()], self)
			c:scheduleEvent('fusion_' .. Card.element[c:getCard():getElement1()], self)
		end
		pc = c
	end
	
	--treat level 0 fusion
	if zero then
		local c
		if zero=='left' then
			pc = component[1]
			c = self
		elseif zero=='right' then
			pc = self
			c = component[1]
		end
		pc:scheduleEvent('fusion_' .. Card.element[pc:getCard():getElement2()], self)
		c:scheduleEvent('fusion_' .. Card.element[c:getCard():getElement1()], self)
	end
end

function PlayableCard:tryInfo()
	if self.face=='up' or self:isDisabled() or not self:isSelectDirect() then
		--card if face up, disabled (does not hide info) or hovered in a list
		return self.card
	end
	return nil
end

function PlayableCard:resetStatus()
	if not Match.isAIMode() then
		self.grabbed = false
	end
	self:setBound(false)
	self:setDisabled(false)
end

function PlayableCard:playAI(component)
	local ret
	if component then
		self:fusion(component)
		ret = 'fusion'
	end
	self:play(self:getEmptyPosition('table'))
	self:reachDestination()
	return ret
end

function PlayableCard:activateAI(effect)
	if not Match.isAIMode() then
		coroutine.yield(function()
			--TODO draw animation
			return true
		end)
	end
	effect:activate(self.interface)
	Game.getMatch():reachDestination()
end

function PlayableCard:moveAI(zone)
	local sc = zone:getPlayableCard()
	if sc then
		--swap if zone is occupied
		sc:addToLocation('table', self:getPosition())
	end
	self:addToLocation('table', zone:getPosition())
end

function PlayableCard:attackAI()
	if not Match.isAIMode() then
		coroutine.yield(function()
			--TODO draw animation
			return true
		end)
	end
	
	local match = Game.getMatch()
	if self:isLocation('deck') then
		--attacking the deck
		match:damage(self.side)
		
		--return
		if Match.isAIMode() then
			return 0, 1
		end
	else
		--attacking a card
		local level = self:getCard():getLevel()
		local levelDiff = 0
		
		--defeat target
		local subsT = self:defeat(false)
		levelDiff = levelDiff + level - (subsT and subsT:getCard():getLevel() or 0)
		if Match.isAIMode() then
			return levelDiff, 1
		end
	end
	self:reachDestination()
	return true
end

function PlayableCard:bind(...)
	if not self:isLocation('table') then
		--not on table
		return false
	end
	
	if self:isBound() or self:isDisabled() then
		--already bound or disabled
		return false
	end
	
	self:setBound(true)
	self:scheduleEvent('bind', ...)
	--self:reachDestination()
	return true
end

function PlayableCard:unbind(...)
	if not self:isBound() then
		--not bound
		return false
	end
	
	self:setBound(false)
	self:scheduleEvent('unbind', ...)
	--self:reachDestination()
	return true
end

function PlayableCard:disable(cooldown, ...)
	if self:isDisabled() then
		--already disabled
		return false
	end
	
	self:resetStatus()
	self:setDisabled(cooldown)
	self:scheduleEvent('disable', ...)
	--self:reachDestination()
	return true
end

function PlayableCard:tryEnable()
	local cooldown = self:isDisabled()
	if cooldown and cooldown.condition and cooldown.condition(self.interface, unpack(cooldown.param)) then
		self:enable()
	end
end

function PlayableCard:enable(...)
	if not self:isDisabled() then
		--not disabled
		return false
	end
	
	self:resetStatus()
	self:setDisabled(false)
	self:scheduleEvent('enable', ...)
	--self:reachDestination()
	return true
end

function PlayableCard:charge(c)
	if c:getCard():getLevel()>=self:getCard():getLevel() then
		--can't charge if component level is above parent
		return false
	end
	
	--charge component
	c:sendTo(self)
	
	--charge component's components
	for i,cc in ipairs(c:getComponents()) do
		self:charge(cc)
	end
	
	return true
end

local function validSubstitute(c)
	return c:getCard():getLevel()>=1
end

function PlayableCard:leaveTable(bound)
	if not self:isLocation('table') then
		--not on table
		return false
	end
	
	--substitute
	local subs
	if table.exists(self:getComponents(), validSubstitute) then
		--choose and play
		local match = Game.getMatch()
		local chosen = match:chooseFromList(self.side, 'Choose substitute:', table.filter(self:getComponents(), validSubstitute), 1, 1)
		local substitute = chosen[1]
		substitute:setBound(bound or self:isBound())
		substitute:sendTo('table', self:getPosition())
		
		--add components
		for i,c in ipairs(self:getComponents()) do
			if c:getCard():getLevel()<substitute:getCard():getLevel() then
				--charge
				substitute:charge(c)
			else
				--discard
				c:sendTo('discard')
			end
		end
		
		subs = substitute
	else
		--discard all components
		for i,c in ipairs(self:getComponents()) do
			--discard
			c:sendTo('discard')
		end
	end
	self:resetStatus()
	
	return subs
end

function PlayableCard:defeat(bound, ...)
	local subs = self:leaveTable(bound)
	self:sendTo('damage')
	self:scheduleEvent('defeat', ...)
	--self:reachDestination()
	
	--draw on defeat
	Game.getMatch():drawCard(self.side)
	
	return subs
end

function PlayableCard:destroy(...)
	if not self:isLocation('table') then
		return false --only cards on table can be destroyed
	end
	self:leaveTable()
	self:sendTo('discard')
	self:scheduleEvent('destroy', ...)
	--self:reachDestination()
	return true
end

function PlayableCard:discard(...)
	self:leaveTable()
	if self:sendTo('discard') then
		self:scheduleEvent('discard', ...)
		--self:reachDestination()
		return true
	end
	return false
end

function PlayableCard:damage(...)
	self:leaveTable()
	if self:sendTo('damage') then
		self:scheduleEvent('damage', ...)
		--self:reachDestination()
		return true
	end
	return false
end

function PlayableCard:shuffle(...)
	self:leaveTable()
	if self:sendTo('deck') then
		self:scheduleEvent('shuffle', ...)
		Game.getMatch():shuffleDeck(self.side)
		--self:reachDestination()
		return true
	end
	return false
end

function PlayableCard:add(...)
	self:leaveTable()
	if self:sendTo('hand') then
		self:scheduleEvent('add', ...)
		--TODO reveal card
		Game.getMatch():shuffleHand(self.side)
		--self:reachDestination()
		return true
	end
	return false
end

function PlayableCard:play(position, ...)
	if self:sendTo('table', position) then
		self:scheduleEvent('play', ...)
		--self:reachDestination()
		return true
	end
	return false
end

function PlayableCard:reveal(...)
	self.revealed = true
	self:scheduleEvent('reveal', ...)
	return true
end

function PlayableCard:unreveal(...)
	self.revealed = false
	self:scheduleEvent('unreveal', ...)
	return true
end

function PlayableCard:resetEffects()
	for i,e in ipairs(self.effect) do
		e:reset()
	end
end

function PlayableCard:canBeAttacked()
	--disabled or not on table/deck
	if self:isDisabled() or not self:isLocation({'table', 'deck'}) then
		return false
	end
	
	--in protected backrow
	if (self:isLocation('deck') or self:getPosition()>3) and not Game.getMatch():canAttackBackrow(self.side) then
		return false
	end
	
	return true
end

function PlayableCard:canAttack()
	return not self:isBound() and not self:isDisabled() and self:isLocation('table')-- and self:getPosition()<=3
end

function PlayableCard:isBound()
	if Match.isAIMode() then
		return self.virtual.bound
	else
		return self.bound
	end
end

function PlayableCard:isDisabled()
	if Match.isAIMode() then
		return self.virtual.disabled
	else
		return self.disabled
	end
end

function PlayableCard:isComponent()
	return class(self:getLocation())==PlayableCard
end

function PlayableCard:isSelectDirect()
	return Selector.isId(self.selector)
end

function PlayableCard:isGrabbed()
	return self.grabbed or (self:isComponent() and self:getLocation():isGrabbed())
end

function PlayableCard:getSelector()
	return self.selector
end

function PlayableCard:getLocation()
	return Match.isAIMode() and self.virtual.location or self.location
end

function PlayableCard:getPosition()
	return Match.isAIMode() and self.virtual.position or self.position
end

function PlayableCard:getSide()
	return self.side
end

function PlayableCard:getCard()
	return self:isUnknown() and Card.unknown or self.card
end

function PlayableCard:getComponents()
	--returns a copy of the components
	local component = table.filter(self.deck, PlayableCard.isLocation, self)
	table.sort(component, PlayableCard.minPosition)
	return component
end

function PlayableCard:getInterface()
	return self.interface
end

function PlayableCard:setBound(bound)
	if Match.isAIMode() then
		self.virtual.bound = bound
	else
		self.bound = bound
	end
end

function PlayableCard:setDisabled(disabled)
	if Match.isAIMode() then
		self.virtual.disabled = disabled
	else
		self.disabled = disabled
	end
end

function PlayableCard:setUnknown(unknown, ignoreAI)
	--card can't become known while AI is thinking (unless it made a play that chooses that card) (can become unknown, though)
	if not Match.isAIMode() or ignoreAI or unknown then
		--AI cannot be reset while thinking
		if not Match.isAIMode() and self.unknown~=unknown then
			AI.resetDP()
		end
		
		if Match.isAIMode() then
			self.virtual.unknown = unknown
		else
			self.unknown = unknown
		end
	end
end

function PlayableCard:isUnknown()
	return Match.isAIMode() and not Match.isKnownMode() and self.virtual.unknown
end

function PlayableCard:tostring()
	return '{' .. '\n' ..
		'\t' .. 'side = ' .. tostring(self.side) .. '\n' ..
		'\t' .. 'location = ' .. tostring(self.location) .. '\n' ..
		'\t' .. 'position = ' .. tostring(self.position) .. '\n' ..
		'\t' .. 'face = ' .. tostring(self.face) .. '\n' ..
		'\t' .. 'grabbed = ' .. tostring(self:isGrabbed()) .. '\n' ..
		'\t' .. 'x = ' .. tostring(self.x) .. '\n' ..
		'\t' .. 'y = ' .. tostring(self.y) .. '\n' ..
		'\t' .. 'z = ' .. tostring(self.z) .. '\n' ..
	'}'
end

function PlayableCard:addEffect(effect)
	self.effect[#self.effect+1] = effect
	return true
end

function PlayableCard:getEffects()
	local effect = {}
	for i,e in ipairs(self.effect) do
		effect[i] = e
	end
	return effect
end

function PlayableCard:resetMatch()
	self:sendTo('deck')
	self:resetEffects()
	self:resetStatus()
end

function PlayableCard:createState()
	--create initial state
	self.state[1] = {
		location = self.location,
		position = self.position,
		bound = self.bound,
		disabled = self.disabled,
		unknown = self.unknown,
	}
	
	--set virtual to new state
	self.virtual = self.state[1]
	
	--create state for effects
	for i,e in ipairs(self.effect) do
		e:createState()
	end
end

function PlayableCard:destroyState()
	--destroy all states
	self.state = {}
	
	--unset virtual
	self.virtual = nil
	
	--destroy state for effects
	for i,e in ipairs(self.effect) do
		e:destroyState()
	end
end

function PlayableCard:saveState()
	--copy virtual to new state
	self.state[#self.state+1] = {}
	for i,v in pairs(self.virtual) do
		self.state[#self.state][i] = v
	end
	
	--set virtual to new state
	self.virtual = self.state[#self.state]
	
	--save state for effects
	for i,e in ipairs(self.effect) do
		e:saveState()
	end
end

function PlayableCard:loadState()
	--destroy current state
	self.state[#self.state] = nil
	
	--set virtual to old state
	self.virtual = self.state[#self.state]
	
	--load state for effects
	for i,e in ipairs(self.effect) do
		e:loadState()
	end
end
























