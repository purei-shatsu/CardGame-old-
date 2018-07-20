local function filter(c, tp)
	return c:isLocation('deck') and c:isSide(tp)
end

local function order(c1, c2)
	return c1:getPosition()>c2:getPosition()
end

local function operation(c, rc)
	local tp = c:getSide()
	local deck = getCards(filter, tp)
	local tc = table.select(deck, order)
	if tc then
		tc:reveal(c)
		if tc:charge(c) then
			tc:unreveal(c)
			return
		else
			confirm(tp, tc)
			confirm(3-tp, tc)
		end
		tc:unreveal(c)
	end
	shuffleDeck(tp, c)
end

return function(c)
	c:createEffect {
		operation = operation,
		event = 'fusion_earth',
		description = "Charge the top card from your deck (if unable, shuffle your deck).",
	}
end
