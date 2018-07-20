local cost = 2

local function condition(c, rc)
	return c:isLocation('table')
end

local function filter(c, tp, level)
	return c:isSide(tp) and c:isLocation('table') and c:isLevel(level) and not c:isDisabled()
end

local function filter2(c, tp)
	return c:isPlayable() and c:isElement('earth') and c:isSide(tp) and c:isLocation('discard') and not c:isDisabled() and table.exists(getCards(), filter, tp, c:getLevel()-1)
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		local tc = choose(tp, 'Play 1 card:', getCards(filter2, tp), 1, 1)
		if tc then
			local tc2 = choose(tp, 'Choose card to be played over:', getCards(filter, tp, tc:getLevel()-1), 1, 1)
			if tc2 then
				tc:playOver(tc2, c)
			end
		end
	end
end

return function(c)
	c:createEffect {
		condition = condition,
		operation = operation,
		description = 'Play 1 level X EARTH from your discard pile over 1 level X-1 from your table.',
	}
end
