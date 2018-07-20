CardInterface = createClass({
	--static things
},
function(self, pcard)
	self.pcard = pcard
	self.card = pcard:getCard()
end,
'CardInterface')

----------------------------CARDS PROPERTIES----------------------------

--returns card location/parent
function CardInterface:getLocation()
	local location = self.pcard:getLocation()
	if class(location)==PlayableCard then
		location = location:getInterface()
	end
	return location
end

--returns if card is in location
function CardInterface:isLocation(location)
	checkParameters('isLocation',
			{location},
			{'string'})
	return self:getLocation()==location
end

--returns card position
function CardInterface:getPosition()
	return self.pcard:getPosition()
end

--returns if card is in position
function CardInterface:isPosition(position)
	checkParameters('isPosition',
			{position},
			{'number'})
	return self.pcard:isPosition(position)
end

--returns card side
function CardInterface:getSide()
	return self.pcard:getSide()
end

--returns if card is in side
function CardInterface:isSide(side)
	checkParameters('isSide',
			{side},
			{'number'})
	return self.pcard:isSide(side)
end

--returns if card can attack
function CardInterface:canAttack()
	return self.pcard:canAttack()
end

--returns if card is bound
function CardInterface:isBound()
	return self.pcard:isBound()
end

--returns if card is disabled
function CardInterface:isDisabled()
	return self.pcard:isDisabled()
end

--returns if card is a component
function CardInterface:isComponent(parent)
	checkParameters('isComponent',
			{parent},
			{{'table', CardInterface, 'nil'}})
			
	--get first if table
	if class(parent)=='table' then
		parent = parent[1]
	end
	
	if parent then
		return self.pcard:isLocation(parent.pcard)
	else
		return self.pcard:isComponent()
	end
end

--returns card's components
function CardInterface:getComponents()
	return interface(self.pcard:getComponents())
end

--returns all effects of this card
function CardInterface:getEffects()
	return self.pcard:getEffects()
end

--returns effects of this card that can be activated now
function CardInterface:getActivableEffects()
	return table.filter(self.pcard:getEffects(), Effect.canActivate, nil, self)
end

--makes card activate effect (for AI)
function CardInterface:activateAI(effect)
	checkParameters('activateAI',
			{effect},
			{Effect})
	return self.pcard:activateAI(effect)
end

--returns card level
function CardInterface:getLevel()
	if self.pcard:isUnknown() then
		return
	end
	return self.card:getLevel()
end

--returns if card has this level
function CardInterface:isLevel(level)
	checkParameters('isLevel',
			{level},
			{'number'})
	if self.pcard:isUnknown() then
		return false
	end
	return self.card:getLevel()==level
end

--returns if card is below or equal level
function CardInterface:isLevelBelow(level)
	checkParameters('isLevelBelow',
			{level},
			{'number'})
	if self.pcard:isUnknown() then
		return false
	end
	return self.card:getLevel()<=level
end

--returns if card is above or equal level
function CardInterface:isLevelAbove(level)
	checkParameters('isLevelAbove',
			{level},
			{'number'})
	if self.pcard:isUnknown() then
		return false
	end
	return self.card:getLevel()>=level
end

--returns if card is a spirit
function CardInterface:isSpirit()
	return self:isLevel(0)
end

local elementId = {
	earth = 1,
	sky = 2,
	water = 3,
	fire = 4,
}

--returns card left or right element
--order: 'left' or 'right'
function CardInterface:getElement(order)
	checkParameters('getElement',
			{order},
			{'string'})
	if self.pcard:isUnknown() then
		return
	end
	local elem
	if order=='left' then
		elem = self.card:getElement1()
	else --right
		elem = self.card:getElement2()
	end
	return Card.element[elem]
end

--return if card has this element
--[[
order:
	nil: either side works
	'left', 'right': element must be on that side
	'earth', 'fire', 'wind', 'water': treats the first as left and this as right
--]]
function CardInterface:isElement(element, order)
	checkParameters('isElement',
			{element, order},
			{'string', {'string', 'nil'}})
	if self.pcard:isUnknown() then
		return false
	end
	element = elementId[element]
	if order then
		if order=='left' then
			--check if element is on left side
			return self.card:getElement1()==element
		end
		
		if order=='right' then
			--check if element is on right side
			return self.card:getElement2()==element
		end
		
		--check if elements on both sides match the parameters
		order = elementId[order]
		return self.card:getElement1()==element or self.card:getElement2()==order
	else
		--check if element is on either side
		return self.card:getElement1()==element or self.card:getElement2()==element
	end
end

function CardInterface:getName()
	--returns card name
	if self.pcard:isUnknown() then
		return
	end
end

function CardInterface:isName(name)
	--returns if card has this name
	if self.pcard:isUnknown() then
		return false
	end
end

function CardInterface:getArchetype()
	--returns card archetype
	if self.pcard:isUnknown() then
		return
	end
end

function CardInterface:isArchetype(archetype)
	--returns if card is in this archetype
	if self.pcard:isUnknown() then
		return false
	end
end

function CardInterface:isFusion(component)
	--returns if card can be played using these components
	if self.pcard:isUnknown() then
		return false
	end
end

--returns if card can be played
function CardInterface:isPlayable()
	return self:isLevelAbove(1) --in the future, also check if has "Unplayable" effect
