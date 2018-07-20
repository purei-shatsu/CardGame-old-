local cost = 1

local function condition(c, rc)
	return c:isLocation('table')
end

local function filter(c, tp)
	return c:isSide(tp) and c:isLocation('table') and not c:isDisabled()
end

local function filter2(c, tp)
	return c:isPlayable() and c:isElement('fire') and c:isSide(tp) and c:isLocation('discard') and not c:isDisabled()
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		local tc = choose(tp, 'Destroy 1 card:', getCards(filter, tp), 1, 1)
		if tc and tc:destroy(c) then
			local tc2 = choose(tp, 'Play 1 card:', getCards(filter2, tp), 1, 1)
			if tc2 then
				tc2:play(c)
			end
		end
	end
end

return function(c)
	c:createEffect {
		condition = condition,
		operation = operation,
		description = 'Destroy 1 card from your table, play 1 FIRE from your discard pile.',
	}
end
