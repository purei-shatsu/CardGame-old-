function pcard(card)
	--get playable cards
	local pc = {}
	for i,c in ipairs(card) do
		pc[i] = c:getPlayableCard()
	end
	return pc
end

function interface(pcard)
	--get interfaces
	local c = {}
	for i,pc in ipairs(pcard) do
		c[i] = pc:getInterface()
	end
	return Group(c)
end

--returns all cards in the game
--optional filter with parameters
function getCards(filter, ...)
	checkParameters('getCards',
			{filter},
			{{'nil', 'function'}})
	
	--get all cards
	local match = Game.getMatch()
	local card = interface(match:getCards())
	
	--filter cards
	if filter then
		Match.setKnownMode(true)
		card = card:filter(filter, ...)
		Match.setKnownMode(false)
	end
	
	return card
end

--saves AI state
function saveState()
	local match = Game.getMatch()
	match:saveState()
end

--loads AI state
function loadState()
	local match = Game.getMatch()
	match:loadState()
end

--opens a list in which a player chooses cards
function choose(tp, text, list, minimum, maximum)
	checkParameters('choose',
			{tp, text, list, minimum, maximum},
			{'number', 'string', 'table', {'nil', 'number'}, {'nil', 'number'}})
	
	local match = Game.getMatch()
	local chosen = match:chooseFromList(tp, text, pcard(list), minimum, maximum)
	return chosen and interface(chosen)
end

--opens a list in which a player confirm cards
function confirm(tp, list)
	checkParameters('confirm',
			{tp, list},
			{'number', {'table', CardInterface}})
	
	if class(list)~='table' then
		list = {list}
	end
	choose(tp, "", list)
end

function damage(tp, amount, rc)
	--sends cards from a player's deck to the damage zone
end

function draw(tp, amount, rc)
	--player draws cards from deck
end

local function dischargeFilter(c, tp)
	return c:isSide(tp) and c:isLocation('table') and #c:getComponents()>0
end

--returns if player can discharge amount
function canDischarge(tp, amount)
	checkParameters('canDischarge',
			{tp, amount},
			{'number', 'number'})
	
	--get cards with components
	local parent = getCards(dischargeFilter, tp)
	
	--count components
	local total = 0
	for i,c in ipairs(parent) do
		total = total + #c:getComponents()
	end
	
	return total>=amount
end

local function allCompFilter(c, tp)
	return c:isSide(tp) and c:isComponent()
end

--players discharges components
function discharge(tp, amount, rc)
	checkParameters('discharge',
			{tp, amount, rc},
			{'number', 'number', CardInterface})
	
	--check if can discharge
	if not canDischarge(tp, amount) then
		return false
	end
	
	if Match.isAIMode() then --choose components directly
		--choose components to discharge
		local component = choose(tp, 'Choose which cards to discharge:', getCards(allCompFilter, tp), amount)
		component:discard(rc)
		
	else
		--get cards with components
		local parent = getCards(dischargeFilter, tp)
		while amount>0 do --discharge until amount is reached
			--choose parent, then component
			--choose a card with components
			local chosen = choose(tp, 'Choose a card to discharge from:', parent, 1, 1)
			
			--choose components to discharge
			local component = choose(tp, 'Choose which cards to discharge:', chosen[1]:getComponents(), 0, amount)
			amount = amount - #component
			component:discard(rc)
			
			--refilter parents (removes cards that no longer have components)
			parent = parent:filter(dischargeFilter, tp)
		end
	end
	
	return true
end

--shuffles player deck
function shuffleDeck(tp, rc)
	local match = Game.getMatch()
	match:shuffleDeck(tp)
end

function win(tp, reason)
	--makes player win
end

--returns turn count
function getTurnCount()
	local match = Game.getMatch()
	return match:getTurnCount()
end

--returns turn player
function getTurnPlayer()
	local match = Game.getMatch()
	return match:getTurnPlayer()
end























