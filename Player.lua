Player = createClass({
	defeatDamage = 10,
},
function(self, deckName, side)
	self.side = side
	self.card = {}
	local i=1
	for card in io.lines('user/decks/' .. deckName .. '.deck') do
		self.card[#self.card+1] = PlayableCard:new(tonumber(card), side, i, self.card)
		i = i + 1
	end
end)

function Player:update(dt)
	--cards
	for i,card in ipairs(self.card) do
		card:update(dt)
	end
end

function Player:draw(param)
	if param then
		error('Draw does not have parameters. Did you mean drawCard?', 2)
	end
end

function Player:getCards()
	local card = {}
	for i,c in ipairs(self.card) do
		card[i] = c
	end
	return card
end

local function reachDestination(card)
	if Match.isAIMode() then
		--don't wait on AI Mode
		return
	end
	
	if class(card)~='table' then
		card = {card}
	end
	coroutine.yield(function()
		for i,c in ipairs(card) do
			if not c:reachedDestination() then
				return false
			end
		end
		return true
	end)
end

function Player:drawCard(amount)
	local topCard
	local drawn = {}
	for i=1,(amount or 1) do
		--select top deck card
		local deck = table.filter(self.card, PlayableCard.isLocation, 'deck')
		topCard = table.select(deck, PlayableCard.maxPosition)
		drawn[#drawn+1] = topCard
		if not topCard then
			return
		end
		topCard:sendTo('hand')
	end
	reachDestination(drawn)
end

function Player:damage(amount)
	local topCard
	for i=1,(amount or 1) do
		--select top deck card
		local deck = table.filter(self.card, PlayableCard.isLocation, 'deck')
		topCard = table.select(deck, PlayableCard.maxPosition)
		if not topCard then
			return
		end
		topCard:sendTo('damage')
		reachDestination(topCard)
	end
end

function Player:shuffleDeck()
	local deck = table.filter(self.card, PlayableCard.isLocation, 'deck')
	table.shuffle(deck)
	for i,c in ipairs(deck) do
		c:setPosition(i)
		c:setUnknown(true) --shuffled cards become unknown
	end
	coroutine.yield(function()
		--TODO wait shuffle animation
		return true
	end)
	reachDestination(deck)
end

function Player:shuffleHand()
	local hand = table.filter(self.card, PlayableCard.isLocation, 'hand')
	
	--set all to same position
	local pos = (#hand+1)/2
	for i,c in ipairs(hand) do
		c:setPosition(pos)
	end
	reachDestination(hand)
	
	--shuffle
	table.shuffle(hand)
	for i,c in ipairs(hand) do
		c:setPosition(i)
	end
	reachDestination(hand)
end

function Player:getSelectedCard(checkSelector)
	local card = Selector.getObject()
	if class(card)==PlayableCard and card:isSide(self.side) and (not checkSelector or card:isSelectDirect()) then
		return card
	end
end

function Player:tryGrab(allowTable)
	local card = self:getSelectedCard()
	if card and card:isLocation(allowTable and {'hand','table'} or 'hand') then
		return card:tryGrab()
	end
	return nil
end

function Player:tryActivate()
	local card = self:getSelectedCard()
	if card then
		return card:tryActivate()
	end
	return nil
end

function Player:tryAttack()
	local card = self:getSelectedCard()
	if card then
		return card:tryAttack()
	end
	return nil
end

function Player:tryFusion()
	local card = self:getSelectedCard()
	if card and card:isLocation('table') then
		return card:tryFusion()
	end
	return nil
end

function Player:tryInfo()
	local card = self:getSelectedCard()
	if card then
		return card:tryInfo()
	end
	return false
end

function Player:tryList(list)
	local card = self:getSelectedCard(true)
	if card and (card:isLocation({'discard', 'damage'}) or card:isComponent()) then
		return table.filter(self.card, PlayableCard.isLocation, card:getLocation())
	end
	return nil
end

function Player:unbind()
	local card = table.filter(self.card, PlayableCard.isLocation, {'table'})
	for i,c in ipairs(card) do
		c:unbind()
	end
end

function Player:enable()
	local card = table.filter(self.card, PlayableCard.isDisabled)
	for i,c in ipairs(card) do
		c:tryEnable()
	end
end

function Player:getHandSize()
	return #table.filter(self.card, PlayableCard.isLocation, 'hand', true)
end

local function backrowCondition(c)
	return c:isLocation('table') and c:isPosition({1,2,3}) and not c:isDisabled()
end

function Player:canAttackBackrow()
	--true if an enabled card doesn't exist in the front row
	return not table.exists(self.card, backrowCondition)
end

function Player:hasLost()
	--damage
	if self:getLife()<=0 then
		return true, 'damage'
	end
	
	--[[
	--deck out
	if not table.exists(self.card, PlayableCard.isLocation, 'deck') then
		return true, 'deck'
	end
	--]]
	
	return false
end

function Player:reachDestination()
	reachDestination(self.card)
end

function Player:resetMatch()
	for i,c in ipairs(self.card) do
		c:resetMatch()
	end
end

local function damageFilter(c)
	return c:isLocation('damage') and not c:isDisabled()
end

function Player:getLife()
	local damage = table.filter(self.card, damageFilter)
	--[[
	local totalLevel = 0
	for i,c in ipairs(damage) do
		totalLevel = totalLevel + (c:isUnknown() and 1 or c:getCard():getLevel())
	end
	return Player.defeatDamage - totalLevel
	--]]
	return Player.defeatDamage - #damage
end

function Player:mulligan()
	local hand = table.filter(self.card, PlayableCard.isLocation, 'hand')
	local match = Game.getMatch()
	local redraw = match:chooseFromList(self.side, 'Choose cards to redraw:', hand, 0, #hand)
	for i,c in ipairs(redraw) do
		c:sendTo('deck')
	end
	self:shuffleDeck()
	self:drawCard(#redraw)
end

function Player:getAttackers()
	--get cards that can attack
	return table.filter(self.card, PlayableCard.canAttack)
end

function Player:getBattlePower()
	--get attackers
	local attacker = self:getAttackers()
	
	--get total levels
	local power = 0
	for i,c in ipairs(attacker) do
		power = power + c:getCard():getLevel()
	end
	return power
end
