end

--returns if card is unknown
function CardInterface:isUnknown()
	return self.pcard:isUnknown()
end

--return card pcard
function CardInterface:getPlayableCard()
	return self.pcard
end

-----------------------------CARDS ACTIONS------------------------------

--adds an effect to card
--[[
property:
	condition: condition callback for the effect (location is determined here)
	operation: operation callback for the effect
	event: event ('fusion', 'defeat', etc.) for the effect
	description: description to show if multiples effects
--]]
function CardInterface:createEffect(property)
	checkParameters('createEffect',
			{property},
			{'table'})
	return self.pcard:addEffect(Effect:new(property))
end

--reveals card
function CardInterface:reveal(rc)
	checkParameters('reveal',
			{rc},
			{CardInterface})
	return self.pcard:reveal(rc)
end

--unreveals card
function CardInterface:unreveal(rc)
	checkParameters('unreveal',
			{rc},
			{CardInterface})
	return self.pcard:unreveal(rc)
end

--moves card
function CardInterface:move(rc)
	checkParameters('move',
			{rc},
			{{CardInterface, 'number'}})
	local match = Game.getMatch()
	local tp = type(rc)=='number' and rc or rc:getSide()
	if not match:isAI(tp) then
		self.pcard:grab(true)
		coroutine.yield(function()
			if Game.hasMouseClicked(1) then
				return self.pcard:finishMove(rc)
			end
			
			return false
		end)
	else
		--TODO treat AI
	end
end

--makes card attack target (for AI)
function CardInterface:attackAI(target)
	checkParameters('attackAI',
			{target},
			{{'table', CardInterface, 'string'}})
			
	--get first if table
	if class(target)=='table' then
		target = target[1]
	end
	
	--get PlayableCard if card
	if class(target)==CardInterface then
		target = target.pcard
	end
	return self.pcard:attackAI(target)
end

function CardInterface:attack(target)
	--makes card attack target
end

--binds card
function CardInterface:bind(rc)
	checkParameters('bind',
			{rc},
			{CardInterface})
	return self.pcard:bind(rc)
end

function CardInterface:unbind()
	--unbinds card
end

--disables card until cooldown
function CardInterface:disable(cooldown, rc, ...)
	checkParameters('disable',
			{cooldown, rc},
			{'table', CardInterface})
	return self.pcard:disable(cooldown, rc, ...)
end

--enables card
function CardInterface:enable(rc)
	checkParameters('enable',
			{rc},
			{CardInterface})
	return self.pcard:enable(rc)
end

local function chargeFilter(c, level, tp)
	return c:isLocation('table') and c:isSide(tp) and c:isLevelAbove(level) and not c:isDisabled()
end

--charges card
function CardInterface:charge(rc)
	checkParameters('charge',
			{rc},
			{CardInterface})
	local tp = rc:getSide()
	local parent = choose(tp, 'Choose card to charge into:', getCards(chargeFilter, self:getLevel()+1, tp), 1, 1)
	if not parent then
		return false
	end
	parent = parent[1]
	return parent.pcard:charge(self.pcard)
end

--charges card into parent
function CardInterface:chargeInto(parent, rc)
	if class(parent)=='table' then
		parent = parent[1]
	end
	checkParameters('chargeInto',
			{parent, rc},
			{CardInterface, CardInterface})
	parent.pcard:charge(self.pcard)
end

--shuffles card into it's owner deck
function CardInterface:shuffle(rc)
	checkParameters('shuffle',
			{rc},
			{CardInterface})
	return self.pcard:shuffle(rc)
end

--adds card to owner's hand
function CardInterface:add(rc)
	checkParameters('add',
			{rc},
			{CardInterface})
	return self.pcard:add(rc)
end

--plays card (for AI)
function CardInterface:playAI(component)
	checkParameters('playAI',
			{component},
			{{'nil', 'table'}})
	return self.pcard:playAI(component and pcard(component))
end

--plays card
function CardInterface:play(rc)
	checkParameters('play',
			{rc},
			{CardInterface})
	--check if there is space on table
	if not self.pcard:getEmptyPosition('table') then
		return false
	end
	
	--send card to table
	if not self.pcard:play(nil, rc) then
		return false
	end
	
	--[[
	--allow player to choose position
	self:move(rc:getSide())
	--]]
	
	return true
end

--plays card over component
function CardInterface:playOver(component, rc)
	--convert to group
	if class(component)~='table' then
		component = Group{component}
	end
	checkParameters('playOver',
			{component, rc},
			{'table', CardInterface})
	
	--check if components are on table
	if not component:isLocation('table') then
		return false
	end
	
	--charge component
	local position = component:getPosition()
	component:chargeInto(self, rc)
	
	--send card to table
	return self.pcard:play(position, rc)
end

--sends card to owner's discard pile
function CardInterface:discard(rc)
	checkParameters('discard',
			{rc},
			{CardInterface})
	return self.pcard:discard(rc)
end

--sends card to owner's damage zone
function CardInterface:damage(rc)
	checkParameters('damage',
			{rc},
			{CardInterface})
	return self.pcard:damage(rc)
end

--destroys card
function CardInterface:destroy(rc)
	checkParameters('destroy',
			{rc},
			{CardInterface})
	return self.pcard:destroy(rc)
end























