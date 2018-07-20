ZoneInterface = createClass({
	--static things
},
function(self, side, position)
	self.side = side
	self.position = position
	--location is always table
end,
'ZoneInterface')

--returns zone position
function ZoneInterface:getPosition()
	return self.position
end

--returns if zone is in position
function ZoneInterface:isPosition(position)
	checkParameters('isPosition',
			{position},
			{'string'})
	return self.position==position
end

--returns zone side
function ZoneInterface:getSide()
	return self.side
end

--returns if zone is in side
function ZoneInterface:isSide(side)
	checkParameters('isSide',
			{side},
			{'number'})
	return self.side==side
end

local function cardFilter(c , side, position)
	return c:isLocation('table') and c:isSide(side) and c:isPosition(position)
end

--returns CardInterface in the zone
function ZoneInterface:getCard()
	local card = getCards(cardFilter, self.side, self.position)
	return card[1]
end

--returns PlayableCard in the zone
function ZoneInterface:getPlayableCard()
	local c = self:getCard()
	return c and c:getPlayableCard()
end

--returns if zone is empty
function ZoneInterface:isEmpty()
	return not self:getCard()
end

--callbacks for sorting
function ZoneInterface.minPosition(a, b)
	return a.position<=b.position
end
function ZoneInterface.maxPosition(a, b)
	return a.position>=b.position
end





















